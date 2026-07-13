import 'dart:async';

import 'package:bucalscan_ai/features/admin/domain/entities/admin_query.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_list_controllers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load more appends pages without truncating the first page', () async {
    final controller = AdminListController<int>(
      (query) async => AdminPage(
        items: query.page == 1 ? const [1, 2] : const [3],
        page: query.page,
        pageSize: 2,
        total: 3,
        hasNext: query.page == 1,
      ),
      () => 1,
    );
    addTearDown(controller.dispose);

    await controller.load();
    await controller.loadMore();

    expect(controller.state.items, [1, 2, 3]);
    expect(controller.state.total, 3);
    expect(controller.state.hasNext, isFalse);
  });

  test('superseded query response cannot overwrite newer results', () async {
    final oldResponse = Completer<AdminPage<int>>();
    final controller = AdminListController<int>((query) {
      if (query.search == 'old') return oldResponse.future;
      return Future.value(
        const AdminPage(
          items: [2],
          page: 1,
          pageSize: 25,
          total: 1,
          hasNext: false,
        ),
      );
    }, () => 1);
    addTearDown(controller.dispose);

    final oldLoad = controller.changeQuery(const AdminQuery(search: 'old'));
    await controller.changeQuery(const AdminQuery(search: 'new'));
    oldResponse.complete(
      const AdminPage(
        items: [1],
        page: 1,
        pageSize: 25,
        total: 1,
        hasNext: false,
      ),
    );
    await oldLoad;

    expect(controller.state.query.search, 'new');
    expect(controller.state.items, [2]);
  });

  test('session generation change discards an in-flight response', () async {
    var session = 1;
    final response = Completer<AdminPage<int>>();
    final controller = AdminListController<int>(
      (_) => response.future,
      () => session,
    );
    addTearDown(controller.dispose);

    final load = controller.load();
    session = 2;
    response.complete(
      const AdminPage(
        items: [1],
        page: 1,
        pageSize: 25,
        total: 1,
        hasNext: false,
      ),
    );
    await load;

    expect(controller.state.items, isEmpty);
  });
}
