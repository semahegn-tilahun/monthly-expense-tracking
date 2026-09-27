import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_constants.dart';
import 'providers/budget_provider.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MonthlyExpenseApp());
}

class MonthlyExpenseApp extends StatelessWidget {
  const MonthlyExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BudgetProvider()..bootstrap(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primary),
          scaffoldBackgroundColor: AppConstants.bg,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: AppConstants.bg,
            foregroundColor: Colors.black87,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppConstants.primary, width: 1.4)),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        home: Consumer<BudgetProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const SplashScreen();
            if (provider.currentUser == null) return const LoginScreen();
            return const HomeShell();
          },
        ),
      ),
    );
  }
}
