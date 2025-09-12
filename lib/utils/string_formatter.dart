// lib/utils/string_formatter.dart

/// Formats a track title by conditionally removing a leading number.
/// e.g., "01. Bertha" becomes "Bertha" if [hideNumber] is true.
String formatTrackTitle(String title, {required bool hideNumber}) {
  if (!hideNumber) {
    return title; // If the setting is off, return the original title.
  }
  // This regex looks for one or two digits at the start of the string,
  // followed by optional whitespace, a period, or a hyphen.
  final regex = RegExp(r'^\d{1,3}[\s.-]*');
  return title.replaceFirst(regex, '');
}


String formatDateHumanReadable(String date) {
  try {
    final dateTime = DateTime.parse(date);
    const List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = monthNames[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    return '$month $day, $year';
  } catch (e) {
    return date;
  }
}