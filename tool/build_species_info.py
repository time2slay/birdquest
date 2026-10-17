"""Builds the bundled species index from Wikidata, Wikipedia and Commons.

For every bird in the BirdNET+ label file it collects:
  * Russian common names (Wikidata, CC0) and the English/Russian Wikipedia
    article titles, so the app can fetch descriptions on demand or in the
    optional Encyclopedia download (descriptions are not bundled);
  * one lead photo from Wikimedia Commons, but only if its license allows
    commercial use (CC0, public domain, CC BY, CC BY-SA), together with the
    author and license needed for attribution;
  * up to three short reference recordings from Wikimedia Commons (Commons
    only hosts free licenses; NC/ND are rejected anyway), with attribution;
  * the family (Wikidata parent taxa), for "similar species";
  * flight speeds from Wikipedia's "List of birds by flight speed"
    (per species, and a per-family median for the rest).

Usage (stdlib only):
  python tool/build_species_info.py <BirdNET labels.csv> assets/data/species_index.json.gz [cache_dir]
"""

import gzip
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

# Wikimedia's User-Agent policy wants a contact; anonymous-looking clients
# are rate limited hard. Same contact as the app (lib/app/app_config.dart).
CONTACT = os.environ.get('WIKIMEDIA_CONTACT', 'scarjkeepari@gmail.com')
UA = f'BirdQuestDataBuilder/1.0 ({CONTACT}; build-time script for the BirdQuest offline bird guide)'
ALLOWED_LICENSE = re.compile(r'^(CC0|Public domain|PD|CC BY(-SA)? \d)', re.I)


def http_json(url, data=None, retries=5):
    for attempt in range(retries + (4 if 'wikipedia' in url else 0)):
        try:
            req = urllib.request.Request(url, data=data, headers={
                'User-Agent': UA,
                'Accept': 'application/json',
                **({'Content-Type': 'application/x-www-form-urlencoded'} if data else {}),
            })
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code in (400, 404, 414):
                raise  # not transient; caller may split the batch
            retry_after = e.headers.get('Retry-After') if e.headers else None
            wait = int(retry_after) if retry_after and retry_after.isdigit() else 2 ** attempt * (15 if e.code == 429 else 1)
            print(f'  HTTP {e.code}; retry {attempt + 1} in {wait}s', file=sys.stderr)
            time.sleep(wait)
        except Exception as e:  # noqa: BLE001 - retry anything transient
            wait = 2 ** attempt
            print(f'  retry {attempt + 1} after {e!r}; sleeping {wait}s', file=sys.stderr)
            time.sleep(wait)
    raise RuntimeError(f'giving up on {url[:200]}')


def cached_stage(cache_dir, name, fn):
    """Runs fn() once and caches its JSON result so reruns resume quickly."""
    if not cache_dir:
        return fn()
    path = os.path.join(cache_dir, name + '.json')
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    result = fn()
    os.makedirs(cache_dir, exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False)
    return result


def chunks(seq, n):
    for i in range(0, len(seq), n):
        yield seq[i:i + n]



def wikidata(names):
    """Scientific name -> {qid, en, ru, ruLabel, enLabel, p18}."""
    out = {}
    q = '''SELECT ?name ?item ?enTitle ?ruTitle ?ruLabel ?enLabel ?img WHERE {
      VALUES ?name { %s }
      ?item wdt:P225 ?name .
      OPTIONAL { ?en schema:about ?item; schema:isPartOf <https://en.wikipedia.org/>; schema:name ?enTitle }
      OPTIONAL { ?ru schema:about ?item; schema:isPartOf <https://ru.wikipedia.org/>; schema:name ?ruTitle }
      OPTIONAL { ?item rdfs:label ?ruLabel FILTER(lang(?ruLabel) = "ru") }
      OPTIONAL { ?item rdfs:label ?enLabel FILTER(lang(?enLabel) = "en") }
      OPTIONAL { ?item wdt:P18 ?img }
    }'''
    for i, batch in enumerate(chunks(names, 150)):
        values = ' '.join('"%s"' % n.replace('"', '') for n in batch)
        body = urllib.parse.urlencode({'query': q % values, 'format': 'json'}).encode()
        res = http_json('https://query.wikidata.org/sparql', data=body)
        for b in res['results']['bindings']:
            name = b['name']['value']
            rec = {
                'qid': b['item']['value'].rsplit('/', 1)[-1],
                'en': b.get('enTitle', {}).get('value'),
                'ru': b.get('ruTitle', {}).get('value'),
                'ruLabel': b.get('ruLabel', {}).get('value'),
                'enLabel': b.get('enLabel', {}).get('value'),
                'p18': urllib.parse.unquote(b['img']['value'].rsplit('/', 1)[-1]) if 'img' in b else None,
            }
            prev = out.get(name)
            score = lambda r: (r['en'] is not None) + (r['ru'] is not None) + (r['p18'] is not None)
            if prev is None or score(rec) > score(prev):
                out[name] = rec
        print(f'wikidata {min((i + 1) * 150, len(names))}/{len(names)}', file=sys.stderr)
        time.sleep(1)
    return out


