// duration_formatter.dart

String formatDurationSeconds(int? seconds) {
  if (seconds == null) return 'Unknown';
  final minutes = (seconds / 60).floor();
  final remainingSeconds = seconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}


  String formatDuration(Duration? duration) {
    if (duration == null) return "00:00";

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }