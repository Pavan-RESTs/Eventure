import 'package:eventure/core/constants/api_constants.dart';
import 'package:eventure/core/theme/theme.dart';
import 'package:eventure/src/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
      url: IApiConstants.supaBaseUrl, anonKey: IApiConstants.anonKey);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        theme: IAppTheme.lightTheme,
        darkTheme: IAppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen());
  }
}
