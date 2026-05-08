import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/presentation/viewmodels/history_viewmodel.dart';
import 'package:bucalscan_ai/presentation/widgets/app_app_bar.dart';
import 'package:bucalscan_ai/presentation/widgets/history_card.dart';

class HistoryTabView extends StatefulWidget {
  const HistoryTabView({super.key});

  @override
  State<HistoryTabView> createState() => _HistoryTabViewState();
}

class _HistoryTabViewState extends State<HistoryTabView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['Fecha', 'Todos', 'Maligna', 'Benigna'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.background,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    context.read<HistoryViewModel>().setSearchQuery(value);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                    hintText: 'Buscar ID de paciente, nombre o fecha...',
                    hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: Consumer<HistoryViewModel>(
                    builder: (context, viewModel, _) {
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filters.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = filters[index];
                          final isActive = filter == viewModel.filter;
                          Color bgColor, textColor;

                          if (filter == 'Maligna' && isActive) {
                            bgColor = AppColors.errorContainer;
                            textColor = AppColors.onErrorContainer;
                          } else if (filter == 'Benigna' && isActive) {
                            bgColor = AppColors.benignBg;
                            textColor = AppColors.benignText;
                          } else if (isActive) {
                            bgColor = AppColors.surfaceContainerHighest;
                            textColor = AppColors.onSurface;
                          } else {
                            bgColor = AppColors.surfaceContainerHighest;
                            textColor = AppColors.onSurface;
                          }

                          return GestureDetector(
                            onTap: () => viewModel.setFilter(filter),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(999),
                                border: filter == 'Maligna' && isActive
                                    ? Border.all(color: AppColors.error)
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (filter == 'Fecha') ...[
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                  ],
                                  if (filter == 'Todos') ...[
                                    const Icon(Icons.filter_list, size: 16, color: AppColors.onSurfaceVariant),
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<HistoryViewModel>(
              builder: (context, viewModel, _) {
                final history = viewModel.history;

                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AppColors.surfaceContainerHighest),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay análisis registrados',
                          style: TextStyle(fontSize: 18, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Los análisis realizados aparecerán aquí',
                          style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return HistoryCard(analysis: history[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
