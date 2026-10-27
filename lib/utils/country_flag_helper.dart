class CountryFlagHelper {
  /// Очищает строку от мусорных декоративных эмодзи
  static String cleanRemark(String remark) {
    return remark
        .replaceAll('💥', '')
        .replaceAll('⭐', '')
        .replaceAll('⚡', '')
        .replaceAll('🎮', '')
        .replaceAll('🏳️', '')
        .replaceAll('👇', '')
        .replaceAll('✨', '')
        .replaceAll('🔥', '')
        .replaceAll('🚀', '')
        .replaceAll('🔄', '')
        .replaceAll(RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Возвращает двухбуквенный ISO код страны для отрисовки флага
  static String getCountryCode(String remark) {
    // 1. Проверяем, есть ли уже юникод-флаг (Regional Indicator Symbols: 0x1F1E6 - 0x1F1FF)
    final flagRegex = RegExp(r'([\u{1F1E6}-\u{1F1FF}])([\u{1F1E6}-\u{1F1FF}])', unicode: true);
    final match = flagRegex.firstMatch(remark);
    if (match != null) {
      final c1 = match.group(1)!.runes.first - 0x1F1E6 + 65;
      final c2 = match.group(2)!.runes.first - 0x1F1E6 + 65;
      return '${String.fromCharCode(c1)}${String.fromCharCode(c2)}'.toUpperCase();
    }

    final lower = remark.toLowerCase();

    // 2. Поиск по городам и странам (русский и английский)
    if (lower.contains('финлянд') || lower.contains('finland') || lower.contains('helsinki') || lower.contains('хельсинки')) return 'FI';
    if (lower.contains('герман') || lower.contains('germany') || lower.contains('frankfurt') || lower.contains('франкфурт') || lower.contains('berlin') || lower.contains('берлин')) return 'DE';
    if (lower.contains('нидерланд') || lower.contains('netherlands') || lower.contains('amsterdam') || lower.contains('амстердам') || lower.contains('holland')) return 'NL';
    if (lower.contains('росси') || lower.contains('russia') || lower.contains('москв') || lower.contains('петербург') || lower.contains('spb') || lower.contains('moscow')) return 'RU';
    if (lower.contains('сша') || lower.contains('usa') || lower.contains('united states') || lower.contains('new york') || lower.contains('йорк') || lower.contains('los angeles')) return 'US';
    if (lower.contains('австри') || lower.contains('austria') || lower.contains('вена') || lower.contains('vienna')) return 'AT';
    if (lower.contains('польш') || lower.contains('poland') || lower.contains('варшав') || lower.contains('warsaw')) return 'PL';
    if (lower.contains('франци') || lower.contains('france') || lower.contains('париж') || lower.contains('paris')) return 'FR';
    if (lower.contains('великобритан') || lower.contains('london') || lower.contains('лондон') || lower.contains('uk') || lower.contains('britain')) return 'GB';
    if (lower.contains('швеци') || lower.contains('sweden') || lower.contains('стокгольм') || lower.contains('stockholm')) return 'SE';
    if (lower.contains('швейцари') || lower.contains('switzerland') || lower.contains('цюрих') || lower.contains('zurich')) return 'CH';
    if (lower.contains('сингапур') || lower.contains('singapore')) return 'SG';
    if (lower.contains('япони') || lower.contains('japan') || lower.contains('токио') || lower.contains('tokyo')) return 'JP';
    if (lower.contains('турци') || lower.contains('turkey') || lower.contains('стамбул') || lower.contains('istanbul')) return 'TR';
    if (lower.contains('казахстан') || lower.contains('kazakhstan') || lower.contains('алматы') || lower.contains('астана')) return 'KZ';
    if (lower.contains('украин') || lower.contains('ukraine') || lower.contains('киев') || lower.contains('kyiv')) return 'UA';
    if (lower.contains('эстони') || lower.contains('estonia') || lower.contains('таллин') || lower.contains('tallinn')) return 'EE';
    if (lower.contains('латви') || lower.contains('latvia') || lower.contains('рига') || lower.contains('riga')) return 'LV';
    if (lower.contains('литв') || lower.contains('lithuania') || lower.contains('вильнюс') || lower.contains('vilnius')) return 'LT';
    if (lower.contains('канада') || lower.contains('canada') || lower.contains('торонто') || lower.contains('toronto')) return 'CA';
    if (lower.contains('чехия') || lower.contains('czech') || lower.contains('прага') || lower.contains('prague')) return 'CZ';
    if (lower.contains('италия') || lower.contains('italy') || lower.contains('рим') || lower.contains('rome')) return 'IT';

    // 3. Поиск двухбуквенных кодов в скобках или разделителях: [FI], | DE |, FI-, NL
    final codeRegex = RegExp(r'\b([A-Z]{2})\b');
    final matches = codeRegex.allMatches(remark);
    for (final m in matches) {
      final code = m.group(1)!;
      if (_knownCodes.contains(code)) return code;
    }

    return 'GLOBE';
  }

  static const _knownCodes = {
    'FI', 'DE', 'NL', 'RU', 'US', 'AT', 'PL', 'FR', 'GB', 'UK',
    'SE', 'CH', 'SG', 'JP', 'TR', 'KZ', 'UA', 'EE', 'LV', 'LT',
    'CA', 'CZ', 'IT', 'ES', 'NO', 'DK', 'RO', 'BG', 'GR', 'IL',
  };
}
