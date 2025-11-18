import 'package:flutter/material.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('ProfileScreen', 'build', 'Building profile screen');
    CoreLoggingUtility.info('profile screen dart file','building profile screen','returning center with text profile screen');
    return const Column(
      children: [
        NumuAppBar(
          title: 'Profile',
        ),
        Expanded(
          child: Center(
            child: Text('Profile Screen'),
          ),
        ),
      ],
    );
  }
}
