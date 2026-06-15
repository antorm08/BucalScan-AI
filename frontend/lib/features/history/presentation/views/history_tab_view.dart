import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/widgets/app_app_bar.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/presentation/widgets/history_card.dart';
import 'package:bucalscan_ai/features/history/presentation/viewmodels/history_viewmodel.dart';

class HistoryTabView extends StatefulWidget {
  const HistoryTabView({super.key});

  @override
  State<HistoryTabView> createState() => _HistoryTabViewState();
}

class _HistoryTabViewState extends State<HistoryTabView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<HistoryViewModel>().fetchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAnalysisDetail(Analysis analysis) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final prediction = analysis.prediction.toLowerCase();
        final isMalignant = prediction == 'malignant';
        final badgeColor = isMalignant ? AppColors.error : AppColors.benignText;
        final badgeBackground = isMalignant
            ? AppColors.errorContainer
            : AppColors.benignBg;
        final displayLabel = isMalignant ? 'Maligno' : 'Benigno';
        final accentColor = isMalignant
            ? AppColors.error
            : AppColors.benignText;
        final confidence = analysis.confidence.clamp(0.0, 1.0);
        final hasImage =
            analysis.imageUrl != null && analysis.imageUrl!.trim().isNotEmpty;

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.92,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detalle del análisis',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDetailDate(analysis.timestamp),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            displayLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: hasImage
                            ? AppColors.surfaceContainerLow
                            : accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: hasImage
                              ? AppColors.outlineVariant
                              : accentColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (hasImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  analysis.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _HistoryImageFallback(
                                      accentColor: accentColor,
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            _HistoryImageFallback(accentColor: accentColor),
                          const SizedBox(height: 12),
                          Text(
                            hasImage
                                ? 'Imagen registrada'
                                : 'Vista previa no disponible',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasImage
                                ? 'La captura asociada se recupero correctamente desde el historial.'
                                : 'Este analisis no tiene una imagen publica disponible para mostrar en la app.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Confianza del modelo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final useStackedLayout = constraints.maxWidth < 320;
                              final percentage = Text(
                                '${(confidence * 100).toStringAsFixed(1)}%',
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                  letterSpacing: -1,
                                ),
                              );
                              final description = Text(
                                isMalignant
                                    ? 'Resultado con indicios de riesgo alto segun la clasificacion actual.'
                                    : 'Resultado con indicios compatibles con una lesion benigna.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              );

                              if (useStackedLayout) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    percentage,
                                    const SizedBox(height: 8),
                                    description,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(width: 120, child: percentage),
                                  const SizedBox(width: 14),
                                  Expanded(child: description),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: confidence,
                              minHeight: 10,
                              backgroundColor:
                                  AppColors.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(
                      label: 'Paciente',
                      value: analysis.patientName ?? 'No registrado',
                    ),
                    _DetailRow(
                      label: 'ID paciente',
                      value: analysis.patientId ?? 'No registrado',
                    ),
                    _DetailRow(label: 'Predicción', value: displayLabel),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Cerrar'),
                      ),
                    ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDetailDate(DateTime date) {
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['Todos', 'Fecha', 'Maligna', 'Benigna'];

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
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.outline,
                    ),
                    hintText:
                        'Buscar por paciente, fecha, ID o clasificación...',
                    hintStyle: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: AppColors.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: AppColors.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: AppColors.primaryContainer,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = filters[index];
                          final isActive = filter == viewModel.filter;
                          Color bgColor, textColor;
                          Border? border;
                          List<BoxShadow>? boxShadow;
                          IconData? trailingIcon;

                          if (filter == 'Maligna' && isActive) {
                            bgColor = AppColors.errorContainer;
                            textColor = AppColors.onErrorContainer;
                            border = Border.all(color: AppColors.error);
                          } else if (filter == 'Benigna' && isActive) {
                            bgColor = AppColors.benignBg;
                            textColor = AppColors.benignText;
                            border = Border.all(color: AppColors.benignText);
                          } else if (isActive) {
                            bgColor = AppColors.surfaceContainerLowest;
                            textColor = AppColors.primary;
                            border = Border.all(
                              color: AppColors.primary,
                              width: 1.4,
                            );
                            boxShadow = [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ];
                          } else {
                            bgColor = AppColors.surfaceContainerHighest;
                            textColor = AppColors.onSurface;
                          }

                          if (filter == 'Fecha' && isActive) {
                            trailingIcon = viewModel.dateSortDescending
                                ? Icons.south_rounded
                                : Icons.north_rounded;
                          }

                          return GestureDetector(
                            onTap: () => viewModel.setFilter(filter),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(999),
                                border: border,
                                boxShadow: boxShadow,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (filter == 'Fecha') ...[
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: isActive
                                          ? textColor
                                          : AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  if (filter == 'Todos') ...[
                                    Icon(
                                      Icons.filter_list,
                                      size: 16,
                                      color: isActive
                                          ? textColor
                                          : AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    filter == 'Fecha'
                                        ? 'Ordenar fecha'
                                        : filter,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: textColor,
                                    ),
                                  ),
                                  if (trailingIcon != null) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      trailingIcon,
                                      size: 16,
                                      color: textColor,
                                    ),
                                  ],
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 720;

                return Consumer<HistoryViewModel>(
                  builder: (context, viewModel, _) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (viewModel.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No se pudo cargar el historial',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              viewModel.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<HistoryViewModel>().fetchHistory();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }

                    final history = viewModel.history;

                    if (history.isEmpty) {
                      final hasNoMatches =
                          viewModel.hasAnyHistory &&
                          viewModel.hasActiveSearchOrFilter;

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasNoMatches ? Icons.search_off : Icons.history,
                              size: 64,
                              color: AppColors.surfaceContainerHighest,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              hasNoMatches
                                  ? 'No se encontraron resultados'
                                  : 'No hay análisis registrados',
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hasNoMatches
                                  ? 'Pruebe con otra búsqueda o cambie los filtros activos.'
                                  : 'Los análisis realizados aparecerán aquí',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (isCompact) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return HistoryCard(
                            analysis: history[index],
                            onTap: () => _showAnalysisDetail(history[index]),
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.9,
                          ),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        return HistoryCard(
                          analysis: history[index],
                          onTap: () => _showAnalysisDetail(history[index]),
                        );
                      },
                    );
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _HistoryImageFallback extends StatelessWidget {
  final Color accentColor;

  const _HistoryImageFallback({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: accentColor,
            size: 30,
          ),
          const SizedBox(height: 8),
          const Text(
            'Imagen no disponible',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
