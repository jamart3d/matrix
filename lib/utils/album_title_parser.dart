class AlbumTitleParser {
  /// Utility to extract the venue name from a formatted album title.
  static String extractVenue(String title) {
    final match = RegExp(r'Live at (.+?) on').firstMatch(title);
    return match?.group(1) ?? title;
  }

  /// Utility to extract and format the date from a formatted album title.
  static String extractDate(String title) {
    final match = RegExp(r'on (\d{4}-\d{2}-\d{2})').firstMatch(title);
    final dateString = match?.group(1);

    if (dateString == null) {
      return '';
    }

    try {
      final dateTime = DateTime.parse(dateString);
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (_) {
      return dateString;
    }
  }
}