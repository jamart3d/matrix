class Track {
  final String albumName;
  final String? artistName;
  final String trackArtistName;
  final int trackDuration;
  final String trackName;
  String trackNumber; // Changed back to mutable for compatibility
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

  /// Create Track from JSON with null safety and type validation
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

  /// Convert Track to JSON
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

  /// Create a copy of Track with updated values
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

  /// Safely parse integer from dynamic value
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.round();
    return null;
  }

  /// Get formatted duration as MM:SS
  String get formattedDuration {
    final minutes = trackDuration ~/ 60;
    final seconds = trackDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted duration as human readable string
  String get humanReadableDuration {
    final minutes = trackDuration ~/ 60;
    final seconds = trackDuration % 60;
    
    if (minutes == 0) {
      return '$seconds second${seconds != 1 ? 's' : ''}';
    } else if (seconds == 0) {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes != 1 ? 's' : ''} and $seconds second${seconds != 1 ? 's' : ''}';
    }
  }

  /// Check if track has valid audio URL
  bool get hasValidUrl => url.isNotEmpty && Uri.tryParse(url) != null;

  /// Check if track has album art
  bool get hasAlbumArt => albumArt != null && albumArt!.isNotEmpty;

  /// Get display name (combines track name and artist)
  String get displayName => '$trackName - $trackArtistName';

  /// Get track number as integer (useful for sorting)
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

  /// Validate that the track has all required fields
  bool get isValid {
    return albumName.isNotEmpty &&
        trackArtistName.isNotEmpty &&
        trackName.isNotEmpty &&
        url.isNotEmpty &&
        trackDuration > 0;
  }

  /// Get a summary of track validation issues
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (albumName.isEmpty) errors.add('Album name is required');
    if (trackArtistName.isEmpty) errors.add('Track artist name is required');
    if (trackName.isEmpty) errors.add('Track name is required');
    if (url.isEmpty) errors.add('URL is required');
    if (trackDuration <= 0) errors.add('Track duration must be positive');
    if (!hasValidUrl) errors.add('URL format is invalid');
    
    return errors;
  }
}