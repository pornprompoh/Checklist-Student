/// Represents one parsed worksheet (`.xlsx` sheet or `.csv` table) as raw
/// string rows. Pure Dart entity.
class ParsedSpreadsheetSheet {
  const ParsedSpreadsheetSheet({
    required this.name,
    required this.rows,
  });

  final String name;
  final List<List<String>> rows;

  int get columnCount {
    var maxCols = 0;
    for (final row in rows) {
      if (row.length > maxCols) maxCols = row.length;
    }
    return maxCols;
  }
}

/// Complete workbook decoded from an uploaded `.xlsx` or `.csv` file.
/// Pure Dart entity.
class ParsedSpreadsheetFile {
  const ParsedSpreadsheetFile({
    required this.filename,
    required this.sheets,
  });

  final String filename;
  final List<ParsedSpreadsheetSheet> sheets;
}
