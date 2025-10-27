import 'package:flutter/material.dart';

const Map<int, Color> primarySwatch = {
  50: Color.fromRGBO(255, 207, 68, .1),
  100: Color.fromRGBO(255, 207, 68, .2),
  200: Color.fromRGBO(255, 207, 68, .3),
  300: Color.fromRGBO(255, 207, 68, .4),
  400: Color.fromRGBO(255, 207, 68, .5),
  500: Color.fromRGBO(255, 207, 68, .6),
  600: Color.fromRGBO(255, 207, 68, .7),
  700: Color.fromRGBO(255, 207, 68, .8),
  800: Color.fromRGBO(255, 207, 68, .9),
  900: Color.fromRGBO(255, 207, 68, 1),
};
// qp blue green

const int primaryColorDark = 0xFF1C2F55; // 0xFF1C2F55
const int primaryColorLight = 0xFF519AF9; // 0xFF519AF9
const MaterialColor primaryDark = MaterialColor(0xFF1C2F55, primarySwatch);
const MaterialColor primaryLight = MaterialColor(0xFF1C2F55, primarySwatch);

const MaterialColor cardColorLight = MaterialColor(0xFF519AF9, primarySwatch);

const Color cardColorEmptied = Color.fromARGB(255, 139, 218, 228);
const Color cardColorFull = Color.fromARGB(0x33, 0x51, 0x9A, 0xF9);
const Color mapIconColorEmptied = Color.fromARGB(255, 0x51, 0x9A, 0xF9);
const Color mapIconColorFull = Color.fromARGB(255, 0x1C, 0x2F, 0x55);
// const MaterialColor cardColorFull = MaterialColor(0x33bafda7, primarySwatch);
const Color buttonColor = Color.fromARGB(255, 0x51, 0x9A, 0xF9);
const Color buttonTextColor = Colors.white;

const Color primaryDarkText = Color(0xFF000000);
const Color primaryLightText = Color(0xFFFFFFFF);

// const String companyName = 'SBS';
// const String companyName =
//     String.fromEnvironment('APP_COMPANY', defaultValue: 'SBS');

Color blendWithBackground(Color color, Color background, double opacity) {
  return Color.fromARGB(
    255,
    (color.red * opacity + background.red * (1 - opacity)).round(),
    (color.green * opacity + background.green * (1 - opacity)).round(),
    (color.blue * opacity + background.blue * (1 - opacity)).round(),
  );
}

String get companyName {
  // Grab the environment variable at runtime
  const company =
      String.fromEnvironment('APP_COMPANY', defaultValue: 'default');
  if (company.toLowerCase() == 'nutrien') {
    return 'Nutrien';
  } else if (company.toLowerCase() == 'merschman') {
    return 'Merschman';
  } else {
    return 'SBS';
  }
}

String get navLogoAsset {
  // Grab the environment variable at runtime
  const company =
      String.fromEnvironment('APP_COMPANY', defaultValue: 'default');
  if (company.toLowerCase() == 'nutrien') {
    return 'lib/assets/nutrien-logo-white-greenleaf-small.png';
  } else if (company.toLowerCase() == 'merschman') {
    return 'lib/assets/merschman-nav-logo.png';
  } else {
    return 'lib/assets/icons/sbs-dark.png';
  }
}

String get logoAsset {
  // Grab the environment variable at runtime
  const company =
      String.fromEnvironment('APP_COMPANY', defaultValue: 'default');
  if (company.toLowerCase() == 'nutrien') {
    return 'lib/assets/nutrien-logo-white-greenleaf.png';
  } else if (company.toLowerCase() == 'merschman') {
    return 'lib/assets/merschman-logo.png';
  } else {
    return 'lib/assets/logo.png';
  }
}

bool get showTagPages {
  // Grab the environment variable at runtime
  const company =
      String.fromEnvironment('APP_COMPANY', defaultValue: 'default');
  if (company.toLowerCase() == 'nutrien') {
    return false;
  } else if (company.toLowerCase() == 'merschman') {
    return false;
  } else if (company.toLowerCase() == 'maintenance') {
    return false;
  } else {
    return true;
  }
}

bool get showMaintenancePages {
  // Grab the environment variable at runtime
  const company =
      String.fromEnvironment('APP_COMPANY', defaultValue: 'default');
  if (company.toLowerCase() == 'nutrien') {
    return false;
  } else if (company.toLowerCase() == 'merschman') {
    return false;
  } else if (company.toLowerCase() == 'maintenance') {
    return true;
  } else {
    return false;
  }
}

// const bool showTagPages = true;
const bool showNavLogo = true;
const bool showMapEmptyGauge = true;
const bool showAssetLocGateActivity = true;

const myLat = 42.562548;
const myLng = -92.805299;

const String mapBoxAccessToken =
    //'pk.eyJ1IjoiZWdpbGJlcnRzZWVkYm94IiwiYSI6ImNtOHFmNGN6ZDA5dm8ya3B1YjEyb3owNXYifQ.aP40DV3MXH6KvhThr5EEgg'; //dark
    'pk.eyJ1IjoiZ3JpbXN0YWRrNyIsImEiOiJjbGZpcGsyaHYwdXUwM3RxdzJyZ3FqM2NiIn0.IyHUXyvvWApGt0S2g9KzuA'; //light

// Style IDs for dark and light modes
const String _mapBoxDarkStyleId = 'grimstadk7/cmbpamci4006n01sperv9fts1';
const String _mapBoxLightStyleId = 'mapbox/streets-v12';

// URL template for all Mapbox tile layers
const String mapBoxUrlTemplate =
    'https://api.mapbox.com/styles/v1/{id}/tiles/256/{z}/{x}/{y}@2x'
    '?access_token={accessToken}';

