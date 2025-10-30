import 'package:flutter/material.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('home screen dart file','building home screen','returning center with text home screen');
    return const Center(
      child: Text('Home Screen'),
    );
  }
}


