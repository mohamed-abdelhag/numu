import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NumuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfileButton;
  final bool showSettingsButton;
  final bool showMenuButton;

  const NumuAppBar({
    super.key,
    required this.title,
    this.showProfileButton = false,
    this.showSettingsButton = false,
    this.showMenuButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      centerTitle: true,
      title: Text(title),
      leading: showMenuButton
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            )
          : (showProfileButton
              ? IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    context.go('/profile');
                  },
                )
              : null),
      actions: [
        if (showSettingsButton)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.go('/settings');
            },
          ),
      ],
    );
  }
}