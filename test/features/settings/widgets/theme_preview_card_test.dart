import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:numu/features/settings/widgets/theme_preview_card.dart';
import 'package:numu/app/theme/theme_registry.dart';
import 'package:numu/core/utils/core_logging_utility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CoreLoggingUtility.init();

  group('ThemePreviewCard Widget Tests', () {
    late ThemeInfo testThemeInfo;

    setUp(() {
      testThemeInfo = ThemeRegistry.getTheme('blue');
    });

    Widget createTestWidget({
      required ThemeInfo themeInfo,
      required bool isSelected,
      VoidCallback? onTap,
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 250,
              child: ThemePreviewCard(
                themeInfo: themeInfo,
                isSelected: isSelected,
                onTap: onTap ?? () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('displays theme name', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
        ),
      );

      expect(find.text(testThemeInfo.displayName), findsOneWidget);
    });

    testWidgets('displays color swatches with Aa text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
        ),
      );

      // Should have 3 "Aa" text widgets for primary, secondary, tertiary
      expect(find.text('Aa'), findsNWidgets(3));
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: true,
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('does not show check icon when not selected', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('has higher elevation when selected', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: true,
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 8);
    });

    testWidgets('has lower elevation when not selected', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 2);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool wasTapped = false;
      
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
          onTap: () => wasTapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });

    testWidgets('displays all available themes correctly', (tester) async {
      final allThemes = ThemeRegistry.getAllThemes();

      for (final theme in allThemes) {
        await tester.pumpWidget(
          createTestWidget(
            themeInfo: theme,
            isSelected: false,
          ),
        );

        expect(find.text(theme.displayName), findsOneWidget);
        expect(find.text('Aa'), findsNWidgets(3));
      }
    });

    testWidgets('renders correctly in light mode', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
          brightness: Brightness.light,
        ),
      );

      expect(find.byType(ThemePreviewCard), findsOneWidget);
      expect(find.text(testThemeInfo.displayName), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
          brightness: Brightness.dark,
        ),
      );

      expect(find.byType(ThemePreviewCard), findsOneWidget);
      expect(find.text(testThemeInfo.displayName), findsOneWidget);
    });

    testWidgets('has proper semantic labels for accessibility', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: true,
        ),
      );

      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, contains(testThemeInfo.displayName));
      expect(semantics.label, contains('theme'));
    });

    testWidgets('displays bold font weight when selected', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: true,
        ),
      );

      final textWidget = tester.widget<Text>(find.text(testThemeInfo.displayName));
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('displays normal font weight when not selected', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
        ),
      );

      final textWidget = tester.widget<Text>(find.text(testThemeInfo.displayName));
      expect(textWidget.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('has border when selected', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: true,
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.side.width, 3);
    });

    testWidgets('has no border when not selected', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.side, BorderSide.none);
    });

    testWidgets('displays color containers for primary, secondary, tertiary', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeInfo: testThemeInfo,
          isSelected: false,
        ),
      );

      // Should have 3 color containers in a Row
      final containers = find.descendant(
        of: find.byType(Row).first,
        matching: find.byType(Container),
      );
      
      expect(containers, findsNWidgets(3));
    });

    testWidgets('handles long theme names with ellipsis', (tester) async {
      final longNameTheme = ThemeInfo(
        id: 'test',
        displayName: 'Very Long Theme Name That Should Be Truncated',
        themeBuilder: testThemeInfo.themeBuilder,
        previewColor: Colors.blue,
      );

      await tester.pumpWidget(
        createTestWidget(
          themeInfo: longNameTheme,
          isSelected: false,
        ),
      );

      final textWidget = tester.widget<Text>(
        find.text('Very Long Theme Name That Should Be Truncated'),
      );
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('maintains aspect ratio in grid layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: 2,
              itemBuilder: (context, index) {
                return ThemePreviewCard(
                  themeInfo: testThemeInfo,
                  isSelected: index == 0,
                  onTap: () {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ThemePreviewCard), findsNWidgets(2));
    });
  });
}