def wiki_pages(lang, titles):
    """Title -> (None, lead image file name)."""
    out = {}
    for i, batch in enumerate(chunks(sorted(set(titles)), 50)):
        try:
            out.update(_wiki_batch(lang, batch))
        except Exception as e:  # noqa: BLE001
            print(f'  batch failed ({e}); retrying titles one by one', file=sys.stderr)
            for t in batch:
                try:
                    out.update(_wiki_batch(lang, [t]))
                except Exception as e2:  # noqa: BLE001
                    print(f'  skipping {t!r}: {e2}', file=sys.stderr)
        if i % 25 == 0:
            print(f'{lang}wiki {min((i + 1) * 50, len(titles))}/{len(titles)}', file=sys.stderr)
        time.sleep(1.2)  # stay well under Wikimedia's anonymous rate limits
    return out


def _wiki_batch(lang, batch):
    out = {}
    if True:
        params = {
            'action': 'query', 'format': 'json', 'formatversion': '2',
            'prop': 'pageimages', 'piprop': 'name', 'pilimit': '50', 'redirects': '1',
            'titles': '|'.join(batch), 'maxlag': '5',
        }
        res = http_json(f'https://{lang}.wikipedia.org/w/api.php?' + urllib.parse.urlencode(params))
        back = {}
        for n in res['query'].get('normalized', []) + res['query'].get('redirects', []):
            back[n['to']] = back.get(n['from'], n['from'])
        for p in res['query'].get('pages', []):
            if p.get('missing'):
                continue
            original = back.get(p['title'], p['title'])
            out[original] = (None, p.get('pageimage'))
    return out


