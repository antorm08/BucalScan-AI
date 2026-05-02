import 'package:flutter/material.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _activeFilter = 'Todos';
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _placeholderHistory = [
    {
      'id': 'ID-8924',
      'date': '24 Oct, 2023',
      'prediction': 'Maligna',
      'confidence': 94,
    },
    {
      'id': 'ID-7731',
      'date': '23 Oct, 2023',
      'prediction': 'Benigna',
      'confidence': 82,
    },
    {
      'id': 'ID-6512',
      'date': '22 Oct, 2023',
      'prediction': 'Benigna',
      'confidence': 98,
    },
    {
      'id': 'ID-5409',
      'date': '21 Oct, 2023',
      'prediction': 'Benigna',
      'confidence': 95,
    },
    {
      'id': 'ID-4301',
      'date': '20 Oct, 2023',
      'prediction': 'OPMD',
      'confidence': 78,
    },
    {
      'id': 'ID-3215',
      'date': '19 Oct, 2023',
      'prediction': 'Maligna',
      'confidence': 91,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_activeFilter == 'Todos') return _placeholderHistory;
    return _placeholderHistory.where((item) {
      if (_activeFilter == 'Maligna') return item['prediction'] == 'Maligna';
      if (_activeFilter == 'Benigna') return item['prediction'] == 'Benigna';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00355F);
    const primaryContainer = Color(0xFF0F4C81);
    const surfaceContainerLowest = Colors.white;
    const surfaceContainerHigh = Color(0xFFE6E8EA);
    const surfaceContainerHighest = Color(0xFFE0E3E5);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF42474F);
    const outline = Color(0xFF727780);
    const outlineVariant = Color(0xFFC2C7D1);
    const error = Color(0xFFBA1A1A);
    const errorContainer = Color(0xFFFFDAD6);
    const onErrorContainer = Color(0xFF93000A);
    const background = Color(0xFFF7F9FB);
    const secondary = Color(0xFF505F76);
    final benignBg = const Color(0xFFE8F5E9);
    final benignText = const Color(0xFF1B5E20);

    final filters = ['Fecha', 'Todos', 'Maligna', 'Benigna'];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.medical_services, color: primary),
            const SizedBox(width: 4),
            Text(
              'OralScan AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: background,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: outline),
                    hintText: 'Buscar ID de paciente, nombre o fecha...',
                    hintStyle: TextStyle(color: onSurfaceVariant, fontSize: 14),
                    filled: true,
                    fillColor: surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: primaryContainer, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      final isActive = filter == _activeFilter;
                      Color bgColor, textColor;

                      if (filter == 'Maligna' && isActive) {
                        bgColor = errorContainer;
                        textColor = onErrorContainer;
                      } else if (filter == 'Benigna' && isActive) {
                        bgColor = benignBg;
                        textColor = benignText;
                      } else if (isActive) {
                        bgColor = surfaceContainerHighest;
                        textColor = onSurface;
                      } else {
                        bgColor = surfaceContainerHighest;
                        textColor = onSurface;
                      }

                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(999),
                            border: filter == 'Maligna' && isActive
                                ? Border.all(color: error)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (filter == 'Fecha') ...[
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: textColor,
                                ),
                                const SizedBox(width: 4),
                              ],
                              if (filter == 'Todos') ...[
                                Icon(
                                  Icons.filter_list,
                                  size: 16,
                                  color: textColor,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: _filteredHistory.length,
              itemBuilder: (context, index) {
                final item = _filteredHistory[index];
                final prediction = item['prediction'] as String;
                final confidence = item['confidence'] as int;
                final date = item['date'] as String;
                final id = item['id'] as String;

                Color accentColor, badgeBg, badgeText, badgeIconColor;
                IconData badgeIcon;

                switch (prediction) {
                  case 'Maligna':
                    accentColor = error;
                    badgeBg = errorContainer;
                    badgeText = onErrorContainer;
                    badgeIconColor = onErrorContainer;
                    badgeIcon = Icons.warning;
                    break;
                  case 'OPMD':
                    accentColor = Colors.orange;
                    badgeBg = const Color(0xFFFFF3E0);
                    badgeText = const Color(0xFFE65100);
                    badgeIconColor = const Color(0xFFE65100);
                    badgeIcon = Icons.warning;
                    break;
                  default:
                    accentColor = const Color(0xFF4CAF50);
                    badgeBg = benignBg;
                    badgeText = benignText;
                    badgeIconColor = benignText;
                    badgeIcon = Icons.check_circle;
                }

                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: surfaceContainerHigh),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.image,
                                  color: onSurfaceVariant.withOpacity(0.5),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            date,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              color: outline,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                badgeIcon,
                                                size: 14,
                                                color: badgeIconColor,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                prediction,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                  color: badgeText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Paciente #$id',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Confianza: $confidence%',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
