class AdminPage<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;

  const AdminPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
  });
}

class AdminQuery {
  final String search;
  final String? status;
  final String? type;
  final String? role;
  final String sortBy;
  final String sortDirection;
  final int page;
  final int pageSize;

  const AdminQuery({
    this.search = '',
    this.status,
    this.type,
    this.role,
    this.sortBy = 'created_at',
    this.sortDirection = 'desc',
    this.page = 1,
    this.pageSize = 25,
  });

  AdminQuery copyWith({
    String? search,
    String? status,
    String? type,
    String? role,
    String? sortBy,
    String? sortDirection,
    int? page,
    bool clearStatus = false,
    bool clearType = false,
    bool clearRole = false,
  }) => AdminQuery(
    search: search ?? this.search,
    status: clearStatus ? null : status ?? this.status,
    type: clearType ? null : type ?? this.type,
    role: clearRole ? null : role ?? this.role,
    sortBy: sortBy ?? this.sortBy,
    sortDirection: sortDirection ?? this.sortDirection,
    page: page ?? this.page,
    pageSize: pageSize,
  );

  Map<String, dynamic> toQuery({required String typeKey}) => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (status != null) 'status': status,
    if (type != null) typeKey: type,
    if (role != null) 'role': role,
    'sort_by': sortBy,
    'sort_direction': sortDirection,
    'page': page,
    'page_size': pageSize,
  };
}
