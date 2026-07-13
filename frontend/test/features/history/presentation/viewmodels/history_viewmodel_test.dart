import 'dart:async';

import 'package:bucalscan_ai/features/history/di/history_providers.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/entities/history_query.dart';
import 'package:bucalscan_ai/features/history/domain/repositories/history_repository.dart';
import 'package:bucalscan_ai/features/history/presentation/viewmodels/history_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Analysis _analysis(int id, {String prediction = 'benign'}) => Analysis(
  id: id,
  prediction: prediction,
  confidence: 0.8,
  timestamp: DateTime.utc(2026, 1, id),
);

HistoryPage _page(
  List<Analysis> items, {
  int page = 1,
  int? total,
  bool hasNext = false,
  bool priorityEnabled = true,
}) => HistoryPage(
  items: items,
  page: page,
  pageSize: 2,
  total: total ?? items.length,
  hasNext: hasNext,
  priorityFilterEnabled: priorityEnabled,
);

class _Repository implements HistoryRepository {
  final Future<HistoryPage> Function(HistoryCriteria criteria, int page) load;
  _Repository(this.load);

  @override
  Future<List<Analysis>> getHistory() async =>
      (await load(const HistoryCriteria(), 1)).items;

  @override
  Future<HistoryPage> getHistoryPage(
    HistoryCriteria criteria, {
    required int page,
  }) => load(criteria, page);
}

ProviderContainer _container(_Repository repository) => ProviderContainer(
  overrides: [historyRepositoryProvider.overrideWithValue(repository)],
);

void main() {
  test(
    'criteria serializes normalized backend query and inclusive UTC dates',
    () {
      final criteria = HistoryCriteria(
        search: '  Ana  ',
        modelLabel: 'malignant',
        priorityCode: 'urgent',
        dateFrom: DateTime(2026, 2, 1),
        dateTo: DateTime(2026, 2, 2, 23, 59),
        sort: HistorySort.patientName,
        direction: SortDirection.ascending,
      );

      expect(criteria.toQuery(3), containsPair('search', 'Ana'));
      expect(criteria.toQuery(3), containsPair('model_label', 'malignant'));
      expect(criteria.toQuery(3), containsPair('priority', 'urgent'));
      expect(criteria.toQuery(3), containsPair('sort_by', 'patient_name'));
      expect(criteria.toQuery(3), containsPair('sort_direction', 'asc'));
      expect(criteria.toQuery(3), containsPair('page', 3));
      expect(criteria.toQuery(3)['date_from'], endsWith('Z'));
    },
  );

  test('refresh replaces page and preserves criteria', () async {
    var call = 0;
    final container = _container(
      _Repository((criteria, page) async {
        call++;
        return _page([_analysis(call)], total: 4, hasNext: true);
      }),
    );
    addTearDown(container.dispose);
    final notifier = container.read(historyViewModelProvider.notifier);

    await notifier.setModelLabel('benign');
    await notifier.refresh();

    final state = container.read(historyViewModelProvider);
    expect(state.items.single.id, 2);
    expect(state.criteria.modelLabel, 'benign');
    expect(state.total, 4);
    expect(state.priorityFilterEnabled, true);
  });

  test('new criteria rejects a late first-page response', () async {
    final benign = Completer<HistoryPage>();
    final malignant = Completer<HistoryPage>();
    final container = _container(
      _Repository((criteria, page) {
        return criteria.modelLabel == 'benign'
            ? benign.future
            : malignant.future;
      }),
    );
    addTearDown(container.dispose);
    final notifier = container.read(historyViewModelProvider.notifier);

    final oldRequest = notifier.setModelLabel('benign');
    final newRequest = notifier.setModelLabel('malignant');
    malignant.complete(_page([_analysis(2, prediction: 'malignant')]));
    await newRequest;
    benign.complete(_page([_analysis(1)]));
    await oldRequest;

    expect(container.read(historyViewModelProvider).items.single.id, 2);
    expect(
      container.read(historyViewModelProvider).criteria.modelLabel,
      'malignant',
    );
  });

  test(
    'append is de-duplicated and a stale page is rejected after query change',
    () async {
      final append = Completer<HistoryPage>();
      final replacement = Completer<HistoryPage>();
      final container = _container(
        _Repository((criteria, page) {
          if (criteria.modelLabel == 'malignant') return replacement.future;
          if (page == 2) return append.future;
          return Future.value(_page([_analysis(1)], total: 3, hasNext: true));
        }),
      );
      addTearDown(container.dispose);
      final notifier = container.read(historyViewModelProvider.notifier);
      await notifier.refresh();

      final oldAppend = notifier.loadMore();
      final newQuery = notifier.setModelLabel('malignant');
      replacement.complete(_page([_analysis(3, prediction: 'malignant')]));
      await newQuery;
      append.complete(_page([_analysis(1), _analysis(2)], page: 2, total: 3));
      await oldAppend;

      expect(
        container.read(historyViewModelProvider).items.map((item) => item.id),
        [3],
      );
    },
  );

  test(
    'successful append advances metadata and removes duplicate ids',
    () async {
      final container = _container(
        _Repository(
          (criteria, page) async => page == 1
              ? _page([_analysis(1)], total: 2, hasNext: true)
              : _page([_analysis(1), _analysis(2)], page: 2, total: 2),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(historyViewModelProvider.notifier);
      await notifier.refresh();
      await notifier.loadMore();

      final state = container.read(historyViewModelProvider);
      expect(state.items.map((item) => item.id), [1, 2]);
      expect(state.page, 2);
      expect(state.hasNext, false);
    },
  );

  test('debounced search sends only the latest query', () async {
    final searches = <String>[];
    final container = _container(
      _Repository((criteria, page) async {
        searches.add(criteria.search);
        return _page(const []);
      }),
    );
    addTearDown(container.dispose);
    final notifier = container.read(historyViewModelProvider.notifier);

    notifier.setSearchQuery('a');
    notifier.setSearchQuery('ana');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(searches, ['ana']);
    expect(container.read(historyViewModelProvider).criteria.search, 'ana');
  });

  test('filters, date, sort and clear replace the server criteria', () async {
    final seen = <HistoryCriteria>[];
    final container = _container(
      _Repository((criteria, page) async {
        seen.add(criteria);
        return _page(const []);
      }),
    );
    addTearDown(container.dispose);
    final notifier = container.read(historyViewModelProvider.notifier);

    await notifier.setPriorityCode('urgent');
    await notifier.setDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 2));
    await notifier.setSort(HistorySort.confidence, SortDirection.ascending);
    expect(seen.last.sort, HistorySort.confidence);
    expect(seen.last.dateTo!.toUtc().day, 2);
    await notifier.clearFilters();
    expect(container.read(historyViewModelProvider).criteria.hasFilters, false);
  });

  test('errors are sanitized and retryable', () async {
    var fail = true;
    final container = _container(
      _Repository((criteria, page) async {
        if (fail) throw Exception('secret server detail');
        return _page([_analysis(1)]);
      }),
    );
    addTearDown(container.dispose);
    final notifier = container.read(historyViewModelProvider.notifier);

    await notifier.refresh();
    expect(
      container.read(historyViewModelProvider).error,
      isNot(contains('secret')),
    );
    fail = false;
    await notifier.refresh();
    expect(container.read(historyViewModelProvider).items, hasLength(1));
    expect(container.read(historyViewModelProvider).error, isNull);
  });
}
