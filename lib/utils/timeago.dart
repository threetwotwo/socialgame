String timeAgo(DateTime date) {
  final duration = DateTime.now().difference(date);

  if (duration.inSeconds <= 0) {
    return 'just now';
  }
  if (duration.inMinutes <= 0) {
    return '${duration.inSeconds} seconds';
  }
  if (duration.inHours <= 0) {
    return '${duration.inMinutes} minutes';
  }
  if (duration.inDays <= 0) {
    return '${duration.inHours} hours';
  }
  if (duration.inDays < 30) {
    return '${duration.inDays} days';
  }
  if (duration.inDays < 365) {
    final months = duration.inDays / 30;
    return '${months.floor()} months';
  }

  final years = duration.inDays / 365;
  return '${years.floor()} years';
}
