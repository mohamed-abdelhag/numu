import 'package:flutter/material.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

class NumuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showDrawerButton;

  const NumuAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showDrawerButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      centerTitle: true,
      title: Text(title),
      leading: leading ?? (showDrawerButton
          ? Builder(
              builder: (BuildContext context) {
                CoreLoggingUtility.info('NumuAppBar', 'Builder', 'Building drawer button');
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    CoreLoggingUtility.info('NumuAppBar', 'onPressed', 'Menu button clicked, attempting to open drawer');
                    try {
                      Scaffold.of(context).openDrawer();
                      CoreLoggingUtility.info('NumuAppBar', 'openDrawer', 'openDrawer() called successfully');
                    } catch (e) {
                      CoreLoggingUtility.error('NumuAppBar', 'openDrawer', 'Failed to open drawer: $e');
                    }
                  },
                );
              },
            )
          : null),
      actions: actions,
    );
  }
}