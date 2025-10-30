import 'package:flutter/material.dart';
import 'package:numu/core/utils/core_logging_utility.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('profile screen dart file','building profile screen','returning center with text profile screen');
    return const Center(
      child: Text('Profile Screen'),
    );
  }
}
