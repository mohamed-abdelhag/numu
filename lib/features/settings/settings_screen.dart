import 'package:flutter/material.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';



class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('SettingsScreen', 'build', 'Building settings screen');
    CoreLoggingUtility.info('profile screen dart file','building profile screen','returning center with text profile screen');
    return const Column(
      children: [
        NumuAppBar(
          title: 'Settings',
        ),
        Expanded(
          child: Center(
            child: Text('Settings Screen'),
          ),
        ),
      ],
    );
  }
}
