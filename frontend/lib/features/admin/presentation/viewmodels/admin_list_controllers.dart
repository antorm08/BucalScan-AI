import 'package:bucalscan_ai/features/admin/di/admin_providers.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_query.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminListState<T> {
  final AdminQuery query;
  final List<T> items;
  final int total;
  final bool hasNext;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int? actingId;

  const AdminListState({
    this.query = const AdminQuery(),
    this.items = const [],
    this.total = 0,
    this.hasNext = false,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.actingId,
  });
}

typedef _PageLoader<T> = Future<AdminPage<T>> Function(AdminQuery query);

class AdminListController<T> extends StateNotifier<AdminListState<T>> {
  final _PageLoader<T> _loader;
  final int Function() _sessionGeneration;
  int _generation = 0;

  AdminListController(this._loader, this._sessionGeneration)
    : super(const AdminListState());

  Future<void> load({AdminQuery? query, bool append = false}) async {
    final nextQuery = query ?? state.query;
    if (append && (state.loadingMore || !state.hasNext)) return;
    final request = ++_generation;
    final session = _sessionGeneration();
    state = AdminListState(
      query: nextQuery,
      items: state.items,
      total: state.total,
      hasNext: state.hasNext,
      loading: !append,
      loadingMore: append,
      actingId: state.actingId,
    );
    try {
      final page = await _loader(nextQuery);
      if (!mounted ||
          request != _generation ||
          session != _sessionGeneration()) {
        return;
      }
      state = AdminListState(
        query: nextQuery.copyWith(page: page.page),
        items: append ? [...state.items, ...page.items] : page.items,
        total: page.total,
        hasNext: page.hasNext,
        actingId: state.actingId,
      );
    } catch (error) {
      if (!mounted ||
          request != _generation ||
          session != _sessionGeneration()) {
        return;
      }
      state = AdminListState(
        query: nextQuery,
        items: state.items,
        total: state.total,
        hasNext: state.hasNext,
        error: error.toString(),
        actingId: state.actingId,
      );
    }
  }

  Future<void> refresh() => load(query: state.query.copyWith(page: 1));

  Future<void> loadMore() => load(
    query: state.query.copyWith(page: state.query.page + 1),
    append: true,
  );

  Future<void> changeQuery(AdminQuery query) =>
      load(query: query.copyWith(page: 1));

  bool beginAction(int id) {
    if (state.actingId != null) return false;
    state = AdminListState(
      query: state.query,
      items: state.items,
      total: state.total,
      hasNext: state.hasNext,
      actingId: id,
    );
    return true;
  }

  void endAction({String? error}) {
    state = AdminListState(
      query: state.query,
      items: state.items,
      total: state.total,
      hasNext: state.hasNext,
      error: error,
    );
  }

  void invalidateRequests() => _generation++;
}

final adminCentersControllerProvider =
    StateNotifierProvider<
      AdminListController<AdminWorkspaceRequest>,
      AdminListState<AdminWorkspaceRequest>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListController(
        repository.getCentersPage,
        () => ref.read(authViewModelProvider).generation,
      );
    });

final adminAccessControllerProvider =
    StateNotifierProvider<
      AdminListController<AdminMembershipRequest>,
      AdminListState<AdminMembershipRequest>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListController(
        repository.getAccessPage,
        () => ref.read(authViewModelProvider).generation,
      );
    });

final adminUsersPageControllerProvider =
    StateNotifierProvider<
      AdminListController<AdminUser>,
      AdminListState<AdminUser>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListController(
        repository.getUsersPage,
        () => ref.read(authViewModelProvider).generation,
      );
    });

Future<bool> runAdminAction<T>({
  required AdminListController<T> controller,
  required int id,
  required Future<void> Function() action,
  required int sessionGeneration,
  required int Function() currentSessionGeneration,
}) async {
  if (!controller.beginAction(id)) return false;
  try {
    await action();
    if (sessionGeneration != currentSessionGeneration()) return false;
    controller.endAction();
    return true;
  } catch (error) {
    if (sessionGeneration == currentSessionGeneration()) {
      controller.endAction(error: error.toString());
    }
    return false;
  }
}
