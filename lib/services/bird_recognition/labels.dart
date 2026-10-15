import '../../data/models.dart';

/// One row of the BirdNET+ V3 label file.
class ModelLabel {
  const ModelLabel({
    required this.index,
    required this.id,
    required this.scientificName,
    required this.commonName,
    required this.taxonClass,
    required this.taxonOrder,
  });

  final int index;
  final String id;
  final String scientificName;
  final String commonName;
  final String taxonClass;
  final String taxonOrder;

  bool get isBird => taxonClass == 'Aves';

  SpeciesInfo toSpeciesInfo() => SpeciesInfo(
    scientificName: scientificName,
    commonName: commonName,
    taxonOrder: taxonOrder,
    modelLabelId: id,
  );
}

/// Parses the semicolon-separated label CSV
/// (`idx;id;sci_name;com_name;class;order`), tolerating a UTF-8 BOM.
List<ModelLabel> parseLabels(String csv) {
  final lines = csv.replaceFirst('﻿', '').split(RegExp(r'\r?\n'));
  if (lines.isEmpty) return const [];
  final header = lines.first.split(';');
  int col(String name) {
    final i = header.indexOf(name);
    if (i < 0) throw FormatException('Label file is missing "$name" column');
    return i;
  }

  final iIdx = col('idx'),
      iId = col('id'),
      iSci = col('sci_name'),
      iCom = col('com_name'),
      iClass = col('class'),
      iOrder = col('order');

  final labels = <ModelLabel>[];
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final f = line.split(';');
    labels.add(
      ModelLabel(
        index: int.parse(f[iIdx]),
        id: f[iId],
        scientificName: f[iSci],
        commonName: f[iCom].isEmpty ? f[iSci] : f[iCom],
        taxonClass: f[iClass],
        taxonOrder: f[iOrder],
      ),
    );
  }
  labels.sort((a, b) => a.index.compareTo(b.index));
  for (var i = 0; i < labels.length; i++) {
    if (labels[i].index != i) {
      throw FormatException('Label indices are not contiguous at $i');
    }
  }
  return labels;
}
