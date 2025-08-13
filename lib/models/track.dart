// lib/models/track.dart

import 'package:flutter/foundation.dart';

@immutable // Annotation to enforce immutability
class Track {
  final String albumName;
  final String? artistName;
  final String trackArtistName;
  final int trackDuration;
  final String trackName;
  final String trackNumber; // Made final
  final String url;
  final String? albumArt; // Made final
  final int? albumReleaseNumber;
  final String? albumReleaseDate;
  final String? shnid;

  const Track({ // Made constructor const
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
    this.shnid,
  });

  @override
  String toString() {
    return '$trackName - $trackArtistName';
  }

  /// Original constructor for `data.json`.
  /// **IMPROVEMENT**: Now accepts an optional `shnid` to be passed in.
  factory Track.fromJson(Map<String, dynamic> json, {String? shnid}) {
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
      shnid: shnid, // Use the passed-in shnid
    );
  }

  /// Constructor for compact data from `archive_tracks_...json` (ShowsPage).
  factory Track.fromJsonCompact(
      Map<String, dynamic> json, {
        required String albumName,
        required String artistName,
        required int trackIndex,
        required String shnid,
      }) {
    return Track(
      albumName: albumName,
      artistName: artistName,
      trackArtistName: artistName,
      trackDuration: _parseIntSafely(json['d']) ?? 0,
      trackName: json['t'] as String? ?? 'Unknown Track',
      trackNumber: (trackIndex + 1).toString(),
      url: json['u'] as String? ?? '',
      shnid: shnid,
    );
  }

  /// Creates a Track from the compact format found in `data_opt.json`.
  factory Track.fromAlbumOptJson({
    required Map<String, dynamic> json,
    required String albumName,
    required String artistName,
    required int albumReleaseNumber,
    required String albumReleaseDate,
  }) {
    return Track(
      albumName: albumName,
      artistName: artistName,
      trackArtistName: artistName,
      trackDuration: _parseIntSafely(json['d']) ?? 0,
      trackName: json['t'] as String? ?? 'Unknown Track',
      trackNumber: (json['n'] as num? ?? 0).toString(),
      url: json['u'] as String? ?? '',
      albumReleaseNumber: albumReleaseNumber,
      albumReleaseDate: albumReleaseDate,
      shnid: null,
    );
  }

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
      'shnid': shnid,
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
    // Use ValueGetter to distinguish between null and not provided
    ValueGetter<String?>? albumArt,
    int? albumReleaseNumber,
    String? albumReleaseDate,
    ValueGetter<String?>? shnid,
  }) {
    return Track(
      albumName: albumName ?? this.albumName,
      artistName: artistName ?? this.artistName,
      trackArtistName: trackArtistName ?? this.trackArtistName,
      trackDuration: trackDuration ?? this.trackDuration,
      trackName: trackName ?? this.trackName,
      trackNumber: trackNumber ?? this.trackNumber,
      url: url ?? this.url,
      albumArt: albumArt != null ? albumArt() : this.albumArt,
      albumReleaseNumber: albumReleaseNumber ?? this.albumReleaseNumber,
      albumReleaseDate: albumReleaseDate ?? this.albumReleaseDate,
      shnid: shnid != null ? shnid() : this.shnid,
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
        other.url == url &&
        other.shnid == shnid;
  }

  @override
  int get hashCode {
    return Object.hash(url, shnid);
  }
}