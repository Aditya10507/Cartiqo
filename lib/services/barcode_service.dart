import 'dart:math';

class BarcodeService {
  static final Random _random = Random();

  /// Generate a random 13-digit barcode number (EAN-13 format)
  /// Format: XXXXXXXXXXXXX (13 digits)
  static String generateRandomBarcode({String? prefix}) {
    // Generate 12 random digits for the base barcode
    // Starting with timestamp for uniqueness, then random digits
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // Last 2 digits of year
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random1 = _random.nextInt(100).toString().padLeft(2, '0');
    final random2 = _random.nextInt(10000).toString().padLeft(4, '0');
    
    // Create 12-digit base: YYMMDD(6) + RANDOM1(2) + RANDOM2(4)
    final baseBarcode = year + month + day + random1 + random2;
    
    print('DEBUG: Generated base barcode: $baseBarcode (length: ${baseBarcode.length})');
    
    // Calculate EAN-13 checksum
    final checksum = _calculateEAN13Checksum(baseBarcode);
    
    final barcode = baseBarcode + checksum;
    print('DEBUG: Final barcode: $barcode (length: ${barcode.length})');
    
    return barcode;
  }

  /// Generate a barcode with custom prefix (useful for mall-specific barcodes)
  static String generateBarcodeWithPrefix(String mallId) {
    // Use mall ID prefix (first 4 chars) + timestamp + random
    final prefix = mallId.substring(0, min(4, mallId.length)).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(1000).toString().padLeft(3, '0');
    
    // Create barcode: PREFIX(2) + TIMESTAMP(6) + RANDOM(3) + CHECKSUM(1) = 12-13 digits
    final baseBarcode = prefix.substring(0, 2) + timestamp.toString().substring(4, 10) + randomPart;
    final checksum = _calculateEAN13Checksum(baseBarcode);
    
    return baseBarcode + checksum;
  }

  /// Calculate EAN-13 checksum digit
  static String _calculateEAN13Checksum(String barcode) {
    // For simplicity, use a mathematical approach
    int sum = 0;
    for (int i = 0; i < barcode.length; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    int checksum = (10 - (sum % 10)) % 10;
    return checksum.toString();
  }

  /// Validate if a barcode has valid format
  static bool isValidBarcode(String barcode) {
    return barcode.isNotEmpty && barcode.length >= 8 && RegExp(r'^\d+$').hasMatch(barcode);
  }

  /// Format barcode for display (add spaces for readability)
  static String formatBarcodeForDisplay(String barcode) {
    if (barcode.length == 13) {
      // EAN-13 format: XXX-XXXX-XXXX-X
      return '${barcode.substring(0, 3)}-${barcode.substring(3, 7)}-${barcode.substring(7, 11)}-${barcode.substring(11)}';
    }
    return barcode;
  }
}
