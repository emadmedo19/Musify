/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/models/discovery_feedback.dart';
import 'package:musify/screens/music_taste_page.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/discovery_feedback_service.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/music_taste_service.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/regional_discovery_service.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/async_loader.dart';
import 'package:musify/utilities/listening_stats_utils.dart';
import 'package:musify/widgets/announcement_box.dart';
import 'package:musify/widgets/discovery_presentation.dart';
import 'package:musify/widgets/listening_recap_card.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/recommended_songs_section.dart';
import 'package:musify/widgets/section_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List> _suggestedPlaylistsFuture;
  late Future<List> _favoriteAlbumsFuture;
  late Future<List<Map>> _artistProfilesFuture;
  bool _startingNineties = false;
  late Future<List> _ninetiesFuture;
  bool _tastePickerOpen = false;
  late Future<List> _recommendedSongsFuture;

  @override
  void initState() {
    super.initState();
    _loadDiscovery();
    musicTaste.addListener(_refreshDiscovery);
    discoveryFeedback.addListener(_refreshRecommendedSongs);
    if (!musicTaste.value.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openTastePicker();
      });
    }
    externalRecommendations.addListener(_refreshRecommendedSongs);
  }

  @override
  void dispose() {
    musicTaste.removeListener(_refreshDiscovery);
    discoveryFeedback.removeListener(_refreshRecommendedSongs);
    externalRecommendations.removeListener(_refreshRecommendedSongs);
    super.dispose();
  }

  void _refreshRecommendedSongs() {
    if (!mounted) return;
    setState(() {
      _recommendedSongsFuture = getRecommendedSongs();
    });
  }

  void _loadDiscovery() {
    final ready = musicTaste.value.completed;
    _suggestedPlaylistsFuture = ready
        ? getRegionalHomePlaylists()
        : Future.value([]);
    _recommendedSongsFuture = ready ? getRecommendedSongs() : Future.value([]);
    _artistProfilesFuture = ready
        ? getFavoriteArtistProfiles()
        : Future.value(<Map>[]);
    _favoriteAlbumsFuture = ready
        ? getFavoriteArtistAlbums()
        : Future.value([]);
    _ninetiesFuture = ready ? getNinetiesHomeSongs() : Future.value([]);
  }

  void _refreshDiscovery() {
    if (mounted) setState(_loadDiscovery);
  }

  Future<void> _openTastePicker() async {
    if (_tastePickerOpen) return;
    _tastePickerOpen = true;
    try {
      await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              MusicTastePage(initial: musicTaste.value, onSave: saveMusicTaste),
          fullscreenDialog: true,
        ),
      );
    } finally {
      _tastePickerOpen = false;
    }
  }

  Future<void> _saveFeedback(Map song, bool reduceArtist) async {
    final id = song['ytid']?.toString() ?? '';
    final artistKey = discoveryArtistKey(song);
    if (id.isEmpty || (reduceArtist && artistKey == null)) return;
    final before = discoveryFeedback.value;
    try {
      await saveDiscoveryFeedback(
        reduceArtist ? before.reduce(artistKey!) : before.hide(id),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reduceArtist
                ? 'هنقلّل اقتراحات الفنان ده'
                : 'مش هنقترح الأغنية دي تاني',
          ),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () async {
              try {
                await saveDiscoveryFeedback(
                  reduceArtist
                      ? discoveryFeedback.value.restoreArtist(artistKey!)
                      : discoveryFeedback.value.restoreSong(id),
                );
              } catch (_) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تعذّر حفظ التغيير. حاول مرة أخرى.'),
                    ),
                  );
              }
            },
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ التفضيل. حاول مرة أخرى.')),
        );
    }
  }

  Widget _buildTasteEntry() {
    final artists = musicTaste.value.artists;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text(
              'على ذوقك',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              artists.isEmpty
                  ? 'اختار نجومك عشان نخصص لك الموسيقى'
                  : '${artists.length} فنان من اختياراتك',
            ),
            trailing: TextButton(
              onPressed: _openTastePicker,
              child: const Text('اختار نجومك'),
            ),
          ),
          if (artists.isNotEmpty)
            FutureBuilder<List<Map>>(
              future: _artistProfilesFuture,
              builder: (context, snapshot) => ArtistDiscoveryStrip(
                artists: artists,
                images: {
                  for (final profile in snapshot.data ?? <Map>[])
                    if (profile['discoveryName'] is String &&
                        profile['image'] is String)
                      profile['discoveryName'] as String:
                          profile['image'] as String,
                },
                onArtist: (name) => context.push(
                  NavigationManager.artistPath(context, name),
                  extra: {'title': name},
                ),
              ),
            ),
          if (discoveryFeedback.value.hiddenSongs.isNotEmpty ||
              discoveryFeedback.value.reducedArtists.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                try {
                  await saveDiscoveryFeedback(DiscoveryFeedback());
                } catch (_) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تعذّر حفظ التغيير. حاول مرة أخرى.'),
                      ),
                    );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة ضبط الاقتراحات'),
            ),
        ],
      ),
    );
  }

  Widget _buildFavoriteAlbums(double height) => AsyncLoader<List<dynamic>>(
    future: _favoriteAlbumsFuture,
    builder: (context, albums) {
      if (albums.isEmpty) return const SizedBox.shrink();
      return Column(
        children: [
          const SectionHeader(
            title: 'ألبومات نجومك',
            icon: Icons.album_outlined,
          ),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => context.push(
                  NavigationManager.albumPath(
                    context,
                    albums[index]['ytid'].toString(),
                  ),
                  extra: albums[index],
                ),
                child: PlaylistCube(albums[index], size: height),
              ),
            ),
          ),
        ],
      );
    },
  );

  Future<void> _playNineties() async {
    if (_startingNineties) return;
    setState(() => _startingNineties = true);
    try {
      final songs = rankDiscoverySongs(
        await _ninetiesFuture,
        discoveryFeedback.value,
        limit: 9,
      );
      if (songs.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الأغاني مش متاحة دلوقتي. جرّب تحديث الاقتراحات.'),
            ),
          );
        return;
      }
      await audioHandler.playPlaylistSong(
        playlist: {'title': 'فاكر التسعينات؟', 'list': songs},
        songIndex: 0,
      );
    } finally {
      if (mounted) setState(() => _startingNineties = false);
    }
  }

  Widget _buildNineties() => AsyncLoader<List<dynamic>>(
    future: _ninetiesFuture,
    builder: (context, songs) {
      final visible = rankDiscoverySongs(
        songs,
        discoveryFeedback.value,
        limit: 9,
      );
      return visible.isEmpty
          ? const SizedBox.shrink()
          : RecommendedSongsSection(
              title: 'فاكر التسعينات؟',
              songs: visible,
              listKeyPrefix: 'home_nineties',
              onDiscoveryFeedback: _saveFeedback,
            );
    },
  );

  @override
  Widget build(BuildContext context) {
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded),
            SizedBox(width: 8),
            Text('Musify'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'اختار نجومك',
            onPressed: _openTastePicker,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshDiscovery();
          await Future.wait([
            _recommendedSongsFuture,
            _suggestedPlaylistsFuture,
            _favoriteAlbumsFuture,
            _ninetiesFuture,
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: commonSingleChildScrollViewPadding,
          child: Column(
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: announcementURL,
                builder: (_, _url, __) {
                  if (_url == null) return const SizedBox.shrink();
                  final isSponsorshipAnnouncement =
                      isSponsorshipAnnouncementUrl(_url);
                  final _message = isSponsorshipAnnouncement
                      ? context.l10n!.sponsorProject
                      : context.l10n!.newAnnouncement;
                  final _icon = isSponsorshipAnnouncement
                      ? FluentIcons.heart_24_filled
                      : FluentIcons.megaphone_24_filled;

                  return AnnouncementBox(
                    message: _message,
                    url: _url,
                    icon: _icon,
                    onDismiss: () async {
                      announcementURL.value = null;
                    },
                  );
                },
              ),
              DiscoveryWelcome(onEdit: _openTastePicker),
              _buildTasteEntry(),
              if (musicTaste.value.includeNineties)
                NinetiesSpotlight(
                  onPlay: _playNineties,
                  loading: _startingNineties,
                ),
              _buildFavoriteAlbums(playlistHeight),
              _buildSuggestedPlaylists(playlistHeight),
              _buildSuggestedPlaylists(playlistHeight, showOnlyLiked: true),
              if (userRecentlyPlayed.value.isNotEmpty)
                RecommendedSongsSection(
                  title: 'سمعتها مؤخرًا',
                  songs: userRecentlyPlayed.value.take(5).toList(),
                  listKeyPrefix: 'home_recent',
                ),
              _buildCurrentMonthRecapSection(),
              _buildRecommendedSongsSection(),
              _buildNineties(),
              const MiniPlayerBottomSpace(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists(
    double playlistHeight, {
    bool showOnlyLiked = false,
  }) {
    if (showOnlyLiked) {
      return ValueListenableBuilder<List<Map>>(
        valueListenable: userLikedPlaylists,
        builder: (_, likedPlaylists, __) => _buildSuggestedPlaylistsSection(
          playlistHeight,
          likedPlaylists
              .where((playlist) => !isArtistPlaylist(playlist))
              .take(recommendedCubesNumber)
              .toList(),
          showOnlyLiked: true,
        ),
      );
    }

    return AsyncLoader<List<dynamic>>(
      future: _suggestedPlaylistsFuture,
      builder: (context, playlists) =>
          _buildSuggestedPlaylistsSection(playlistHeight, playlists),
    );
  }

  Widget _buildSuggestedPlaylistsSection(
    double playlistHeight,
    List<dynamic> playlists, {
    bool showOnlyLiked = false,
  }) {
    if (playlists.isEmpty) return const SizedBox.shrink();

    final sectionTitle = showOnlyLiked
        ? context.l10n!.backToFavorites
        : context.l10n!.suggestedPlaylists;
    final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);
    final isLargeScreen = MediaQuery.of(context).size.width > 480;

    return Column(
      children: [
        SectionHeader(
          title: sectionTitle,
          icon: showOnlyLiked
              ? FluentIcons.heart_24_filled
              : FluentIcons.list_24_filled,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: playlistHeight),
          child: isLargeScreen
              ? _buildHorizontalList(playlists, itemsNumber, playlistHeight)
              : _buildCarouselView(playlists, itemsNumber, playlistHeight),
        ),
      ],
    );
  }

  Widget _buildHorizontalList(
    List<dynamic> playlists,
    int itemCount,
    double height,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: () => context.push('/home/playlist/${playlist['ytid']}'),
            child: PlaylistCube(playlist, size: height),
          ),
        );
      },
    );
  }

  Widget _buildCarouselView(
    List<dynamic> playlists,
    int itemCount,
    double height,
  ) {
    return CarouselView.weighted(
      flexWeights: const <int>[3, 2, 1],
      itemSnapping: true,
      onTap: (index) =>
          context.push('/home/playlist/${playlists[index]['ytid']}'),
      children: List.generate(itemCount, (index) {
        return PlaylistCube(playlists[index], size: height * 2);
      }),
    );
  }

  Widget _buildRecommendedSongsSection() {
    return AsyncLoader<List<dynamic>>(
      future: _recommendedSongsFuture,
      emptyWidget: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'مفيش اقتراحات جاهزة دلوقتي. جرّب التحديث أو عدّل اختياراتك.',
            ),
            TextButton.icon(
              onPressed: _refreshDiscovery,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
      builder: (context, data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return _buildRecommendedForYouSection(context, data);
      },
    );
  }

  Widget _buildCurrentMonthRecapSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: wrappedEnabled,
      builder: (_, isEnabled, __) {
        if (!isEnabled) return const SizedBox.shrink();

        final currentMonthKey = listeningStatsMonthKey(DateTime.now());
        final monthStats = listeningStatsService.monthStats(currentMonthKey);
        final songs = listeningStatsService.monthTopSongs(currentMonthKey);
        final displayMinutes = monthDisplayMinutes(monthStats);
        if (displayMinutes <= 0 && songs.isEmpty) {
          return const SizedBox.shrink();
        }

        final previewSongs = songs.take(wrappedShareSongsLimit).toList();
        final periodLabel = formatMonthPeriodLabel(
          Localizations.localeOf(context),
          currentMonthKey,
        );

        return Column(
          children: [
            SectionHeader(
              title: context.l10n!.timeMachine,
              icon: FluentIcons.data_trending_24_filled,
            ),
            ListeningRecapCard(
              periodLabel: periodLabel,
              minutes: displayMinutes,
              songs: previewSongs,
              onSongTap: (index) => _playRecapSongs(previewSongs, index),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/home/timeMachine'),
                  icon: const Icon(FluentIcons.arrow_right_24_regular),
                  label: Text(context.l10n!.listeningStats),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playRecapSongs(
    List<Map<String, dynamic>> songs,
    int index,
  ) async {
    if (songs.isEmpty) return;
    await audioHandler.playPlaylistSong(
      playlist: {'title': context.l10n!.timeMachine, 'list': songs},
      songIndex: index,
    );
  }

  Widget _buildRecommendedForYouSection(
    BuildContext context,
    List<dynamic> data,
  ) {
    return RecommendedSongsSection(
      title: context.l10n!.recommendedForYou,
      songs: data,
      listKeyPrefix: 'home_recommended',
      onDiscoveryFeedback: _saveFeedback,
    );
  }
}
