import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/components/player/shows_player/shows_player_app_bar.dart';
import 'package:matrix/components/player/shows_player/shows_player_background.dart';
import 'package:matrix/components/player/shows_player/shows_player_controls_area.dart';
import 'package:matrix/components/player/shows_player/shows_player_track_list.dart';
import 'package:matrix/providers/track_player_provider.dart';
import 'package:provider/provider.dart';

// Constants for styling and layout to improve readability and maintainability.
const double _kListItemHeight = 80.0;
const double _kControlsAreaBottomPadding = 220.0;
const Duration _kTrackChangeAnimationDuration = Duration(milliseconds: 600);
const Duration _kFadeAnimationDuration = Duration(milliseconds: 300);
const Duration _kPulseAnimationDuration = Duration(milliseconds: 1500);
const Color _kThemeColor = Colors.yellow;
const Color _kThemeAccentColor = Colors.redAccent;
const List<Shadow> _kGlowShadows = [
  Shadow(color: _kThemeAccentColor, blurRadius: 3),
  Shadow(color: _kThemeAccentColor, blurRadius: 6),
];

class ShowsMusicPlayerPage extends StatefulWidget {
  const ShowsMusicPlayerPage({super.key});

  @override
  State<ShowsMusicPlayerPage> createState() => _ShowsMusicPlayerPageState();
}

class _ShowsMusicPlayerPageState extends State<ShowsMusicPlayerPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final TrackPlayerProvider _playerProvider;

  // Animation controllers
  late final AnimationController _trackChangeController;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;

  // Animations
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  // State for tracking track changes to trigger animations
  String _previousTrackName = '';
  int _previousTrackIndex = -1;
  bool _hasAnimatedOnce = false;

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<TrackPlayerProvider>();
    _initializeState();
    _initializeAnimations();
    _playerProvider.addListener(_onPlayerStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _scrollToCurrent(_playerProvider.currentIndex, isInitial: true);
          _fadeController.forward();
        }
      });
    });
  }

  void _initializeState() {
    final currentTrack = _playerProvider.currentTrack;
    if (currentTrack != null) {
      _previousTrackName = currentTrack.trackName;
      _previousTrackIndex = _playerProvider.currentIndex;
    }
  }

  void _initializeAnimations() {
    _trackChangeController = AnimationController(
        duration: _kTrackChangeAnimationDuration, vsync: this);
    _fadeController =
        AnimationController(duration: _kFadeAnimationDuration, vsync: this);
    _pulseController =
        AnimationController(duration: _kPulseAnimationDuration, vsync: this);

    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(
          parent: _pulseController,
          curve: Curves.easeInOut,
        ));
    _slideAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _trackChangeController,
          curve: Curves.easeOutCubic,
        ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    if (_playerProvider.isPlaying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playerProvider.removeListener(_onPlayerStateChanged);
    _trackChangeController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final currentTrack = _playerProvider.currentTrack;
    final currentIndex = _playerProvider.currentIndex;
    final currentTrackName = currentTrack?.trackName ?? '';

    if (currentIndex != _previousTrackIndex &&
        currentTrackName != _previousTrackName) {
      _animateTrackChange();
      _previousTrackIndex = currentIndex;
      _previousTrackName = currentTrackName;
    }

    if (_playerProvider.isPlaying && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_playerProvider.isPlaying && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.animateTo(0.0,
          duration: const Duration(milliseconds: 100));
    }
    _scrollToCurrent(_playerProvider.currentIndex);
  }

  void _animateTrackChange() {
    HapticFeedback.selectionClick();
    _hasAnimatedOnce = true;
    _trackChangeController.forward(from: 0.0);
    _fadeController.forward(from: 0.0);
  }

  void _scrollToCurrent(int index, {bool isInitial = false}) {
    if (_scrollController.hasClients && index >= 0) {
      final screenHeight = MediaQuery.sizeOf(context).height;
      final targetOffset = (index * _kListItemHeight) - (screenHeight / 4);
      final maxScroll = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxScroll);

      if (isInitial) {
        _scrollController.jumpTo(clampedOffset);
      } else {
        _scrollController.animateTo(clampedOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ShowsPlayerBackground(),
          _ContentView(),
        ],
      ),
    );
  }
}

class _ContentView extends StatelessWidget {
  const _ContentView();

  @override
  Widget build(BuildContext context) {
    // Re-access state and animations from the parent State object
    final state = context.findAncestorStateOfType<_ShowsMusicPlayerPageState>()!;

    return SafeArea(
      child: Stack(
        children: [
          CustomScrollView(
            controller: state._scrollController,
            slivers: [
              ShowsPlayerSliverAppBar(
                onClearPlaylist: () => _showClearPlaylistDialog(context),
                themeColor: _kThemeColor,
                themeAccentColor: _kThemeAccentColor,
                glowShadows: _kGlowShadows,
              ),
              ShowsPlayerTrackList(
                slideAnimation: state._slideAnimation,
                fadeAnimation: state._fadeAnimation,
                hasAnimatedOnce: state._hasAnimatedOnce,
                themeColor: _kThemeColor,
                glowShadows: _kGlowShadows,
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: _kControlsAreaBottomPadding),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ShowsPlayerControlsArea(
              trackChangeAnimation: state._trackChangeController,
              pulseAnimation: state._pulseAnimation,
              themeColor: _kThemeColor,
              glowShadows: _kGlowShadows,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearPlaylistDialog(BuildContext context) {
    final provider = context.read<TrackPlayerProvider>();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Playlist'),
          content: const Text(
              'Are you sure you want to clear the current playlist?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await provider.clearPlaylist();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}