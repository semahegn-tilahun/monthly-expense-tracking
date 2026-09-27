import 'package:flutter/material.dart';

import '../core/app_constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: AppConstants.primary,
              child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
            ),
            SizedBox(height: 18),
            Text('Monthly Expense Tracker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
