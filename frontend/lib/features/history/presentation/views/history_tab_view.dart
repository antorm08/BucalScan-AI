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
import 'package:bucalscan_ai/features/priority/presentation/priority_copy.dart';
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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.94,
        child: Material(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _EvaluationDetailHeader(
                date: _date(analysis.evaluatedAt ?? analysis.timestamp),
                onClose: () => Navigator.pop(sheetContext),
              ),
              Expanded(
                child: ListView(
                  key: const Key('historyDetailSheet'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    if (analysis.imageUrl?.trim().isNotEmpty == true) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: HeatmapOverlayImage(
                            baseImage: NetworkImage(analysis.imageUrl!),
                            heatmapUrl: analysis.heatmapUrl,
                            errorFallback: const _HistoryImageFallback(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _DetailSection(
                      icon: Icons.person_outline,
                      title: 'Paciente y lesión',
                      children: [
                        _Detail(
                          label: 'Paciente',
                          value: _available(analysis.patientName),
                        ),
                        _Detail(
                          label: 'Código clínico',
                          value: _available(analysis.patientId),
                        ),
                        _Detail(
                          label: 'Sitio de la lesión',
                          value: _available(analysis.lesionSite),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailSection(
                      icon: Icons.fact_check_outlined,
                      title: 'Hallazgos clínicos',
                      children: [
                        _Detail(
                          label: 'Observaciones de esta evaluación',
                          value: _available(analysis.clinicalObservations),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ModelResultCard(analysis: analysis),
                    if (analysis.priority case final priority?) ...[
                      const SizedBox(height: 12),
                      _DetailSection(
                        icon: Icons.traffic_outlined,
                        title: 'Prioridad orientativa',
                        accent: true,
                        children: [
                          _Detail(
                            label: 'Semáforo orientativo de atención',
                            value: localizedPriorityStatus(
                              priority.priorityCode,
                            ).label,
                          ),
                          _Detail(
                            label: 'Motivos registrados',
                            value: localizedPriorityReasons(priority).isEmpty
                                ? 'No disponibles'
                                : localizedPriorityReasons(priority).join('\n'),
                          ),
                          _Detail(
                            label: 'Proveniencia de prioridad',
                            value:
                                'Reglas ${priority.rulesetVersion}; motor ${priority.engineVersion}; resultado histórico no recalculado.',
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _DetailSection(
                      icon: Icons.medical_information_outlined,
                      title: 'Profesional responsable',
                      children: [
                        _Detail(
                          label: 'Profesional',
                          value: _professional(analysis),
                        ),
                        _Detail(
                          label: 'Código profesional',
                          value: _available(
                            analysis.professionalDoctorId ??
                                analysis.createdByDoctorId,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _EvaluationDetailActions(
                canOpenPatient: analysis.patientRecordId != null,
                canOpenLesion:
                    analysis.patientRecordId != null &&
                    analysis.lesionId != null,
                onOpenPatient: () {
                  Navigator.pop(sheetContext);
                  _openPatient(analysis);
                },
                onOpenLesion: () {
                  Navigator.pop(sheetContext);
                  _openLesion(analysis);
                },
              ),
            ],
          ),
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

class _EvaluationDetailHeader extends StatelessWidget {
  final String date;
  final VoidCallback onClose;

  const _EvaluationDetailHeader({required this.date, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 10, 14),
    decoration: const BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalle de la evaluación',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar detalle',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool accent;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.children,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: accent ? AppColors.primaryFixed : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: accent ? AppColors.primaryFixedDim : AppColors.outlineVariant,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

class _ModelResultCard extends StatelessWidget {
  final Analysis analysis;

  const _ModelResultCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final status = localizedModelOutput(analysis.prediction);
    final confidence = analysis.confidence.clamp(0, 1).toDouble();
    return Container(
      key: const Key('historyModelResultSection'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resultado del modelo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(status.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Salida del modelo',
                      style: TextStyle(color: AppColors.primaryFixedDim),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _predictionLabel(analysis.prediction),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Confianza',
                    style: TextStyle(color: AppColors.primaryFixedDim),
                  ),
                  Text(
                    '${(confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: confidence,
            minHeight: 6,
            color: AppColors.primaryFixedDim,
            backgroundColor: Colors.white24,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _ModelMetadata(
                label: 'Versión del modelo',
                value: _available(analysis.modelVersion),
              ),
              if (analysis.processingTimeMs != null)
                _ModelMetadata(
                  label: 'Procesamiento',
                  value: '${analysis.processingTimeMs!.toStringAsFixed(0)} ms',
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'La confianza describe la salida del clasificador. No expresa diagnóstico ni probabilidad de cáncer.',
            style: TextStyle(
              color: AppColors.primaryFixed,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelMetadata extends StatelessWidget {
  final String label;
  final String value;

  const _ModelMetadata({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.primaryFixedDim, fontSize: 11),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _EvaluationDetailActions extends StatelessWidget {
  final bool canOpenPatient;
  final bool canOpenLesion;
  final VoidCallback onOpenPatient;
  final VoidCallback onOpenLesion;

  const _EvaluationDetailActions({
    required this.canOpenPatient,
    required this.canOpenLesion,
    required this.onOpenPatient,
    required this.onOpenLesion,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: const BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border(top: BorderSide(color: AppColors.outlineVariant)),
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('openHistoryPatient'),
              onPressed: canOpenPatient ? onOpenPatient : null,
              icon: const Icon(Icons.person_outline),
              label: const Text('Paciente'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              key: const Key('openHistoryLesion'),
              onPressed: canOpenLesion ? onOpenLesion : null,
              icon: const Icon(Icons.adjust),
              label: const Text('Abrir lesión'),
            ),
          ),
        ],
      ),
    ),
  );
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
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 15,
            height: 1.35,
          ),
        ),
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
