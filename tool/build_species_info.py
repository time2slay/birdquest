"""Builds the bundled species index from Wikidata, Wikipedia and Commons.

For every bird in the BirdNET+ label file it collects:
  * Russian common names (Wikidata, CC0) and the English/Russian Wikipedia
    article titles, so the app can fetch descriptions on demand or in the
    optional Encyclopedia download (descriptions are not bundled);
  * one lead photo from Wikimedia Commons, but only if its license allows
    commercial use (CC0, public domain, CC BY, CC BY-SA), together with the
    author and license needed for attribution.

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

UA = 'BirdQuestDataBuilder/1.0 (offline bird field guide app; build-time script)'
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
        if rec:
            species[name] = rec

    data = {
        'version': 1,
        'built': time.strftime('%Y-%m-%d'),
        'sources': {
            'titles': 'Wikipedia (en, ru) article titles',
            'names': 'Wikidata, CC0',
            'images': 'Wikimedia Commons; per-file licenses',
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
        'raw_mb': round(len(raw) / 1e6, 2),
    }), file=sys.stderr)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
