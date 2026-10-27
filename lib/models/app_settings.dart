class AppSettings {
  // Пинг
  String pingUrl;
  String speedtestUrl;
  int pingTimeoutMs;
  bool pingViaProxy;
  bool disconnectBeforePing;

  // Тема и шрифт
  String fontFamily;
  bool useDynamicColor;
  String themeMode; // system, light, dark, amoled

  // Подписка
  String userAgent; // MaterialVless, Clash.Meta, Sing-box, v2rayN
  bool sendHwid;
  bool autoUpdateOnStart;
  int autoUpdateIntervalHours; // 0 = off, 6, 12, 24

  // Маршрутизация
  String routingPreset; // none (default), russia
  String geoipUrl;
  String geositeUrl;
  bool autoUpdateRulesOnStart;

  AppSettings({
    this.pingUrl = 'http://cp.cloudflare.com/',
    this.speedtestUrl = 'http://cachefly.cachefly.net/1mb.test',
    this.pingTimeoutMs = 1000,
    this.pingViaProxy = true,
    this.disconnectBeforePing = true,
    this.fontFamily = 'Google Sans',
    this.useDynamicColor = true,
    this.themeMode = 'system',
    this.userAgent = 'MaterialVless',
    this.sendHwid = true,
    this.autoUpdateOnStart = true,
    this.autoUpdateIntervalHours = 12,
    this.routingPreset = 'none',
    this.geoipUrl = 'https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat',
    this.geositeUrl = 'https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat',
    this.autoUpdateRulesOnStart = true,
  });

  AppSettings copyWith({
    String? pingUrl,
    String? speedtestUrl,
    int? pingTimeoutMs,
    bool? pingViaProxy,
    bool? disconnectBeforePing,
    String? fontFamily,
    bool? useDynamicColor,
    String? themeMode,
    String? userAgent,
    bool? sendHwid,
    bool? autoUpdateOnStart,
    int? autoUpdateIntervalHours,
    String? routingPreset,
    String? geoipUrl,
    String? geositeUrl,
    bool? autoUpdateRulesOnStart,
  }) {
    return AppSettings(
      pingUrl: pingUrl ?? this.pingUrl,
      speedtestUrl: speedtestUrl ?? this.speedtestUrl,
      pingTimeoutMs: pingTimeoutMs ?? this.pingTimeoutMs,
      pingViaProxy: pingViaProxy ?? this.pingViaProxy,
      disconnectBeforePing: disconnectBeforePing ?? this.disconnectBeforePing,
      fontFamily: fontFamily ?? this.fontFamily,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      themeMode: themeMode ?? this.themeMode,
      userAgent: userAgent ?? this.userAgent,
      sendHwid: sendHwid ?? this.sendHwid,
      autoUpdateOnStart: autoUpdateOnStart ?? this.autoUpdateOnStart,
      autoUpdateIntervalHours: autoUpdateIntervalHours ?? this.autoUpdateIntervalHours,
      routingPreset: routingPreset ?? this.routingPreset,
      geoipUrl: geoipUrl ?? this.geoipUrl,
      geositeUrl: geositeUrl ?? this.geositeUrl,
      autoUpdateRulesOnStart: autoUpdateRulesOnStart ?? this.autoUpdateRulesOnStart,
    );
  }
}
