import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_constants.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(kBgColor),
    systemNavigationBarDividerColor: Color(kBgColor),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Supabase.initialize(
    url: kSupabaseUrl,
    publishableKey: kSupabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Email confirmation / password reset links redirect to
  // com.truresolve.truwardrobe://login-callback — hand that off to Supabase
  // so it completes the session instead of the OS trying to open it as a URL.
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    Supabase.instance.client.auth.getSessionFromUrl(uri);
  });
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    Supabase.instance.client.auth.getSessionFromUrl(initialUri);
  }

  runApp(const TruWardrobeApp());
}

class TruWardrobeApp extends StatelessWidget {
  const TruWardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tru Wardrobe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: false).copyWith(
        scaffoldBackgroundColor: const Color(kBgColor),
        cardColor: const Color(kCardColor),
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: const Color(kAccentColor),
              secondary: const Color(kAccentColor),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(kBgColor),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(kAccentColor),
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