// Select style based on build_customer
String get mapBoxStyleId {
  final key = build_customer.toLowerCase();
  if (key == 'nutrien') {
    return _mapBoxDarkStyleId;
  } else if (key == 'merschman') {
    return _mapBoxLightStyleId;
  } else {
    return _mapBoxLightStyleId;
  }
}

// NEW UI CONSTANTS
Color get primaryHoverColor {
  return blendWithBackground(
    accent_primary_color,
    widget_background_color, // or background_grad1 depending on context
    hoverOpacity,
  );
}

/// Solid hover shade that visually matches `accent_primary_color` at 80 %
/// opacity on a white widget background, but without being translucent.
const double secondaryHoverOpacity = 0.8;

Color get secondaryHoverColor {
  return blendWithBackground(
    accent_primary_color,
    widget_background_color,
    secondaryHoverOpacity,
  );
}

const TextStyle dashboardTextStyle = TextStyle(
  color: Color.fromARGB(255, 0, 6, 12),
  fontSize: 16.0,
  fontWeight: FontWeight.normal,
  // fontFamily: 'Roboto',
);

const TextStyle dashboardTitleTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 18.0,
  fontWeight: FontWeight.bold,
);

const TextStyle dashboardNumberTextStyle = TextStyle(
  color: primaryDarkText,
  fontSize: 24.0,
  fontWeight: FontWeight.bold,
);

TextStyle assetListViewCardStandard = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: text_primary_color,
);

TextStyle assetListViewCardBold = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: text_primary_color,
);

TextStyle assetListViewCardRssiBold = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: text_primary_color,
);

TextStyle listSizeStyle = TextStyle(
  color: text_secondary_color,
  fontWeight: FontWeight.w400,
  fontSize: 12,
);

TextStyle assetPageInfoText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: text_primary_color,
);

TextStyle assetPageText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: text_primary_color,
);

TextStyle searchBoxTextStyle = TextStyle(
  color: accent_primary_color,
  fontWeight: FontWeight.w400,
  fontSize: 16,
);

TextStyle searchBoxHintTextStyle = TextStyle(
  color: accent_primary_color.withOpacity(0.7),
  fontWeight: FontWeight.w400,
  fontSize: 16,
);

const double hoverOpacity = 0.2;
const double kButtonSpacing = 8.0;
const double kCornerRadius = 8.0;

const double appMinHeight = 800; // pixels
const appBarRatio = 0.075;
const pageContentRatio = 1 - appBarRatio;

const bool debug_customer = false;
const String debug_customer_name = 'nutrien';

const String build_customer = debug_customer
    ? debug_customer_name
    : String.fromEnvironment('APP_COMPANY', defaultValue: 'sbs');

Color get background_grad1 {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF0D0D0D);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFFF6E1CC);
  } else {
    return const Color(0xFFF6E1CC);
  }
}

Color get background_grad2 {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF0D0D0D);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFFEEDCBC);
  } else {
    return const Color(0xFFEEDCBC);
  }
}

Color get widget_background_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF1C1C1C);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFFFFFFFF);
  } else {
    return const Color(0xFFFFFFFF);
  }
}

Color get accent_primary_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF4C9E00);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFF429BDB);
  } else {
    return const Color(0xFF429BDB);
  }
}

Color get light_onaccent_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF000000);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFFFFFFFF);
  } else {
    return const Color(0xFFFFFFFF);
  }
}

Color get text_primary_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFFE0E0E0);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFF000000);
  } else {
    return const Color(0xFF000000);
  }
}

Color get text_secondary_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFFD0D0D0);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFF707070);
  } else {
    return const Color(0xFF707070);
  }
}

Color get text_change_positive {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF33A935);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFF33A935);
  } else {
    return const Color(0xFF33A935);
  }
}

Color get text_change_negative {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFFF45D5F);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFFF45D5F);
  } else {
    return const Color(0xFFF45D5F);
  }
}

Color get ble_signal_strong {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF7EB77F);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFF7EB77F);
  } else {
    return const Color(0xFF7EB77F);
  }
}

Color get ble_signal_medium {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFFE48A56);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFFE48A56);
  } else {
    return const Color(0xFFE48A56);
  }
}

Color get ble_signal_weak {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFFD56062);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFFD56062);
  } else {
    return const Color(0xFFD56062);
  }
}

Color get plot_gridline_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF494949);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFFC5C5C5);
  } else {
    return const Color(0xFFC5C5C5);
  }
}

Color get plot_boarder_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF656565);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFF989898);
  } else {
    return const Color(0xFF989898);
  }
}

Color get map_pin_outline_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color(0xFF111111);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color(0xFFFFFFFF);
  } else {
    return const Color(0xFFFFFFFF);
  }
}

Color get seed_fill_color {
  return const Color.fromARGB(255, 245, 191, 90);
}

Color get empty_fill_color {
  return const Color(0xFF757575);
}

Color get map_cluster_text_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    return const Color.fromARGB(255, 194, 194, 194);
  } else if (build_customer.toLowerCase() == 'merschman') {
    return const Color.fromARGB(255, 20, 20, 20);
  } else {
    return const Color.fromARGB(255, 20, 20, 20);
  }
}

Color get modal_sheet_shading_color {
  if (build_customer.toLowerCase() == 'nutrien') {
    // Lighter gray so it shows on black backgrounds
    return const Color.fromARGB(255, 50, 50, 50);
  } else {
    // Default: same as your current semi-transparent black shadow
    return Colors.black.withOpacity(0.30);
  }
}
// const Color background_grad1 = Color(0xFFFFECD9);
// // Color.fromARGB(255, 254, 249, 237); //Color(0xFFFFECD9);
// const Color backgroundColor2 = Color(0xFFDCD1C7);
