import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class TontineFacileApp extends StatelessWidget {
  const TontineFacileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TontineFacile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppRouter.home,
    );
  }
}