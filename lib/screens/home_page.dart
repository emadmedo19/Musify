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
import 'package:musify/screens/music_taste_page.dart';
import 'package:musify/services/common_services.dart';
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
  late Future<List> _ninetiesFuture;
  bool _tastePickerOpen = false;
  late Future<List> _recommendedSongsFuture;

  @override
  void initState() {
    super.initState();
    _loadDiscovery();
    musicTaste.addListener(_refreshDiscovery);
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
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: artists.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: Text(artists[index]),
                  onPressed: () => context.push(
                    NavigationManager.artistPath(context, artists[index]),
                    extra: {'title': artists[index]},
                  ),
                ),
              ),
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

  Widget _buildNineties() => AsyncLoader<List<dynamic>>(
    future: _ninetiesFuture,
    builder: (context, songs) => songs.isEmpty
        ? const SizedBox.shrink()
        : RecommendedSongsSection(
            title: 'فاكر التسعينات؟',
            songs: songs,
            listKeyPrefix: 'home_nineties',
          ),
  );

  @override
  Widget build(BuildContext context) {
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Musify.'),
        actions: [
          IconButton(
            tooltip: 'اختار نجومك',
            onPressed: _openTastePicker,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: announcementURL,
              builder: (_, _url, __) {
                if (_url == null) return const SizedBox.shrink();
                final isSponsorshipAnnouncement = isSponsorshipAnnouncementUrl(
                  _url,
                );
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
            _buildTasteEntry(),
            _buildFavoriteAlbums(playlistHeight),
            _buildSuggestedPlaylists(playlistHeight),
            _buildSuggestedPlaylists(playlistHeight, showOnlyLiked: true),
            _buildCurrentMonthRecapSection(),
            _buildRecommendedSongsSection(),
            _buildNineties(),
            const MiniPlayerBottomSpace(),
          ],
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
    );
  }
}
