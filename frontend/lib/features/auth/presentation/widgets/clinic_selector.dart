import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';

class ClinicSelector extends ConsumerStatefulWidget {
  final ClinicalWorkspace? selectedWorkspace;
  final ValueChanged<ClinicalWorkspace?> onSelected;

  const ClinicSelector({
    super.key,
    required this.selectedWorkspace,
    required this.onSelected,
  });

  @override
  ConsumerState<ClinicSelector> createState() => _ClinicSelectorState();
}

class _ClinicSelectorState extends ConsumerState<ClinicSelector> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  List<ClinicalWorkspace> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (widget.selectedWorkspace != null) {
      widget.onSelected(null);
    }
    _debounce?.cancel();
    final normalized = query.trim();
    if (normalized.length < 2) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.length < 2) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(clinicalRepositoryProvider)
          .discoverWorkspaces(query);
      if (!mounted || query != _queryController.text.trim()) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _error = 'No se pudo consultar el directorio de clinicas.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(ClinicalWorkspace workspace) {
    if (workspace.status != 'active') return;
    widget.onSelected(workspace);
    setState(() => _results = const []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('clinic-search-field'),
          controller: _queryController,
          onChanged: _onQueryChanged,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            labelText: 'Buscar clinica registrada',
            hintText: 'Nombre de clinica o consultorio',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Buscar',
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.arrow_forward),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        if (widget.selectedWorkspace case final workspace?)
          Card(
            key: const Key('selected-clinic'),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(workspace.name),
              subtitle: const Text('Clinica activa seleccionada'),
              trailing: IconButton(
                tooltip: 'Quitar seleccion',
                onPressed: () => widget.onSelected(null),
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ..._results.map((workspace) {
          final active = workspace.status == 'active';
          return Card(
            key: Key('clinic-${workspace.id}'),
            child: ListTile(
              enabled: active,
              leading: Icon(
                active ? Icons.local_hospital_outlined : Icons.schedule,
              ),
              title: Text(workspace.name),
              subtitle: Text(
                active
                    ? 'Activa · Disponible para solicitar acceso'
                    : 'Pendiente de aprobacion · No disponible',
              ),
              trailing: active
                  ? const Icon(Icons.chevron_right)
                  : const Chip(label: Text('Pendiente')),
              onTap: active ? () => _select(workspace) : null,
            ),
          );
        }),
        if (!_loading &&
            _error == null &&
            _queryController.text.trim().length >= 2 &&
            _results.isEmpty &&
            widget.selectedWorkspace == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No se encontraron clinicas con esa busqueda.'),
          ),
      ],
    );
  }
}
