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

  // Подписка
  String userAgent; // MaterialVless, Clash.Meta, Sing-box, v2rayN, etc.
  bool sendHwid;
  bool autoUpdateOnStart;
  int autoUpdateIntervalHours; // 0 = off, 1, 2, 6, 12, 24

  // Маршрутизация
  String routingPreset; // none, russia
  bool secureDnsEnabled; // DNS-over-HTTPS (DoH) Cloudflare/Google via proxy
  bool bypassLanEnabled; // Direct bypass for 192.168.*, 10.*, 172.16.*
  String geoipUrl;
  String geositeUrl;
  bool autoUpdateRulesOnStart;

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
    this.userAgent = 'v2rayN/6.42',
    this.sendHwid = true,
    this.autoUpdateOnStart = true,
    this.autoUpdateIntervalHours = 12,
    this.routingPreset = 'russia',
    this.secureDnsEnabled = true,
    this.bypassLanEnabled = true,
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
    String? customFontPath,
    bool? useDynamicColor,
    String? themeMode,
    String? userAgent,
    bool? sendHwid,
    bool? autoUpdateOnStart,
    int? autoUpdateIntervalHours,
    String? routingPreset,
    bool? secureDnsEnabled,
    bool? bypassLanEnabled,
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
      customFontPath: customFontPath ?? this.customFontPath,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      themeMode: themeMode ?? this.themeMode,
      userAgent: userAgent ?? this.userAgent,
      sendHwid: sendHwid ?? this.sendHwid,
      autoUpdateOnStart: autoUpdateOnStart ?? this.autoUpdateOnStart,
      autoUpdateIntervalHours: autoUpdateIntervalHours ?? this.autoUpdateIntervalHours,
      routingPreset: routingPreset ?? this.routingPreset,
      secureDnsEnabled: secureDnsEnabled ?? this.secureDnsEnabled,
      bypassLanEnabled: bypassLanEnabled ?? this.bypassLanEnabled,
      geoipUrl: geoipUrl ?? this.geoipUrl,
      geositeUrl: geositeUrl ?? this.geositeUrl,
      autoUpdateRulesOnStart: autoUpdateRulesOnStart ?? this.autoUpdateRulesOnStart,
    );
  }

  Map<String, dynamic> toJson() => {
        'routingPreset': routingPreset,
        'secureDnsEnabled': secureDnsEnabled,
        'bypassLanEnabled': bypassLanEnabled,
        'pingUrl': pingUrl,
        'pingTimeoutMs': pingTimeoutMs,
        'speedtestUrl': speedtestUrl,
        'autoUpdateRulesOnStart': autoUpdateRulesOnStart,
        'userAgent': userAgent,
        'sendHwid': sendHwid,
        'themeMode': themeMode,
        'fontFamily': fontFamily,
        'customFontPath': customFontPath,
        'useDynamicColor': useDynamicColor,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      routingPreset: json['routingPreset']?.toString() ?? 'russia',
      secureDnsEnabled: json['secureDnsEnabled'] != false,
      bypassLanEnabled: json['bypassLanEnabled'] != false,
      pingUrl: json['pingUrl']?.toString() ?? 'http://cp.cloudflare.com/',
      pingTimeoutMs: int.tryParse(json['pingTimeoutMs']?.toString() ?? '2000') ?? 2000,
      speedtestUrl: json['speedtestUrl']?.toString() ?? 'http://cachefly.cachefly.net/1mb.test',
      autoUpdateRulesOnStart: json['autoUpdateRulesOnStart'] == true,
      userAgent: json['userAgent']?.toString() ?? 'v2rayN/6.42',
      sendHwid: json['sendHwid'] != false,
      themeMode: json['themeMode']?.toString() ?? 'dark',
      fontFamily: json['fontFamily']?.toString() ?? 'Google Sans',
      customFontPath: json['customFontPath']?.toString(),
      useDynamicColor: json['useDynamicColor'] == true,
    );
  }
}
