import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingapp/widgets/paged_list.dart';

/// Fake server with [total] items, records which offsets were asked for.
class _FakeSource {
  final int total;
  final calls = <int>[];
  bool failNext = false;
  _FakeSource(this.total);

  Future<PageResult<String>> fetch(int offset, int limit) async {
    calls.add(offset);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (failNext) {
      failNext = false;
      throw 'Server down';
    }
    final end = (offset + limit).clamp(0, total);
    return PageResult(
        [for (var i = offset; i < end; i++) 'Item $i'], total);
  }
}

Widget _app(_FakeSource src) => MaterialApp(
      home: Scaffold(
        body: PagedList<String>(
          fetch: src.fetch,
          pageSize: 20,
          header: (t) => Text('$t total'),
          itemBuilder: (_, s, __) => SizedBox(height: 60, child: Text(s)),
        ),
      ),
    );

void main() {
  testWidgets('loads the first page, then more as you scroll, then stops',
      (tester) async {
    final src = _FakeSource(45);
    await tester.pumpWidget(_app(src));
    await tester.pumpAndSettle();

    expect(find.text('45 total'), findsOneWidget);
    expect(find.text('Item 0'), findsOneWidget);
    expect(src.calls, [0]);

    // Scroll to the bottom repeatedly: pages at 20 and 40, then no more calls
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
    }
    expect(src.calls, [0, 20, 40]);
    expect(find.text('Item 44'), findsOneWidget);
    expect(find.text('No more results'), findsOneWidget);
  });

  testWidgets('shows the error with Retry, and Retry loads', (tester) async {
    final src = _FakeSource(5)..failNext = true;
    await tester.pumpWidget(_app(src));
    await tester.pumpAndSettle();

    expect(find.text('Server down'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Item 4'), findsOneWidget);
    expect(find.text('No more results'), findsOneWidget);
  });

  testWidgets('empty result shows the empty text', (tester) async {
    final src = _FakeSource(0);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PagedList<String>(
          fetch: src.fetch,
          emptyText: 'No bookings found',
          itemBuilder: (_, s, __) => Text(s),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No bookings found'), findsOneWidget);
  });
}
