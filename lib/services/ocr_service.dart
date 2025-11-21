// lib/services/receipt_ocr_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ParsedReceiptData {
  final String? store;
  final double? total;
  final DateTime? date;
  final String? categoryHint;

  const ParsedReceiptData({
    this.store,
    this.total,
    this.date,
    this.categoryHint,
  });
}

class ReceiptOcrService {
  ReceiptOcrService({TextRecognizer? recognizer})
    : _recognizer =
          recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<ParsedReceiptData> parseImage(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Image file does not exist: $imagePath');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(inputImage);

    // Flatten all lines into a simple list of strings.
    final lines = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          lines.add(text);
        }
      }
    }

    final store = _guessStore(lines);
    final total = _guessTotal(lines);
    final date = _guessDate(lines);
    final category = _guessCategory(store, lines);

    return ParsedReceiptData(
      store: store,
      total: total,
      date: date,
      categoryHint: category,
    );
  }

  void dispose() {
    _recognizer.close();
  }

  // ---------- Heuristic helpers ----------

  String? _guessStore(List<String> lines) {
    if (lines.isEmpty) return null;

    // Take the first non-numeric-looking line that doesn't look like a total line.
    for (final line in lines) {
      final lower = line.toLowerCase();
      final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(line);
      final looksLikeTotal =
          lower.contains('total') || lower.contains('amount due');
      if (hasLetter && !looksLikeTotal) {
        return line;
      }
    }

    // Fallback: first line.
    return lines.first;
  }

  double? _guessTotal(List<String> lines) {
    final amountRegex = RegExp(r'([0-9]+[.,][0-9]{2})');

    double? bestFromTotalLine;
    double maxAmount = 0.0;

    for (final line in lines) {
      final lower = line.toLowerCase();
      final matches = amountRegex.allMatches(line).toList();
      if (matches.isEmpty) continue;

      for (final m in matches) {
        final raw = m.group(0)!;
        final normalized = raw.replaceAll(',', '.');
        final val = double.tryParse(normalized);
        if (val == null) continue;

        // Prefer amounts from "total" lines
        if (lower.contains('total') || lower.contains('amount due')) {
          if (bestFromTotalLine == null || val > bestFromTotalLine) {
            bestFromTotalLine = val;
          }
        }

        if (val > maxAmount) {
          maxAmount = val;
        }
      }
    }

    return bestFromTotalLine ?? (maxAmount > 0 ? maxAmount : null);
  }

  DateTime? _guessDate(List<String> lines) {
    // Very simple: MM/DD/YYYY or MM-DD-YYYY or MM/DD/YY
    final dateRegex = RegExp(r'(\b\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}\b)');

    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match == null) continue;

      final raw = match.group(0)!;
      final parts = raw.split(RegExp(r'[\/\-]'));
      if (parts.length != 3) continue;

      int m = int.tryParse(parts[0]) ?? 1;
      int d = int.tryParse(parts[1]) ?? 1;
      int y = int.tryParse(parts[2]) ?? DateTime.now().year;

      if (y < 100) {
        // Convert 2-digit year to 20xx
        y += 2000;
      }

      try {
        return DateTime(y, m, d);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  String? _guessCategory(String? store, List<String> lines) {
    final text = ((store ?? '') + ' ' + lines.join(' ')).toLowerCase();

    if (text.contains('walmart') ||
        text.contains('costco') ||
        text.contains('target') ||
        text.contains('grocery') ||
        text.contains('market')) {
      return 'Groceries';
    }

    if (text.contains('mcdonald') ||
        text.contains('restaurant') ||
        text.contains('starbucks') ||
        text.contains('cafe') ||
        text.contains('coffee')) {
      return 'Dining';
    }

    if (text.contains('shell') ||
        text.contains('chevron') ||
        (text.contains('7-eleven') && text.contains('fuel')) ||
        text.contains('gas')) {
      return 'Fuel';
    }

    if (text.contains('best buy') ||
        text.contains('apple store') ||
        text.contains('electronics')) {
      return 'Electronics';
    }

    if (text.contains('amazon') || text.contains('online')) {
      return 'Home';
    }

    return null;
  }
}
