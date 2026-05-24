class CurrencyUtils {
  static const String _currencySymbol = 'EGP';
  static const String _currencyCode = 'EGP';
  static const int _decimalDigits = 2;

  // Format amount with currency symbol
  static String format(double amount) {
    return '$_currencySymbol ${amount.toStringAsFixed(_decimalDigits)}';
  }

  // Format amount without currency symbol
  static String formatWithoutSymbol(double amount) {
    return amount.toStringAsFixed(_decimalDigits);
  }

  // Parse amount from string
  static double parse(String amount) {
    try {
      // Remove currency symbol and whitespace
      final cleanAmount = amount.replaceAll(_currencySymbol, '').trim();
      return double.parse(cleanAmount);
    } catch (e) {
      return 0.0;
    }
  }

  // Calculate total amount (room cost + booking fee)
  static double calculateTotal(double roomCost, double bookingFee) {
    return roomCost + bookingFee;
  }

  // Calculate room cost from total
  static double calculateRoomCost(double total, double bookingFee) {
    return total - bookingFee;
  }

  // Validate amount
  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 999999.99;
  }

  // Format for display in lists
  static String formatForDisplay(double amount) {
    if (amount == amount.roundToDouble()) {
      return '$_currencySymbol ${amount.round()}';
    } else {
      return format(amount);
    }
  }

  // Get currency symbol
  static String get currencySymbol => _currencySymbol;

  // Get currency code
  static String get currencyCode => _currencyCode;

  // Round to 2 decimal places
  static double round(double amount) {
    return (amount * 100).round() / 100;
  }

  // Add amounts
  static double add(double a, double b) {
    return round(a + b);
  }

  // Subtract amounts
  static double subtract(double a, double b) {
    return round(a - b);
  }

  // Multiply amount by factor
  static double multiply(double amount, double factor) {
    return round(amount * factor);
  }

  // Calculate percentage
  static double percentage(double amount, double percent) {
    return round(amount * (percent / 100));
  }

  // Check if amount is within reasonable range
  static bool isReasonableAmount(double amount) {
    return amount >= 0 && amount <= 10000; // Max 10,000 EGP
  }
}
