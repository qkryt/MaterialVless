class AppStrings {
  static const Map<String, Map<String, String>> _localized = {
    // Header & Titles
    'app_title': {
      'ru': 'MaterialVless',
      'en': 'MaterialVless',
    },
    'settings_title': {
      'ru': 'Настройки',
      'en': 'Settings',
    },
    'ping_all': {
      'ru': 'Проверить пинг всех серверов',
      'en': 'Ping all servers',
    },
    'add_sub_or_node': {
      'ru': 'Добавить подписку или узел',
      'en': 'Add subscription or node',
    },
    'check_updates': {
      'ru': 'Проверить обновления',
      'en': 'Check for updates',
    },

    // Status
    'status_connected': {
      'ru': 'ПОДКЛЮЧЕНО',
      'en': 'CONNECTED',
    },
    'status_connecting': {
      'ru': 'ПОДКЛЮЧЕНИЕ...',
      'en': 'CONNECTING...',
    },
    'status_disconnected': {
      'ru': 'ОТКЛЮЧЕНО',
      'en': 'DISCONNECTED',
    },
    'connect_button': {
      'ru': 'Подключить',
      'en': 'Connect',
    },
    'disconnect_button': {
      'ru': 'Отключить',
      'en': 'Disconnect',
    },

    // Subscriptions
    'subscriptions_title': {
      'ru': 'Подписки и Серверы',
      'en': 'Subscriptions & Servers',
    },
    'search_hint': {
      'ru': 'Поиск серверов, локаций или протоколов...',
      'en': 'Search servers, locations or protocols...',
    },
    'sub_options': {
      'ru': 'Настройки подписки',
      'en': 'Subscription Settings',
    },
    'sub_name': {
      'ru': 'Название подписки',
      'en': 'Subscription Name',
    },
    'sub_url': {
      'ru': 'URL адрес подписки',
      'en': 'Subscription URL',
    },
    'sub_ua': {
      'ru': 'Кастомный User-Agent для этой подписки',
      'en': 'Custom User-Agent for this subscription',
    },
    'sub_ua_hint': {
      'ru': 'По умолчанию используется глобальный User-Agent',
      'en': 'Default uses global User-Agent',
    },
    'sub_auto_update': {
      'ru': 'Автообновление',
      'en': 'Auto-Update',
    },
    'sub_update_interval': {
      'ru': 'Интервал обновления:',
      'en': 'Update Interval:',
    },
    'sub_update_on_start': {
      'ru': 'Обновить подписку при открытии программы',
      'en': 'Update subscription on app startup',
    },
    'sub_ping_on_start': {
      'ru': 'Проверить пинг подписки при открытии программы',
      'en': 'Ping subscription on app startup',
    },
    'sub_connect_best_on_start': {
      'ru': 'Подключаться на самый стабильный сервер при открытии программы',
      'en': 'Connect to fastest server on app startup',
    },
    'sub_send_hwid': {
      'ru': 'Передавать HWID устройства',
      'en': 'Send device HWID',
    },
    'sub_alt_hwid': {
      'ru': 'Использовать альтернативный HWID',
      'en': 'Use alternative HWID',
    },
    'sub_alt_hwid_hint': {
      'ru': 'Введите кастомный идентификатор устройства',
      'en': 'Enter custom device identifier',
    },

    // Settings Screen Sections
    'section_network': {
      'ru': 'Сеть и Маршрутизация',
      'en': 'Network & Routing',
    },
    'ip_strategy_title': {
      'ru': 'Предпочитаемый тип IP',
      'en': 'Preferred IP Type',
    },
    'ip_strategy_auto': {
      'ru': 'Auto (IPv4 / IPv6)',
      'en': 'Auto (IPv4 / IPv6)',
    },
    'ip_strategy_ipv4': {
      'ru': 'Только IPv4',
      'en': 'IPv4 Only',
    },
    'ip_strategy_ipv6': {
      'ru': 'Предпочитать IPv6',
      'en': 'Prefer IPv6',
    },
    'routing_preset': {
      'ru': 'Предустановленный пресет',
      'en': 'Routing Preset',
    },
    'secure_dns': {
      'ru': 'Защищенный DNS (DoH)',
      'en': 'Secure DNS (DoH)',
    },
    'secure_dns_desc': {
      'ru': 'DNS-over-HTTPS Cloudflare (1.1.1.1) и Google (8.8.8.8) через туннель',
      'en': 'DNS-over-HTTPS via Cloudflare (1.1.1.1) & Google (8.8.8.8)',
    },
    'bypass_lan': {
      'ru': 'Обход локальной сети (LAN)',
      'en': 'Bypass Local Network (LAN)',
    },
    'bypass_lan_desc': {
      'ru': 'Прямой доступ к домашним устройствам (192.168.*, 10.*, 172.16.*)',
      'en': 'Direct connection to local network devices (192.168.*, 10.*)',
    },

    // Ping & Latency
    'section_ping': {
      'ru': 'Пинг и Задержка',
      'en': 'Ping & Latency',
    },
    'ping_timeout': {
      'ru': 'Таймаут пинга (от 1 до 5 секунд)',
      'en': 'Ping Timeout (from 1 to 5 seconds)',
    },
    'ping_url': {
      'ru': 'Сайт для замера пинга',
      'en': 'Ping check URL',
    },
    'ping_proxy': {
      'ru': 'Пинг через Proxy GET',
      'en': 'Ping via Proxy GET',
    },

    // Appearance & Customization
    'section_appearance': {
      'ru': 'Внешний вид и Material You',
      'en': 'Appearance & Material You',
    },
    'color_theme': {
      'ru': 'Цветовая палитра (Material You)',
      'en': 'Color Palette (Material You)',
    },
    'theme_mode': {
      'ru': 'Режим темы',
      'en': 'Theme Mode',
    },
    'theme_system': {
      'ru': 'Системная',
      'en': 'System',
    },
    'theme_light': {
      'ru': 'Светлая',
      'en': 'Light',
    },
    'theme_dark': {
      'ru': 'Тёмная',
      'en': 'Dark',
    },
    'theme_amoled': {
      'ru': 'AMOLED Black',
      'en': 'AMOLED Black',
    },
    'font_title': {
      'ru': 'Шрифт интерфейса',
      'en': 'Interface Font',
    },
    'font_import': {
      'ru': 'Импорт (.ttf, .otf)',
      'en': 'Import (.ttf, .otf)',
    },
    'language_title': {
      'ru': 'Язык интерфейса / Language',
      'en': 'App Language',
    },

    // System Behavior
    'section_system': {
      'ru': 'Системный трей и поведение',
      'en': 'System Tray & Behavior',
    },
    'minimize_to_tray': {
      'ru': 'Сворачивать в трей при закрытии',
      'en': 'Minimize to tray on close',
    },
    'autostart': {
      'ru': 'Запускать вместе с Windows',
      'en': 'Start with Windows',
    },
    'exit_app': {
      'ru': 'Полностью выйти из приложения',
      'en': 'Quit Application',
    },
    'exit_app_desc': {
      'ru': 'Отключить VPN, очистить системный прокси и закрыть клиент',
      'en': 'Disconnect VPN, clean system proxy and close app',
    },

    // About & Updates
    'section_about': {
      'ru': 'О программе и обновления',
      'en': 'About & Updates',
    },
    'client_version': {
      'ru': 'Версия клиента',
      'en': 'Client Version',
    },
    'check_btn': {
      'ru': 'Проверить',
      'en': 'Check Now',
    },
    'download_installer': {
      'ru': 'Скачать установщик (.exe)',
      'en': 'Download Installer (.exe)',
    },
    'open_releases': {
      'ru': 'Страница релизов на GitHub',
      'en': 'GitHub Releases Page',
    },

    // General Dialog Buttons
    'cancel': {
      'ru': 'Отмена',
      'en': 'Cancel',
    },
    'save': {
      'ru': 'Сохранить',
      'en': 'Save',
    },
    'delete': {
      'ru': 'Удалить',
      'en': 'Delete',
    },
    'close': {
      'ru': 'Закрыть',
      'en': 'Close',
    },
    'apply': {
      'ru': 'Применить',
      'en': 'Apply',
    },
  };

  static String t(String key, String lang) {
    final entry = _localized[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['ru'] ?? key;
  }
}
