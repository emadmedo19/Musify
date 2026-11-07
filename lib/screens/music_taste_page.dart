import 'package:flutter/material.dart';
import 'package:musify/models/music_taste.dart';

class MusicTastePage extends StatefulWidget {
  const MusicTastePage({
    super.key,
    required this.initial,
    required this.onSave,
  });
  final MusicTaste initial;
  final Future<void> Function(MusicTaste taste) onSave;

  @override
  State<MusicTastePage> createState() => _MusicTastePageState();
}

class _MusicTastePageState extends State<MusicTastePage> {
  final _search = TextEditingController();
  late List<String> _selected;
  late bool _nineties;
  bool _saving = false;
  String? _error;
  String _filter = 'الكل';

  @override
  void initState() {
    super.initState();
    _selected = [...widget.initial.artists];
    _nineties = widget.initial.includeNineties;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _isSelected(String name) => _selected.any(
    (value) => normalizeSingerName(value) == normalizeSingerName(name),
  );

  void _toggle(String name) {
    setState(() {
      if (_isSelected(name)) {
        _selected.removeWhere(
          (value) => normalizeSingerName(value) == normalizeSingerName(name),
        );
      } else {
        _selected = cleanSingerNames([..._selected, name]);
      }
    });
  }

  Future<void> _save({bool skip = false}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        MusicTaste(
          artists: skip ? const [] : _selected,
          includeNineties: _nineties,
          completed: true,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = 'تعذّر حفظ اختياراتك. حاول مرة أخرى.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = switch (_filter) {
      'مصري' => egyptianSingers,
      'عربي' => arabSingers,
      'تسعينات' => ninetiesSingers,
      'اختياراتي' => _selected,
      _ => cleanSingerNames([
        ...egyptianSingers,
        ...arabSingers,
        ...ninetiesSingers,
        ..._selected,
      ]),
    };
    final query = normalizeSingerName(_search.text);
    final names = base
        .where((name) => normalizeSingerName(name).contains(query))
        .toList();
    final typedName = _search.text.trim();
    final canAdd =
        typedName.isNotEmpty &&
        typedName.length <= 100 &&
        !_isSelected(typedName) &&
        !cleanSingerNames([
          ...egyptianSingers,
          ...arabSingers,
          ...ninetiesSingers,
        ]).any((name) => normalizeSingerName(name) == query);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: widget.initial.completed && !_saving,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('اختار نجومك'),
            automaticallyImplyLeading: widget.initial.completed,
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مين بتحب تسمع؟',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اختار فنانين مصريين وعرب عشان نجهّز لك أغاني وألبومات وقوائم على ذوقك. تقدر تضيف أي اسم ناقص وتعدّل اختياراتك بعدين.',
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _search,
                        enabled: !_saving,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'ابحث أو اكتب اسم فنان',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final filter in [
                              'الكل',
                              'مصري',
                              'عربي',
                              'تسعينات',
                              'اختياراتي',
                            ])
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                child: ChoiceChip(
                                  label: Text(filter),
                                  selected: _filter == filter,
                                  onSelected: _saving
                                      ? null
                                      : (_) => setState(() => _filter = filter),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (canAdd)
                        TextButton.icon(
                          onPressed: _saving
                              ? null
                              : () {
                                  _toggle(typedName);
                                  _search.clear();
                                },
                          icon: const Icon(Icons.add),
                          label: Text('إضافة "$typedName" لاختياراتي'),
                        ),
                    ],
                  ),
                ),
              ),
              if (names.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'مفيش أسماء مطابقة. تقدر تضيف اسم فنان من البحث.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisExtent: 76,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: names.length,
                    itemBuilder: (context, index) {
                      final name = names[index];
                      final selected = _isSelected(name);
                      return Semantics(
                        selected: selected,
                        button: true,
                        child: Card(
                          color: selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: InkWell(
                            onTap: _saving ? null : () => _toggle(name),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.person_outline,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ضيف لي أغاني التسعينات'),
                    value: _nineties,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _nineties = value ?? true),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _saving ||
                              (_selected.isEmpty && !widget.initial.completed)
                          ? null
                          : _save,
                      child: Text(
                        _saving
                            ? 'جارٍ الحفظ…'
                            : 'حفظ اختياراتي (${_selected.length})',
                      ),
                    ),
                  ),
                  if (!widget.initial.completed)
                    TextButton(
                      onPressed: _saving ? null : () => _save(skip: true),
                      child: const Text('استكشف من غير اختيارات دلوقتي'),
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
