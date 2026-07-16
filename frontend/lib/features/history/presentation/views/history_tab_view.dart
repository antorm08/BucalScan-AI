import 'dart:async';

import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/lesion_detail_view.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/patient_detail_view.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/features/history/domain/entities/history_query.dart';
import 'package:bucalscan_ai/features/history/presentation/viewmodels/history_viewmodel.dart';
import 'package:bucalscan_ai/features/history/presentation/widgets/history_card.dart';
import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/widgets/heatmap_overlay_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryTabView extends ConsumerStatefulWidget {
  final void Function(Patient, OralLesion)? onRepeatAnalysis;

  const HistoryTabView({super.key, this.onRepeatAnalysis});

  @override
  ConsumerState<HistoryTabView> createState() => _HistoryTabViewState();
}

class _HistoryTabViewState extends ConsumerState<HistoryTabView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(historyViewModelProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final state = ref.read(historyViewModelProvider);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: state.criteria.dateFrom == null
          ? null
          : DateTimeRange(
              start: state.criteria.dateFrom!.toLocal(),
              end: (state.criteria.dateTo ?? state.criteria.dateFrom!)
                  .toLocal(),
            ),
      helpText: 'Rango de evaluaciones',
    );
    if (range != null) {
      await ref
          .read(historyViewModelProvider.notifier)
          .setDateRange(range.start, range.end);
    }
  }

  Future<void> _openPatient(Analysis analysis) async {
    final patientId = analysis.patientRecordId;
    if (patientId == null) return _showUnavailable();
    try {
      final patient = await ref.read(getPatientUseCaseProvider)('$patientId');
      if (!mounted || patient.id != '$patientId') return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PatientDetailView(
            patientId: patient.id,
            onRepeatAnalysis: widget.onRepeatAnalysis ?? (_, _) {},
          ),
        ),
      );
    } catch (_) {
      if (mounted) _showUnavailable();
    }
  }

  Future<void> _openLesion(Analysis analysis) async {
    final patientId = analysis.patientRecordId;
    final lesionId = analysis.lesionId;
    if (patientId == null || lesionId == null) return _showUnavailable();
    try {
      final results = await Future.wait([
        ref.read(getPatientUseCaseProvider)('$patientId'),
        ref.read(getLesionDetailUseCaseProvider)('$lesionId'),
      ]);
      final patient = results[0] as Patient;
      final detail = results[1] as LesionDetail;
      if (patient.id != '$patientId' ||
          detail.lesion.id != '$lesionId' ||
          detail.lesion.patientId != patient.id) {
        return _showUnavailable();
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LesionDetailView(
            patient: patient,
            lesionId: detail.lesion.id,
            onRepeatAnalysis: widget.onRepeatAnalysis ?? (_, _) {},
          ),
        ),
      );
    } catch (_) {
      if (mounted) _showUnavailable();
    }
  }

  void _showUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: Key('historyUnavailableMessage'),
        content: Text(
          'El registro no está disponible o ya no tienes acceso en el centro activo.',
        ),
      ),
    );
  }

  void _showDetail(Analysis analysis) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (_, controller) => ListView(
          key: const Key('historyDetailSheet'),
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Detalle de la evaluación',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (analysis.imageUrl?.trim().isNotEmpty == true) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: HeatmapOverlayImage(
                    baseImage: NetworkImage(analysis.imageUrl!),
                    heatmapUrl: analysis.heatmapUrl,
                    errorFallback: const _HistoryImageFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            _Detail(
              label: 'Fecha de evaluación',
              value: _date(analysis.evaluatedAt ?? analysis.timestamp),
            ),
            _Detail(label: 'Paciente', value: _available(analysis.patientName)),
            _Detail(
              label: 'Código clínico',
              value: _available(analysis.patientId),
            ),
            _Detail(
              label: 'Sitio de la lesión',
              value: _available(analysis.lesionSite),
            ),
            _Detail(
              label: 'Hallazgos de esta evaluación',
              value: _available(analysis.clinicalObservations),
            ),
            _Detail(label: 'Profesional', value: _professional(analysis)),
            _Detail(
              label: 'Código profesional',
              value: _available(
                analysis.professionalDoctorId ?? analysis.createdByDoctorId,
              ),
            ),
            _Detail(
              label: 'Salida del modelo',
              value: _predictionLabel(analysis.prediction),
            ),
            _Detail(
              label: 'Confianza del clasificador',
              value:
                  '${(analysis.confidence.clamp(0, 1) * 100).toStringAsFixed(1)}%. No expresa diagnóstico ni probabilidad de cáncer.',
            ),
            _Detail(
              label: 'Versión del modelo',
              value: _available(analysis.modelVersion),
            ),
            if (analysis.priority case final priority?) ...[
              const Divider(height: 28),
              _Detail(
                label: 'Prioridad clínica orientativa',
                value: localizedPriorityStatus(priority.priorityCode).label,
              ),
              _Detail(
                label: 'Motivos registrados',
                value: priority.reasons.isEmpty
                    ? 'No disponibles'
                    : priority.reasons.join('\n'),
              ),
              _Detail(
                label: 'Proveniencia de prioridad',
                value:
                    'Reglas ${priority.rulesetVersion}; motor ${priority.engineVersion}; resultado histórico no recalculado.',
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('openHistoryPatient'),
                  onPressed: analysis.patientRecordId == null
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          _openPatient(analysis);
                        },
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Abrir paciente'),
                ),
                OutlinedButton.icon(
                  key: const Key('openHistoryLesion'),
                  onPressed:
                      analysis.patientRecordId == null ||
                          analysis.lesionId == null
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          _openLesion(analysis);
                        },
                  icon: const Icon(Icons.adjust),
                  label: const Text('Abrir lesión'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyViewModelProvider);
    final notifier = ref.read(historyViewModelProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Material(
            color: AppColors.background,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('historySearch'),
                    controller: _searchController,
                    onChanged: notifier.setSearchQuery,
                    decoration: InputDecoration(
                      labelText: 'Buscar historial',
                      hintText: 'Paciente, código, lesión o profesional',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              onPressed: () {
                                _searchController.clear();
                                notifier.setSearchQuery('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (state.priorityFilterEnabled)
                          PopupMenuButton<String?>(
                            key: const Key('historyPriorityFilter'),
                            tooltip: 'Filtrar prioridad clínica',
                            onSelected: notifier.setPriorityCode,
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: null,
                                child: Text('Cualquier prioridad'),
                              ),
                              PopupMenuItem(
                                value: 'incomplete',
                                child: Text('Incompleta'),
                              ),
                              PopupMenuItem(
                                value: 'standard',
                                child: Text('Estándar'),
                              ),
                              PopupMenuItem(
                                value: 'prompt',
                                child: Text('Pronta'),
                              ),
                              PopupMenuItem(
                                value: 'urgent',
                                child: Text('Urgente'),
                              ),
                              PopupMenuItem(
                                value: 'emergency',
                                child: Text('Emergencia'),
                              ),
                            ],
                            child: Chip(
                              avatar: const Icon(Icons.flag_outlined, size: 18),
                              label: Text(
                                state.criteria.priorityCode == null
                                    ? 'Prioridad'
                                    : localizedPriorityStatus(
                                        state.criteria.priorityCode!,
                                      ).label,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        ActionChip(
                          key: const Key('historyDateFilter'),
                          avatar: const Icon(
                            Icons.date_range_outlined,
                            size: 18,
                          ),
                          label: Text(
                            state.criteria.dateFrom == null
                                ? 'Fechas'
                                : _dateSummary(state.criteria),
                          ),
                          onPressed: _pickDates,
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<(HistorySort, SortDirection)>(
                          key: const Key('historySort'),
                          tooltip: 'Ordenar historial',
                          onSelected: (value) =>
                              notifier.setSort(value.$1, value.$2),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: (
                                HistorySort.evaluatedAt,
                                SortDirection.descending,
                              ),
                              child: Text('Más recientes primero'),
                            ),
                            PopupMenuItem(
                              value: (
                                HistorySort.evaluatedAt,
                                SortDirection.ascending,
                              ),
                              child: Text('Más antiguos primero'),
                            ),
                            PopupMenuItem(
                              value: (
                                HistorySort.patientName,
                                SortDirection.ascending,
                              ),
                              child: Text('Paciente A-Z'),
                            ),
                            PopupMenuItem(
                              value: (
                                HistorySort.confidence,
                                SortDirection.descending,
                              ),
                              child: Text('Mayor confianza primero'),
                            ),
                            PopupMenuItem(
                              value: (
                                HistorySort.lesionSite,
                                SortDirection.ascending,
                              ),
                              child: Text('Sitio de lesión A-Z'),
                            ),
                          ],
                          child: const Chip(
                            avatar: Icon(Icons.sort, size: 18),
                            label: Text('Ordenar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.criteria.hasFilters) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _filterSummary(state.criteria),
                            key: const Key('historyFilterSummary'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          key: const Key('clearHistoryFilters'),
                          onPressed: () {
                            _searchController.clear();
                            notifier.clearFilters();
                          },
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ),
                  ],
                  if (state.total > 0)
                    Text(
                      '${state.total} evaluaciones en el centro activo',
                      key: const Key('historyTotal'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: _body(state, notifier)),
        ],
      ),
    );
  }

  Widget _body(HistoryState state, HistoryViewModel notifier) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('historyLoading')),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudo cargar el historial',
        detail: state.error!,
        action: TextButton.icon(
          key: const Key('retryHistory'),
          onPressed: notifier.refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }
    if (state.items.isEmpty) {
      return _Message(
        icon: state.criteria.hasFilters ? Icons.search_off : Icons.history,
        title: state.criteria.hasFilters
            ? 'No hay coincidencias'
            : 'No hay evaluaciones registradas',
        detail: state.criteria.hasFilters
            ? 'Cambie o limpie los filtros para ampliar la búsqueda.'
            : 'Las evaluaciones guardadas aparecerán aquí.',
        action: state.criteria.hasFilters
            ? TextButton(
                onPressed: notifier.clearFilters,
                child: const Text('Limpiar filtros'),
              )
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 620
              ? 2
              : 1;
          return CustomScrollView(
            key: const Key('historyResults'),
            slivers: [
              if (state.isRefreshing)
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 178,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (_, index) => HistoryCard(
                    analysis: state.items[index],
                    onTap: () => _showDetail(state.items[index]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: state.hasNext
                      ? OutlinedButton.icon(
                          key: const Key('loadMoreHistory'),
                          onPressed: state.isAppending
                              ? null
                              : notifier.loadMore,
                          icon: state.isAppending
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(
                            state.isAppending ? 'Cargando...' : 'Cargar más',
                          ),
                        )
                      : const Center(child: Text('Fin de los resultados')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryImageFallback extends StatelessWidget {
  const _HistoryImageFallback();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceContainerHigh,
    alignment: Alignment.center,
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, color: AppColors.onSurfaceVariant),
        SizedBox(height: 6),
        Text('Imagen no disponible'),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 3),
        SelectableText(value),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}

String _available(String? value) =>
    value?.trim().isNotEmpty == true ? value!.trim() : 'No disponible';

String _predictionLabel(String value) {
  final status = localizedModelOutput(value);
  return status.tone == StatusTone.neutral
      ? 'Salida no disponible'
      : 'Compatible con ${status.label.toLowerCase()}';
}

String _professional(Analysis analysis) {
  final name = analysis.professionalName ?? analysis.createdByName;
  final context = [
    analysis.professionalProfession,
    analysis.professionalSpecialty,
  ].where((value) => value?.trim().isNotEmpty == true).join(' · ');
  return context.isEmpty ? _available(name) : '${_available(name)}\n$context';
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _dateSummary(HistoryCriteria criteria) =>
    '${_date(criteria.dateFrom!).split(' ').first} - ${_date(criteria.dateTo ?? criteria.dateFrom!).split(' ').first}';

String _filterSummary(HistoryCriteria criteria) {
  final values = <String>[
    if (criteria.search.isNotEmpty) 'Búsqueda: “${criteria.search}”',
    if (criteria.modelLabel != null)
      'Modelo: ${_predictionLabel(criteria.modelLabel!)}',
    if (criteria.priorityCode != null)
      'Prioridad: ${localizedPriorityStatus(criteria.priorityCode!).label}',
    if (criteria.dateFrom != null) 'Fechas: ${_dateSummary(criteria)}',
  ];
  return values.join(' · ');
}