def commons_licenses(files):
    """File name -> {author, license, licenseUrl} for commercially usable files."""
    out = {}
    for i, batch in enumerate(chunks(sorted(set(files)), 50)):
        params = {
            'action': 'query', 'format': 'json', 'formatversion': '2',
            'prop': 'imageinfo', 'iiprop': 'extmetadata',
            'iiextmetadatafilter': 'LicenseShortName|LicenseUrl|Artist|AttributionRequired',
            'titles': '|'.join('File:' + f for f in batch), 'maxlag': '5',
        }
        res = http_json('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params))
        back = {n['to']: n['from'] for n in res['query'].get('normalized', [])}
        for p in res['query'].get('pages', []):
            info = (p.get('imageinfo') or [None])[0]
            if not info:
                continue  # not hosted on Commons (local / fair use)
            meta = info.get('extmetadata', {})
            lic = meta.get('LicenseShortName', {}).get('value', '')
            if not ALLOWED_LICENSE.match(lic) or 'NC' in lic or 'ND' in lic:
                continue
            author = re.sub(r'<[^>]+>', '', html.unescape(meta.get('Artist', {}).get('value', ''))).strip()
            title = back.get(p['title'], p['title'])[len('File:'):]
            out[title.replace(' ', '_')] = {
                'author': author[:120] or 'Unknown author',
                'license': lic,
                'licenseUrl': meta.get('LicenseUrl', {}).get('value'),
            }
        if i % 20 == 0:
            print(f'commons {min((i + 1) * 50, len(files))}/{len(files)}', file=sys.stderr)
        time.sleep(0.2)
    return out


# Wikidata speed units -> km/h factor.
_WD_UNITS = {'Q180154': 1, 'Q182429': 3.6, 'Q211256': 1.609344, 'Q128822': 1.852}


def _parents(qids):
    """QID -> (parent QID or None, rank QID or None, taxon name or None,
    speed km/h or None), one cheap query per 150 items."""
    out = {}
    q = """SELECT ?item ?parent ?rank ?name ?v ?u WHERE {
      VALUES ?item { %s }
      OPTIONAL { ?item wdt:P171 ?parent }
      OPTIONAL { ?item wdt:P105 ?rank }
      OPTIONAL { ?item wdt:P225 ?name }
      OPTIONAL { ?item p:P2052/psv:P2052 [ wikibase:quantityAmount ?v; wikibase:quantityUnit ?u ] }
    }"""
    for batch in chunks(sorted(set(qids)), 150):
        values = ' '.join('wd:' + q_ for q_ in batch)
        body = urllib.parse.urlencode({'query': q % values, 'format': 'json'}).encode()
        res = http_json('https://query.wikidata.org/sparql', data=body)
        for b in res['results']['bindings']:
            qid = b['item']['value'].rsplit('/', 1)[-1]
            parent, rank, name, kmh = out.get(qid, (None, None, None, None))
            parent = parent or (b['parent']['value'].rsplit('/', 1)[-1] if 'parent' in b else None)
            rank = rank or (b['rank']['value'].rsplit('/', 1)[-1] if 'rank' in b else None)
            name = name or b.get('name', {}).get('value')
            unit = b.get('u', {}).get('value', '').rsplit('/', 1)[-1]
            if 'v' in b and unit in _WD_UNITS:
                kmh = max(kmh or 0, round(float(b['v']['value']) * _WD_UNITS[unit]))
            out[qid] = (parent, rank, name, kmh)
        time.sleep(1)
    return out


def taxonomy(qids):
    """QID -> {fam: scientific family name or None, kmh: Wikidata speed}.
    Walks parent taxa level by level (a transitive query times out)."""
    FAMILY = 'Q35409'
    info = _parents(qids)
    print(f'taxonomy level 0: {len(info)}', file=sys.stderr)
    out = {q_: {'fam': None, 'kmh': info.get(q_, (None,) * 4)[3]} for q_ in qids}
    frontier = {q_: info.get(q_, (None,) * 4)[0] for q_ in qids}
    for level in range(1, 6):
        need = {p_ for p_ in frontier.values() if p_ and p_ not in info}
        if need:
            info.update(_parents(sorted(need)))
        nxt = {}
        for q_, p_ in frontier.items():
            if not p_ or p_ not in info:
                continue
            parent, rank, name, _ = info[p_]
            if rank == FAMILY:
                out[q_]['fam'] = name
            else:
                nxt[q_] = parent
        frontier = nxt
        print(f'taxonomy level {level}: {len(frontier)} still climbing', file=sys.stderr)
        if not frontier:
            break
    return out


AUDIO_EXT = re.compile(r'\.(ogg|oga|opus|mp3|wav|flac)$', re.I)


def _audio_prefix_one(name):
    """Commons files whose title starts with the scientific name, e.g. the
    xeno-canto imports "Turdus merula - Common Blackbird XC123.mp3". Uses
    list=allimages (a database listing, not the throttled search engine)."""
    hits = []
    params = {
        'action': 'query', 'format': 'json', 'formatversion': '2',
        'list': 'allimages', 'aiprefix': name.replace(' ', '_'),
        'ailimit': '500', 'aiprop': 'mime', 'maxlag': '5',
    }
    for _ in range(4):  # at most 2000 files per species
        res = http_json('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params))
        for f in res.get('query', {}).get('allimages', []):
            mime = f.get('mime', '')
            title = f['name']
            if (mime.startswith('audio/') or mime in ('application/ogg', 'video/ogg')) and AUDIO_EXT.search(title):
                # The prefix must end at a word boundary ("Turdus merula" not
                # "Turdus merulaoides").
                rest = title[len(name):]
                if not rest or not rest[0].isalpha():
                    hits.append(title.replace(' ', '_'))
        cont = res.get('continue')
        if not cont:
            break
        params.update(cont)
    return hits


def commons_audio_prefix(names, cache_dir=None, workers=2):
    """Scientific name -> Commons audio file names starting with it."""
    from concurrent.futures import ThreadPoolExecutor
    part = os.path.join(cache_dir, 'voices_prefix.partial.json') if cache_dir else None
    out = {}
    if part and os.path.exists(part):
        with open(part, encoding='utf-8') as f:
            out = json.load(f)
    todo = [n for n in names if n not in out]

    def one(name):
        try:
            hits = _audio_prefix_one(name)
        except Exception as e:  # noqa: BLE001
            print(f'  listing failed for {name}: {e}', file=sys.stderr)
            return name, None
        time.sleep(0.3)
        return name, hits

    with ThreadPoolExecutor(max_workers=workers) as pool:
        for i, (name, hits) in enumerate(pool.map(one, todo)):
            if hits is not None:
                out[name] = hits
            if part and i % 200 == 0:
                with open(part, 'w', encoding='utf-8') as f:
                    json.dump(out, f, ensure_ascii=False)
                print(f'voices listing {len(out)}/{len(names)}', file=sys.stderr)
    return out


def wikidata_audio(qids):
    """QID -> Commons audio file names from Wikidata P51 (audio)."""
    out = {}
    q = """SELECT ?item ?a WHERE { VALUES ?item { %s } ?item wdt:P51 ?a }"""
    for batch in chunks(sorted(set(qids)), 150):
        values = ' '.join('wd:' + q_ for q_ in batch)
        body = urllib.parse.urlencode({'query': q % values, 'format': 'json'}).encode()
        res = http_json('https://query.wikidata.org/sparql', data=body)
        for b in res['results']['bindings']:
            qid = b['item']['value'].rsplit('/', 1)[-1]
            f = urllib.parse.unquote(b['a']['value'].rsplit('/', 1)[-1]).replace(' ', '_')
            out.setdefault(qid, []).append(f)
        time.sleep(1)
    print(f'wikidata audio: {len(out)} species', file=sys.stderr)
    return out


def commons_audio_info(files):
    """File name -> {author, license, licenseUrl, size, seconds} for audio
    that is freely licensed, small enough and short enough."""
    out = {}
    for i, batch in enumerate(chunks(sorted(set(files)), 50)):
        params = {
            'action': 'query', 'format': 'json', 'formatversion': '2',
            'prop': 'imageinfo', 'iiprop': 'size|mediatype|metadata|extmetadata',
            'iiextmetadatafilter': 'LicenseShortName|LicenseUrl|Artist',
            'titles': '|'.join('File:' + f for f in batch), 'maxlag': '5',
        }
        res = http_json('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params))
        back = {n['to']: n['from'] for n in res['query'].get('normalized', [])}
        for p in res['query'].get('pages', []):
            info = (p.get('imageinfo') or [None])[0]
            if not info or info.get('mediatype') != 'AUDIO':
                continue
            meta = info.get('extmetadata', {})
            lic = meta.get('LicenseShortName', {}).get('value', '')
            if not ALLOWED_LICENSE.match(lic) or 'NC' in lic or 'ND' in lic:
                continue
            seconds = None
            for m in info.get('metadata') or []:
                if m.get('name') in ('length', 'playtime_seconds', 'duration'):
                    try:
                        seconds = float(m['value'])
                    except (TypeError, ValueError):
                        pass
            size = info.get('size') or 0
            if size > 2_500_000 or (seconds is not None and not 3 <= seconds <= 240):
                continue
            author = re.sub(r'<[^>]+>', '', html.unescape(meta.get('Artist', {}).get('value', ''))).strip()
            title = back.get(p['title'], p['title'])[len('File:'):]
            out[title.replace(' ', '_')] = {
                'author': author[:120] or 'Unknown author',
                'license': lic,
                'licenseUrl': meta.get('LicenseUrl', {}).get('value'),
                'size': size,
                'seconds': round(seconds, 1) if seconds else None,
            }
        if i % 20 == 0:
            print(f'voices info {min((i + 1) * 50, len(files))}/{len(files)}', file=sys.stderr)
        time.sleep(0.2)
    return out


SPEED_LIST = 'https://en.wikipedia.org/wiki/List_of_birds_by_flight_speed'


def _cell_text(cell):
    cell = re.sub(r'<sup[^>]*>.*?</sup>', '', cell, flags=re.S)  # footnotes
    cell = re.sub(r'<br\s*/?>', ' ', cell)
    return html.unescape(re.sub(r'<[^>]+>', '', cell)).replace('\xa0', ' ').strip()


def _kmh(text):
    """Largest km/h figure in a rendered cell ("112–160 km/h (70–99 mph)")."""
    best = None
    for m in re.finditer(r'(\d+(?:\.\d+)?)(?:\s*[–-]\s*(\d+(?:\.\d+)?))?\s*km/h', text):
        v = float(m.group(2) or m.group(1))
        best = v if best is None else max(best, v)
    return round(best) if best else None


def flight_speeds():
    """Scientific name -> {h: max horizontal km/h, d: max overall km/h,
    fam: family} from Wikipedia's list (CC BY-SA, cited there)."""
    params = {'action': 'parse', 'page': 'List_of_birds_by_flight_speed',
              'prop': 'text', 'format': 'json', 'formatversion': '2'}
    page = http_json('https://en.wikipedia.org/w/api.php?' + urllib.parse.urlencode(params))['parse']['text']
    table = page[page.index('<table'):page.index('</table>')]
    out = {}
    for row in re.findall(r'<tr[^>]*>(.*?)</tr>', table, flags=re.S):
        cells = [_cell_text(c) for c in re.findall(r'<td[^>]*>(.*?)</td>', row, flags=re.S)]
        if len(cells) < 7:
            continue
        sci = re.sub(r'\s+', ' ', cells[2]).strip()
        if not re.fullmatch(r'[A-Z][a-z]+ [a-z-]+', sci):
            continue
        avg, h, d = _kmh(cells[4]), _kmh(cells[5]), _kmh(cells[6])
        h = h or avg
        if h or d:
            out[sci] = {'h': h, 'd': d if d and (not h or d > h) else None, 'fam': cells[3]}
    return out

def main(labels_path, out_path, cache_dir=None):
    rows = [l.rstrip('\n').split(';') for l in open(labels_path, encoding='utf-8-sig')][1:]
    birds = [r for r in rows if len(r) > 4 and r[4] == 'Aves']
    names = [r[2] for r in birds]
    print(f'{len(names)} bird species', file=sys.stderr)

    wd = cached_stage(cache_dir, 'wikidata', lambda: wikidata(names))
    en = cached_stage(cache_dir, 'enwiki', lambda: wiki_pages('en', [w['en'] for w in wd.values() if w['en']]))
    ru = cached_stage(cache_dir, 'ruwiki', lambda: wiki_pages('ru', [w['ru'] for w in wd.values() if w['ru']]))

    candidates = {}
    for name, w in wd.items():
        lead = en.get(w['en'] or '', (None, None))[1] or ru.get(w['ru'] or '', (None, None))[1]
        files = [f for f in (lead, w['p18']) if f]
        if files:
            candidates[name] = [f.replace(' ', '_') for f in files]
    lic = cached_stage(cache_dir, 'commons', lambda: commons_licenses([f for fs in candidates.values() for f in fs]))

    tax = cached_stage(cache_dir, 'taxonomy', lambda: taxonomy([w['qid'] for w in wd.values()]))
    p51 = cached_stage(cache_dir, 'voices_wikidata', lambda: wikidata_audio([w['qid'] for w in wd.values()]))
    found = cached_stage(cache_dir, 'voices_prefix', lambda: commons_audio_prefix(names, cache_dir))
    for name, w in wd.items():
        extra = [f for f in p51.get(w['qid'], []) if f not in found.get(name, [])]
        if extra:
            found[name] = extra + found.get(name, [])
    vinfo = cached_stage(cache_dir, 'voices_info', lambda: commons_audio_info([f for fs in found.values() for f in fs]))
    speeds = cached_stage(cache_dir, 'speeds', flight_speeds)

    # Per-family median of the listed species' horizontal speeds.
    fam_speeds = {}
    for sp in speeds.values():
        if sp['h'] and sp['fam']:
            fam_speeds.setdefault(sp['fam'], []).append(sp['h'])
    fam_median = {f: sorted(v)[len(v) // 2] for f, v in fam_speeds.items()}

    def voice_rank(f):
        low = f.lower()
        return (0 if 'song' in low else 1 if 'call' in low else 2, vinfo[f].get('seconds') or 99)

    species = {}
    for name in names:
        w = wd.get(name)
        if not w:
            continue
        rec = {}
        if w['en']:
            rec['en'] = {'t': w['en']}
        if w['ru']:
            rec['ru'] = {'t': w['ru']}
        ru_name = None
        for cand in (w['ruLabel'], re.sub(r'\s*\(.*\)$', '', w['ru'] or '')):
            if cand and re.search('[А-Яа-яЁё]', cand) and not re.search('[A-Za-z]', cand):
                ru_name = cand.replace('́', '')
                break
        if ru_name:
            rec.setdefault('ru', {})['n'] = ru_name[:1].upper() + ru_name[1:]
        for f in candidates.get(name, []):
            if f in lic:
                rec['img'] = {'f': f, 'a': lic[f]['author'], 'l': lic[f]['license'], 'u': lic[f]['licenseUrl']}
                break
        fam = (tax.get(w['qid']) or {}).get('fam') or (speeds.get(name) or {}).get('fam')
        if fam:
            rec['fam'] = fam
        voices = sorted((f for f in found.get(name, []) if f in vinfo), key=voice_rank)[:3]
        if voices:
            rec['snd'] = [
                {'f': f, 'a': vinfo[f]['author'], 'l': vinfo[f]['license'], 'u': vinfo[f]['licenseUrl'],
                 **({'d': vinfo[f]['seconds']} if vinfo[f].get('seconds') else {})}
                for f in voices
            ]
        sp = speeds.get(name)
        wd_kmh = (tax.get(w['qid']) or {}).get('kmh')
        if sp:
            rec['spd'] = {k: v for k, v in (('h', sp['h']), ('d', sp['d'])) if v}
        elif wd_kmh:
            rec['spd'] = {'h': wd_kmh, 'wd': 1}
        elif fam in fam_median:
            rec['spd'] = {'h': fam_median[fam], 'fam': 1}
        if rec:
            species[name] = rec

    data = {
        'version': 2,
        'built': time.strftime('%Y-%m-%d'),
        'sources': {
            'titles': 'Wikipedia (en, ru) article titles',
            'names': 'Wikidata, CC0',
            'images': 'Wikimedia Commons; per-file licenses',
            'voices': 'Wikimedia Commons; per-file licenses',
            'families': 'Wikidata parent taxa, CC0',
            'speeds_wikidata': 'Wikidata P2052 (speed), CC0',
            'speeds': SPEED_LIST + ' (CC BY-SA); per-family values are medians of listed species',
        },
        'species': species,
    }
    raw = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    with gzip.open(out_path, 'wb', compresslevel=9) as f:
        f.write(raw)
    n = len(names)
    print(json.dumps({
        'species': n,
        'with_en_article': sum('t' in s.get('en', {}) for s in species.values()),
        'with_ru_article': sum('t' in s.get('ru', {}) for s in species.values()),
        'with_ru_name': sum('n' in s.get('ru', {}) for s in species.values()),
        'with_image': sum('img' in s for s in species.values()),
        'with_voices': sum('snd' in s for s in species.values()),
        'voices': sum(len(s.get('snd', [])) for s in species.values()),
        'with_family': sum('fam' in s for s in species.values()),
        'with_speed': sum('spd' in s and 'fam' not in s['spd'] for s in species.values()),
        'with_family_speed': sum('fam' in s.get('spd', {}) for s in species.values()),
        'raw_mb': round(len(raw) / 1e6, 2),
    }), file=sys.stderr)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
