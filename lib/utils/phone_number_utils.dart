/// Utility class for handling Kenyan phone number formatting and validation
class PhoneNumberUtils {
  /// Formats a Kenyan phone number to international format (+254...)
  /// Handles inputs like:
  /// - 0712345678 -> +254712345678
  /// - 712345678 -> +254712345678
  /// - +254712345678 -> +254712345678
  /// - 254712345678 -> +254712345678
  static String formatKenyanNumber(String input) {
    // Remove all whitespace and special characters except +
    String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');

    // Remove leading + if present
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // Handle different formats
    if (cleaned.startsWith('254')) {
      // Already has country code
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      // Remove leading 0 and add country code
      return '+254${cleaned.substring(1)}';
    } else if (cleaned.length == 9) {
      // Missing leading 0 and country code
      return '+254$cleaned';
    } else {
      // Return as is with +254 prefix
      return '+254$cleaned';
    }
  }

  /// Validates if a phone number is a valid Kenyan number
  /// Valid formats: +254[7XX|1XX]XXXXXXX (9 digits after country code)
  /// Valid prefixes: 7 (mobile), 1 (mobile - Safaricom)
  static bool isValidKenyanNumber(String phone) {
    // Format the number first
    String formatted = formatKenyanNumber(phone);

    // Check if it matches the pattern +254[71]XXXXXXXX
    // Kenyan mobile numbers start with 7 or 1 and have 9 digits total
    RegExp regex = RegExp(r'^\+254[71]\d{8}$');
    return regex.hasMatch(formatted);
  }

  /// Masks a phone number for display purposes
  /// Example: +254712345678 -> +254 *** *** 678
  static String maskNumber(String phone) {
    String formatted = formatKenyanNumber(phone);

    if (formatted.length >= 13) {
      // +254712345678 -> +254 *** *** 678
      String countryCode = formatted.substring(0, 4); // +254
      String lastDigits = formatted.substring(formatted.length - 3); // 678
      return '$countryCode *** *** $lastDigits';
    }

    return formatted;
  }

  /// Gets a user-friendly error message for invalid phone numbers
  static String getValidationError(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    String formatted = formatKenyanNumber(phone);

    if (!formatted.startsWith('+254')) {
      return 'Phone number must be a Kenyan number (+254)';
    }

    if (formatted.length != 13) {
      return 'Phone number must be 9 digits after country code';
    }

    if (!RegExp(r'^\+254[71]').hasMatch(formatted)) {
      return 'Phone number must start with +2547 or +2541';
    }

    if (!isValidKenyanNumber(phone)) {
      return 'Invalid Kenyan phone number format';
    }

    return '';
  }

  /// Formats a phone number for display in UI
  /// Example: +254712345678 -> +254 712 345 678
  static String formatForDisplay(String phone) {
    String formatted = formatKenyanNumber(phone);

    if (formatted.length == 13) {
      // +254712345678 -> +254 712 345 678
      return '${formatted.substring(0, 4)} ${formatted.substring(4, 7)} ${formatted.substring(7, 10)} ${formatted.substring(10)}';
    }

    return formatted;
  }
}
