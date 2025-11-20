import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:numu/features/habits/models/category.dart';
import 'package:numu/features/tasks/widgets/task_form.dart';

void main() {
  testWidgets('TaskForm renders without RenderFlex overflow in Category dropdown', (
    WidgetTester tester,
  ) async {
    // Arrange
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categories = [
      Category(
        id: 1,
        name: 'Short Category',
        color: '0xFF000000',
        createdAt: DateTime.now(),
      ),
      Category(
        id: 2,
        name:
            'A very very very very very very very very very very long category name that might cause overflow if not handled correctly',
        color: '0xFF000000',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TaskForm(
              titleController: titleController,
              descriptionController: descriptionController,
              categories: categories,
              onDueDateChanged: (_) {},
              onCategoryChanged: (_) {},
              onReminderEnabledChanged: (_) {},
              onReminderMinutesBeforeChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    // Act & Assert
    // 1. Verify initial render doesn't crash
    expect(find.byType(TaskForm), findsOneWidget);

    // 2. Open the dropdown to trigger the rendering of items
    final dropdownFinder = find.byType(DropdownButtonFormField<int?>);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // 3. Verify the items are visible (and thus rendered)
    expect(find.text('Short Category'), findsOneWidget);
    // The long text might be truncated, so we might not find the full text if it's correctly handled with ellipsis,
    // but if it's NOT handled, it might throw an exception during layout.
    // We mainly care that no exception was thrown.
  });
}
