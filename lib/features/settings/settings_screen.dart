import 'package:flutter/material.dart';
import 'package:numu/core/utils/core_logging_utility.dart';



class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('profile screen dart file','building profile screen','returning center with text profile screen');
    return const Center(
      child: Text('Settings Screen'),
    );
  }
}
