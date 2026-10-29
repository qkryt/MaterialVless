class AppSettings {
  // Пинг
  String pingUrl;
  String speedtestUrl;
  int pingTimeoutMs; // 1000 to 5000 ms
  bool pingViaProxy;
  bool disconnectBeforePing;

  // Тема и шрифт
  String fontFamily;
  String? customFontPath;
  bool useDynamicColor;
  String themeMode; // system, light, dark, amoled
  int accentColor; // Hex seed color, default 0xFF6750A4
  String appLanguage; // ru, en

  // Поведение окна и запуск
  bool autoStartWithWindows;
  bool minimizeToTrayOnClose;
  bool startMinimized;

  // Подписка
  String userAgent; // MaterialVless, Clash.Meta, Sing-box, v2rayN, etc.
  bool sendHwid;
  bool autoUpdateOnStart;
  int autoUpdateIntervalHours; // 0 = off, 1, 2, 6, 12, 24

  // Маршрутизация и IP
  String routingPreset; // none, russia
  String ipStrategy; // auto, ipv4, ipv6
  bool secureDnsEnabled; // DNS-over-HTTPS (DoH) Cloudflare/Google via proxy
  bool bypassLanEnabled; // Direct bypass for 192.168.*, 10.*, 172.16.*
  String geoipUrl;
  String geositeUrl;
  bool autoUpdateRulesOnStart;
  List<String> customRoutingRules; // Extra direct domain suffixes

  AppSettings({
    this.pingUrl = 'http://cp.cloudflare.com/',
    this.speedtestUrl = 'http://cachefly.cachefly.net/1mb.test',
    this.pingTimeoutMs = 2000,
    this.pingViaProxy = true,
    this.disconnectBeforePing = true,
    this.fontFamily = 'Google Sans',
    this.customFontPath,
    this.useDynamicColor = false,
    this.themeMode = 'dark',
    this.accentColor = 0xFF6750A4,
    this.appLanguage = 'ru',
    this.autoStartWithWindows = false,
    this.minimizeToTrayOnClose = true,
    this.startMinimized = false,
    this.userAgent = 'MaterialVless/2.14.3',
    this.sendHwid = true,
    this.autoUpdateOnStart = true,
    this.autoUpdateIntervalHours = 12,
    this.routingPreset = 'russia',
    this.ipStrategy = 'auto',
    this.secureDnsEnabled = true,
    this.bypassLanEnabled = true,
    this.geoipUrl = 'https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat',
    this.geositeUrl = 'https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat',
    this.autoUpdateRulesOnStart = true,
    this.customRoutingRules = const [],
  });

  AppSettings copyWith({
    String? pingUrl,
    String? speedtestUrl,
    int? pingTimeoutMs,
    bool? pingViaProxy,
    bool? disconnectBeforePing,
    String? fontFamily,
    String? customFontPath,
    bool? useDynamicColor,
    String? themeMode,
    int? accentColor,
    String? appLanguage,
    bool? autoStartWithWindows,
    bool? minimizeToTrayOnClose,
    bool? startMinimized,
    String? userAgent,
    bool? sendHwid,
    bool? autoUpdateOnStart,
    int? autoUpdateIntervalHours,
    String? routingPreset,
    String? ipStrategy,
    bool? secureDnsEnabled,
    bool? bypassLanEnabled,
    String? geoipUrl,
    String? geositeUrl,
    bool? autoUpdateRulesOnStart,
    List<String>? customRoutingRules,
  }) {
    return AppSettings(
      pingUrl: pingUrl ?? this.pingUrl,
      speedtestUrl: speedtestUrl ?? this.speedtestUrl,
      pingTimeoutMs: pingTimeoutMs ?? this.pingTimeoutMs,
      pingViaProxy: pingViaProxy ?? this.pingViaProxy,
      disconnectBeforePing: disconnectBeforePing ?? this.disconnectBeforePing,
      fontFamily: fontFamily ?? this.fontFamily,
      customFontPath: customFontPath ?? this.customFontPath,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      appLanguage: appLanguage ?? this.appLanguage,
      autoStartWithWindows: autoStartWithWindows ?? this.autoStartWithWindows,
      minimizeToTrayOnClose: minimizeToTrayOnClose ?? this.minimizeToTrayOnClose,
      startMinimized: startMinimized ?? this.startMinimized,
      userAgent: userAgent ?? this.userAgent,
      sendHwid: sendHwid ?? this.sendHwid,
      autoUpdateOnStart: autoUpdateOnStart ?? this.autoUpdateOnStart,
      autoUpdateIntervalHours: autoUpdateIntervalHours ?? this.autoUpdateIntervalHours,
      routingPreset: routingPreset ?? this.routingPreset,
      ipStrategy: ipStrategy ?? this.ipStrategy,
      secureDnsEnabled: secureDnsEnabled ?? this.secureDnsEnabled,
      bypassLanEnabled: bypassLanEnabled ?? this.bypassLanEnabled,
      geoipUrl: geoipUrl ?? this.geoipUrl,
      geositeUrl: geositeUrl ?? this.geositeUrl,
      autoUpdateRulesOnStart: autoUpdateRulesOnStart ?? this.autoUpdateRulesOnStart,
      customRoutingRules: customRoutingRules ?? this.customRoutingRules,
    );
  }

  Map<String, dynamic> toJson() => {
        'routingPreset': routingPreset,
        'ipStrategy': ipStrategy,
        'secureDnsEnabled': secureDnsEnabled,
        'bypassLanEnabled': bypassLanEnabled,
        'pingUrl': pingUrl,
        'pingTimeoutMs': pingTimeoutMs,
        'speedtestUrl': speedtestUrl,
        'autoUpdateRulesOnStart': autoUpdateRulesOnStart,
        'userAgent': userAgent,
        'sendHwid': sendHwid,
        'themeMode': themeMode,
        'accentColor': accentColor,
        'appLanguage': appLanguage,
        'autoStartWithWindows': autoStartWithWindows,
        'minimizeToTrayOnClose': minimizeToTrayOnClose,
        'startMinimized': startMinimized,
        'fontFamily': fontFamily,
        'customFontPath': customFontPath,
        'useDynamicColor': useDynamicColor,
        'customRoutingRules': customRoutingRules,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      routingPreset: json['routingPreset']?.toString() ?? 'russia',
      ipStrategy: json['ipStrategy']?.toString() ?? 'auto',
      secureDnsEnabled: json['secureDnsEnabled'] != false,
      bypassLanEnabled: json['bypassLanEnabled'] != false,
      pingUrl: json['pingUrl']?.toString() ?? 'http://cp.cloudflare.com/',
      pingTimeoutMs: int.tryParse(json['pingTimeoutMs']?.toString() ?? '2000') ?? 2000,
      speedtestUrl: json['speedtestUrl']?.toString() ?? 'http://cachefly.cachefly.net/1mb.test',
      autoUpdateRulesOnStart: json['autoUpdateRulesOnStart'] == true,
      userAgent: json['userAgent']?.toString() ?? 'MaterialVless/2.14.3',
      sendHwid: json['sendHwid'] != false,
      themeMode: json['themeMode']?.toString() ?? 'dark',
      accentColor: int.tryParse(json['accentColor']?.toString() ?? '0xFF6750A4') ?? 0xFF6750A4,
      appLanguage: json['appLanguage']?.toString() ?? 'ru',
      autoStartWithWindows: json['autoStartWithWindows'] == true,
      minimizeToTrayOnClose: json['minimizeToTrayOnClose'] != false,
      startMinimized: json['startMinimized'] == true,
      fontFamily: json['fontFamily']?.toString() ?? 'Google Sans',
      customFontPath: json['customFontPath']?.toString(),
      useDynamicColor: json['useDynamicColor'] == true,
      customRoutingRules: (json['customRoutingRules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
