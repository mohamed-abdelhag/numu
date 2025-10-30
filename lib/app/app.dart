import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numu/app/router/router.dart';
import 'package:numu/core/utils/core_logging_utility.dart';


class MyApp extends ConsumerWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {



    final router = ref.watch(routerProvider);
    CoreLoggingUtility.info('app dart file','starting my app ','returning material app router');

    return MaterialApp.router(
      title: 'Numu App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 117, 247, 56)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}