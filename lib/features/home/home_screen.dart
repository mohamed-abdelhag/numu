import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';
import 'package:numu/core/widgets/shell/numu_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CoreLoggingUtility.info('HomeScreen', 'build', 'Building home screen');
    CoreLoggingUtility.info('home screen dart file','building home screen','returning center with text home screen');
    return Column(
      children: [
        NumuAppBar(
          title: 'Home',
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.go('/settings');
              },
            ),
          ],
        ),
        const Expanded(
          child: Center(
            child: Text('Home Screen'),
          ),
        ),
      ],
    );
  }
}


