class Track {
  final String albumName;
  final String? artistName;
  final String trackArtistName;
  final int trackDuration;
  final String trackName;
  String trackNumber;
  final String url;
  String? albumArt;
  final int? albumReleaseNumber;
  final String? albumReleaseDate;

  Track({
    required this.albumName,
    this.artistName,
    required this.trackArtistName,
    required this.trackDuration,
    required this.trackName,
    required this.trackNumber,
    required this.url,
    this.albumArt,
    this.albumReleaseNumber,
    this.albumReleaseDate,
  });

  @override
  String toString() {
    return '$trackName - $trackArtistName';
  }

  /// **UNCHANGED CONSTRUCTOR**
  /// This is used by the old `data.json` for the AlbumsPage.
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      albumName: json['albumName'] as String? ?? '',
      artistName: json['artistName'] as String?,
      trackArtistName: json['trackArtistName'] as String? ?? '',
      trackDuration: _parseIntSafely(json['trackDuration']) ?? 0,
      trackName: json['trackName'] as String? ?? '',
      trackNumber: json['trackNumber']?.toString() ?? '0',
      url: json['url'] as String? ?? '',
      albumArt: json['albumArt'] as String?,
      albumReleaseNumber: _parseIntSafely(json['albumReleaseNumber']),
      albumReleaseDate: json['albumReleaseDate'] as String?,
    );
  }

  /// **UPDATED CONSTRUCTOR FOR SHOWS PAGE**
  /// Creates a Track from the new compact `data_opt.json` format.
  /// Requires albumName and artistName to be passed in from the parent Show object.
  /// Now uses index-based track numbering instead of JSON 'n' field.
  factory Track.fromJsonCompact(
    Map<String, dynamic> json, {
    required String albumName,
    required String artistName,
    required int trackIndex, // NEW: Track index for proper numbering
  }) {
    return Track(
      albumName: albumName,
      artistName: artistName,
      trackArtistName: artistName, // In the new format, track artist is the same as the show artist.
      trackDuration: _parseIntSafely(json['d']) ?? 0,
      trackName: json['t'] as String? ?? 'Unknown Track',
      trackNumber: (trackIndex + 1).toString(), // Use 1-based index instead of JSON 'n'
      url: json['u'] as String? ?? '',
      // Artwork is not present in this format, so it will be null, as requested.
      albumArt: null,
      albumReleaseNumber: null,
      albumReleaseDate: null,
    );
  }

  // --- The rest of the file remains the same ---

  Map<String, dynamic> toJson() {
    return {
      'albumName': albumName,
      'artistName': artistName,
      'trackArtistName': trackArtistName,
      'trackDuration': trackDuration,
      'trackName': trackName,
      'trackNumber': trackNumber,
      'url': url,
      'albumArt': albumArt,
      'albumReleaseNumber': albumReleaseNumber,
      'albumReleaseDate': albumReleaseDate,
    };
  }
  
  Track copyWith({
    String? albumName,
    String? artistName,
    String? trackArtistName,
    int? trackDuration,
    String? trackName,
    String? trackNumber,
    String? url,
    String? albumArt,
    int? albumReleaseNumber,
    String? albumReleaseDate,
  }) {
    return Track(
      albumName: albumName ?? this.albumName,
      artistName: artistName ?? this.artistName,
      trackArtistName: trackArtistName ?? this.trackArtistName,
      trackDuration: trackDuration ?? this.trackDuration,
      trackName: trackName ?? this.trackName,
      trackNumber: trackNumber ?? this.trackNumber,
      url: url ?? this.url,
      albumArt: albumArt ?? this.albumArt,
      albumReleaseNumber: albumReleaseNumber ?? this.albumReleaseNumber,
      albumReleaseDate: albumReleaseDate ?? this.albumReleaseDate,
    );
  }

  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.round();
    return null;
  }

  String get formattedDuration {
    final minutes = trackDuration ~/ 60;
    final seconds = trackDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get hasValidUrl => url.isNotEmpty && Uri.tryParse(url) != null;

  int get trackNumberAsInt => int.tryParse(trackNumber) ?? 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Track &&
        other.albumName == albumName &&
        other.trackName == trackName &&
        other.trackArtistName == trackArtistName &&
        other.url == url;
  }

  @override
  int get hashCode {
    return Object.hash(albumName, trackName, trackArtistName, url);
  }
}