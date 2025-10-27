import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter/material.dart';

import 'features/journal/view/food_journal_page.dart';

class KgFoodJournalApp extends StatelessWidget {
  const KgFoodJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KG Food Journal',
        builder: Authenticator.builder(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7A4F8C)),
          useMaterial3: true,
        ),
        home: const FoodJournalPage(),
      ),
    );
  }
}
