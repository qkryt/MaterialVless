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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Возвращает официальный эмодзи флага страны по названию или коду
  static String getCountryFlag(String remark) {
    final clean = cleanRemark(remark);

    // 1. Проверяем, есть ли уже юникод-флаг (Regional Indicator Symbols: 0x1F1E6 - 0x1F1FF)
    final flagRegex = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);
    final match = flagRegex.firstMatch(clean);
    if (match != null) {
      return match.group(0)!;
    }

    final lower = clean.toLowerCase();

    // 2. Поиск по городам и странам (русский и английский)
    if (lower.contains('финлянд') || lower.contains('finland') || lower.contains('helsinki') || lower.contains('хельсинки')) return '🇫🇮';
    if (lower.contains('герман') || lower.contains('germany') || lower.contains('frankfurt') || lower.contains('франкфурт') || lower.contains('berlin') || lower.contains('берлин')) return '🇩🇪';
    if (lower.contains('нидерланд') || lower.contains('netherlands') || lower.contains('amsterdam') || lower.contains('амстердам') || lower.contains('holland')) return '🇳🇱';
    if (lower.contains('росси') || lower.contains('russia') || lower.contains('москв') || lower.contains('петербург') || lower.contains('spb') || lower.contains('moscow')) return '🇷🇺';
    if (lower.contains('сша') || lower.contains('usa') || lower.contains('united states') || lower.contains('new york') || lower.contains('йорк') || lower.contains('los angeles')) return '🇺🇸';
    if (lower.contains('австри') || lower.contains('austria') || lower.contains('вена') || lower.contains('vienna')) return '🇦🇹';
    if (lower.contains('польш') || lower.contains('poland') || lower.contains('варшав') || lower.contains('warsaw')) return '🇵🇱';
    if (lower.contains('франци') || lower.contains('france') || lower.contains('париж') || lower.contains('paris')) return '🇫🇷';
    if (lower.contains('великобритан') || lower.contains('london') || lower.contains('лондон') || lower.contains('uk') || lower.contains('britain')) return '🇬🇧';
    if (lower.contains('швеци') || lower.contains('sweden') || lower.contains('стокгольм') || lower.contains('stockholm')) return '🇸🇪';
    if (lower.contains('швейцари') || lower.contains('switzerland') || lower.contains('цюрих') || lower.contains('zurich')) return '🇨🇭';
    if (lower.contains('сингапур') || lower.contains('singapore')) return '🇸🇬';
    if (lower.contains('япони') || lower.contains('japan') || lower.contains('токио') || lower.contains('tokyo')) return '🇯🇵';
    if (lower.contains('турци') || lower.contains('turkey') || lower.contains('стамбул') || lower.contains('istanbul')) return '🇹🇷';
    if (lower.contains('казахстан') || lower.contains('kazakhstan') || lower.contains('алматы') || lower.contains('астана')) return '🇰🇿';
    if (lower.contains('украин') || lower.contains('ukraine') || lower.contains('киев') || lower.contains('kyiv')) return '🇺🇦';
    if (lower.contains('эстони') || lower.contains('estonia') || lower.contains('таллин') || lower.contains('tallinn')) return '🇪🇪';
    if (lower.contains('латви') || lower.contains('latvia') || lower.contains('рига') || lower.contains('riga')) return '🇱🇻';
    if (lower.contains('литв') || lower.contains('lithuania') || lower.contains('вильнюс') || lower.contains('vilnius')) return '🇱🇹';
    if (lower.contains('канада') || lower.contains('canada') || lower.contains('торонто') || lower.contains('toronto')) return '🇨🇦';
    if (lower.contains('чехия') || lower.contains('czech') || lower.contains('прага') || lower.contains('prague')) return '🇨🇿';

    // 3. Поиск двухбуквенных кодов в скобках или разделителях: [FI], | DE |, FI-, NL
    final codeRegex = RegExp(r'\b([A-Z]{2})\b');
    final matches = codeRegex.allMatches(clean);
    for (final m in matches) {
      final code = m.group(1)!;
      final flag = _isoToFlag(code);
      if (flag != '🌐') return flag;
    }

    return '🌐';
  }

  static String _isoToFlag(String code) {
    const knownCodes = {
      'FI': '🇫🇮', 'DE': '🇩🇪', 'NL': '🇳🇱', 'RU': '🇷🇺', 'US': '🇺🇸',
      'AT': '🇦🇹', 'PL': '🇵🇱', 'FR': '🇫🇷', 'GB': '🇬🇧', 'UK': '🇬🇧',
      'SE': '🇸🇪', 'CH': '🇨🇭', 'SG': '🇸🇬', 'JP': '🇯🇵', 'TR': '🇹🇷',
      'KZ': '🇰🇿', 'UA': '🇺🇦', 'EE': '🇪🇪', 'LV': '🇱🇻', 'LT': '🇱🇹',
      'CA': '🇨🇦', 'CZ': '🇨🇿', 'IT': '🇮🇹', 'ES': '🇪🇸', 'NO': '🇳🇴',
      'DK': '🇩🇰', 'BG': '🇧🇬', 'RO': '🇷🇴', 'MD': '🇲🇩', 'GE': '🇬🇪',
      'AM': '🇦🇲', 'BY': '🇧🇾', 'HK': '🇭🇰', 'TW': '🇹🇼', 'KR': '🇰🇷',
    };
    return knownCodes[code.toUpperCase()] ?? '🌐';
  }
}
