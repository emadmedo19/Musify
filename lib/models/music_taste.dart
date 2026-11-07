import 'dart:convert';

/// Editable discovery names, not a claim to enumerate every Arab singer.
const egyptianSingers = <String>[
  'عمرو دياب',
  'تامر حسني',
  'شيرين عبد الوهاب',
  'محمد حماقي',
  'أنغام',
  'أحمد سعد',
  'محمد منير',
  'محمد فؤاد',
  'مصطفى قمر',
  'إيهاب توفيق',
  'هشام عباس',
  'حميد الشاعري',
  'حكيم',
  'علي الحجار',
  'مدحت صالح',
  'هاني شاكر',
  'هاني شنودة',
  'خالد عجاج',
  'حسام حبيب',
  'رامي صبري',
  'رامي جمال',
  'بهاء سلطان',
  'أحمد جمال',
  'محمد رشاد',
  'محمود العسيلي',
  'أبو',
  'حمزة نمرة',
  'أحمد كامل',
  'مسلم',
  'تامر عاشور',
  'أحمد بتشان',
  'لؤي',
  'شذى',
  'جنات',
  'كارمن سليمان',
  'نسمة محجوب',
  'ساندي',
  'روبي',
  'دنيا سمير غانم',
  'دينا الوديدي',
  'مريم صالح',
  'أم كلثوم',
  'عبد الحليم حافظ',
  'محمد عبد الوهاب',
  'نجاة الصغيرة',
  'شادية',
  'فايزة أحمد',
  'وردة',
  'ليلى مراد',
  'أسمهان',
  'فريد الأطرش',
  'محمد قنديل',
  'سيد مكاوي',
  'محرم فؤاد',
  'عمر فتحي',
  'علي حميدة',
  'حسن الأسمر',
  'أحمد عدوية',
  'شعبان عبد الرحيم',
  'بوسي',
  'أمينة',
  'رضا البحراوي',
  'محمود الليثي',
  'عبد الباسط حمودة',
  'طارق الشيخ',
  'حسن شاكوش',
  'حمو بيكا',
  'عمر كمال',
  'عنبة',
  'ويجز',
  'مروان بابلو',
  'مروان موسى',
  'عفروتو',
  'أبيوسف',
  'شاهين',
  'ديسكو مصر',
  'كايروكي',
  'مسار إجباري',
  'وسط البلد',
  'بلاك تيما',
  'شارموفرز',
];
const arabSingers = <String>[
  'عزيز مرقة',
  'جدل',
  'فيروز',
  'إليسا',
  'نانسي عجرم',
  'فضل شاكر',
  'حسين الجسمي',
  'ماجد المهندس',
  'راغب علامة',
  'وائل كفوري',
  'وائل جسار',
  'ملحم زين',
  'نجوى كرم',
  'نوال الزغبي',
  'نوال الكويتية',
  'ديانا حداد',
  'كارول سماحة',
  'يارا',
  'ميريام فارس',
  'هيفاء وهبي',
  'سيرين عبد النور',
  'مروان خوري',
  'عاصي الحلاني',
  'جوزيف عطية',
  'زياد برجي',
  'ناصيف زيتون',
  'الشامي',
  'جورج وسوف',
  'صباح',
  'وديع الصافي',
  'ملحم بركات',
  'ماجدة الرومي',
  'جوليا بطرس',
  'زياد الرحباني',
  'عبير نعمة',
  'أدهم نابلسي',
  'نداء شرارة',
  'عمر العبداللات',
  'ديانا كرزون',
  'توفيق الدلو',
  'نديم نور',
  'كاظم الساهر',
  'صابر الرباعي',
  'لطيفة',
  'ذكرى',
  'أميمة طالب',
  'أماني السويسي',
  'أسماء لمنور',
  'سميرة سعيد',
  'دنيا بطمة',
  'سعد لمجرد',
  'حاتم عمور',
  'الدوزي',
  'الشاب خالد',
  'الشاب مامي',
  'سولكينغ',
  'الشاب حسني',
  'محمد عبده',
  'طلال مداح',
  'عبد المجيد عبد الله',
  'راشد الماجد',
  'عبادي الجوهر',
  'رابح صقر',
  'خالد عبد الرحمن',
  'عبد الله الرويشد',
  'نبيل شعيل',
  'مطرف المطرف',
  'داليا مبارك',
  'بلقيس',
  'أحلام',
  'أصيل أبو بكر',
  'أبو بكر سالم',
  'أحمد فتحي',
  'حسين محب',
  'فؤاد عبد الواحد',
  'سيف نبيل',
  'رحمة رياض',
  'أصيل هميم',
  'نور الزين',
  'حسام الرسام',
  'حاتم العراقي',
  'سعدون جابر',
  'صلاح الزدجالي',
  'بدر الشعيبي',
];
const ninetiesSingers = <String>[
  'عمرو دياب',
  'محمد فؤاد',
  'إيهاب توفيق',
  'حميد الشاعري',
  'هشام عباس',
  'مصطفى قمر',
  'أنوشكا',
  'سيمون',
  'حنان',
  'لطيفة',
];

String normalizeSingerName(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'\s+'), ' ');

List<String> cleanSingerNames(Iterable<dynamic> values) {
  final names = <String>[];
  final seen = <String>{};
  for (final value in values) {
    if (value is! String) continue;
    final name = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty || name.length > 100) continue;
    if (seen.add(normalizeSingerName(name))) names.add(name);
    if (names.length == 200) break;
  }
  return names;
}

class MusicTaste {
  MusicTaste({
    Iterable<dynamic> artists = const [],
    this.includeNineties = true,
    this.completed = false,
  }) : artists = List.unmodifiable(cleanSingerNames(artists));

  factory MusicTaste.fromStorage(dynamic value) {
    if (value is! Map) return MusicTaste();
    return MusicTaste(
      artists: value['artists'] is List ? value['artists'] as List : const [],
      includeNineties: value['includeNineties'] != false,
      completed: value['completed'] == true,
    );
  }
  final List<String> artists;
  final bool includeNineties;
  final bool completed;
  String get cacheKey => jsonEncode([artists, includeNineties]);
  Map<String, dynamic> toStorage() => {
    'version': 1,
    'artists': artists,
    'includeNineties': includeNineties,
    'completed': completed,
  };
}
