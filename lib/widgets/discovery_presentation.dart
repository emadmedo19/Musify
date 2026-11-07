import 'package:material_ui/material_ui.dart';

class DiscoveryWelcome extends StatelessWidget {
  const DiscoveryWelcome({super.key, required this.onEdit});
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 8, 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'على ذوقك',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'موسيقى تشبهك',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onEdit,
          tooltip: 'اختار نجومك',
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    ),
  );
}

class ArtistDiscoveryStrip extends StatelessWidget {
  const ArtistDiscoveryStrip({
    super.key,
    required this.artists,
    this.images = const {},
    required this.onArtist,
  });
  final List<String> artists;
  final Map<String, String> images;
  final ValueChanged<String> onArtist;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 119,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: artists.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final name = artists[index];
        final image = images[name];
        final color = Theme.of(context).colorScheme;
        final fallback = Icon(
          Icons.person_outline_rounded,
          size: 34,
          color: color.primary,
        );
        return SizedBox(
          width: 88,
          child: Semantics(
            button: true,
            label: 'افتح صفحة $name',
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onArtist(name),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.primary.withValues(alpha: .65),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        width: 66,
                        height: 66,
                        color: color.surfaceContainerHigh,
                        child: image == null || image.isEmpty
                            ? fallback
                            : Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => fallback,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class NinetiesSpotlight extends StatelessWidget {
  const NinetiesSpotlight({
    super.key,
    required this.onPlay,
    this.loading = false,
  });
  final VoidCallback onPlay;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onPlay,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.primaryContainer, color.surfaceContainerHigh],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رجّع الشريط',
                          style: TextStyle(
                            color: color.onPrimaryContainer.withValues(
                              alpha: .8,
                            ),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'فاكر التسعينات؟',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text('أغاني ولسه عايشة معانا'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: loading ? null : onPlay,
                          icon: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow_rounded),
                          label: const Text('شغّل الذكريات'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 95,
                    height: 100,
                    child: CustomPaint(
                      painter: _CassettePainter(
                        color.primary,
                        color.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CassettePainter extends CustomPainter {
  const _CassettePainter(this.accent, this.ink);
  final Color accent;
  final Color ink;
  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(0, 12)
      ..rotate(-.12);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 10, size.width - 5, 65),
      const Radius.circular(9),
    );
    canvas
      ..drawRRect(body, Paint()..color = accent.withValues(alpha: .35))
      ..drawRRect(
        body,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(12, 25, size.width - 25, 24),
          const Radius.circular(8),
        ),
        Paint()..color = ink.withValues(alpha: .2),
      );
    for (final x in [27.0, size.width - 27]) {
      canvas
        ..drawCircle(Offset(x, 37), 9, Paint()..color = accent)
        ..drawCircle(
          Offset(x, 37),
          4,
          Paint()..color = ink.withValues(alpha: .6),
        );
    }
    canvas
      ..drawLine(
        const Offset(31, 66),
        Offset(size.width - 31, 66),
        Paint()
          ..color = accent
          ..strokeWidth = 3,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _CassettePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.ink != ink;
}

class DiscoveryArtistCover extends StatelessWidget {
  const DiscoveryArtistCover({
    super.key,
    required this.title,
    this.image,
    this.isChosen = false,
  });
  final String title;
  final String? image;
  final bool isChosen;
  @override
  Widget build(BuildContext context) => SliverAppBar(
    pinned: true,
    expandedHeight: 320,
    backgroundColor: const Color(0xff111810),
    foregroundColor: Colors.white,
    flexibleSpace: FlexibleSpaceBar(
      titlePadding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 18),
      centerTitle: false,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      background: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null && image!.startsWith('https://'))
            Image.network(
              image!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(
                  Icons.person_outline,
                  size: 96,
                  color: Colors.white24,
                ),
              ),
            )
          else
            const Center(
              child: Icon(
                Icons.person_outline,
                size: 96,
                color: Colors.white24,
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xdd111810)],
              ),
            ),
          ),
          if (isChosen)
            const PositionedDirectional(
              start: 24,
              bottom: 62,
              child: Chip(
                avatar: Icon(Icons.check_circle_outline, size: 16),
                label: Text('من اختياراتك'),
              ),
            ),
        ],
      ),
    ),
  );
}

class PlayerQuickLinks extends StatelessWidget {
  const PlayerQuickLinks({
    super.key,
    required this.onLyrics,
    required this.onQueue,
  });
  final VoidCallback onLyrics;
  final VoidCallback onQueue;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Card(
            child: InkWell(
              onTap: onLyrics,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.lyrics_outlined, size: 20),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'كلمات الأغنية',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: InkWell(
              onTap: onQueue,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.queue_music, size: 20),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'التالي في القائمة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
