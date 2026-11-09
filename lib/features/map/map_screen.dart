import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../services/location_service.dart';
import '../activity/activity_store.dart';
import '../companies/company_detail_screen.dart';
import '../companies/domain/company.dart';
import '../companies/nearby_companies_screen.dart';
import 'ranking_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.companies,
    required this.activityStore,
  });

  final List<Company> companies;
  final ActivityStore activityStore;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _fallback = LatLng(-12.0972, -77.0365);

  final MapController _mapController = MapController();
  final CompanyRankingService _ranking = const CompanyRankingService();
  final LocationService _locationService = const LocationService();

  StreamSubscription<Position>? _positionSubscription;
  LatLng _anchor = _fallback;
  LatLng? _userLocation;
  double _zoom = 13.4;
  bool _followUser = true;
  bool _exploring = false;
  bool _locationUnavailable = false;
  String _query = '';
  Company? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLocation());
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocation() async {
    final current = await _locationService.currentPosition();

    if (!mounted) return;

    if (current == null) {
      setState(() => _locationUnavailable = true);
      return;
    }

    final point = LatLng(current.latitude, current.longitude);

    setState(() {
      _userLocation = point;
      _anchor = point;
      _locationUnavailable = false;
    });

    _mapController.move(point, _zoom);

    final stream = await _locationService.watchPosition();
    if (stream == null || !mounted) return;

    _positionSubscription = stream.listen((position) {
      if (!mounted) return;

      final point = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = point;

        if (_followUser) {
          _anchor = point;
          _selected = null;
        }
      });

      if (_followUser) {
        _mapController.move(point, _zoom);
      }
    });
  }

  List<RankedCompany> _ranked() =>
      _ranking.rank(widget.companies, _anchor, query: _query);

  List<RankedCompany> _candidates() {
    final radius = _ranking.radiusForZoom(_zoom);

    return _ranked()
        .where((item) => item.distanceKm <= radius)
        .take(90)
        .toList(growable: false);
  }

  void _searchCurrentMapCenter() {
    setState(() {
      _anchor = _mapController.camera.center;
      _exploring = false;
      _followUser = false;
      _selected = null;
    });
  }

  void _returnToUser() {
    final userLocation = _userLocation;

    if (userLocation == null) {
      _startLocation();
      return;
    }

    setState(() {
      _anchor = userLocation;
      _followUser = true;
      _exploring = false;
      _selected = null;
      _zoom = 14;
    });

    _mapController.move(userLocation, _zoom);
  }

  void _openCompany(Company company) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanyDetailScreen(
          company: company,
          activityStore: widget.activityStore,
        ),
      ),
    );
  }

  void _openNearbyList(List<RankedCompany> ranked) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NearbyCompaniesScreen(
          companies: ranked,
          activityStore: widget.activityStore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates();
    final featured = candidates
        .where((item) => item.company.nearbyRankingEligible)
        .take(3)
        .toList(growable: false);
    final featuredIds = featured.map((item) => item.company.id).toSet();
    final regular = candidates
        .where((item) => !featuredIds.contains(item.company.id))
        .toList(growable: false);

    final regularMarkers = regular
        .map(
          (item) => Marker(
            key: ValueKey(item.company.id),
            point: item.company.point,
            width: 34,
            height: 34,
            child: GestureDetector(
              onTap: () => setState(() => _selected = item.company),
              child: Container(
                decoration: BoxDecoration(
                  color: NexoColors.mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 8),
                  ],
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ),
        )
        .toList(growable: false);

    final featuredMarkers = featured
        .map(
          (item) => Marker(
            key: ValueKey('featured-${item.company.id}'),
            point: item.company.point,
            width: 48,
            height: 54,
            child: GestureDetector(
              onTap: () => setState(() => _selected = item.company),
              child: const Icon(
                Icons.location_on,
                color: NexoColors.orange,
                size: 48,
                shadows: [Shadow(color: Color(0x44000000), blurRadius: 6)],
              ),
            ),
          ),
        )
        .toList(growable: false);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _fallback,
            initialZoom: _zoom,
            minZoom: 5,
            maxZoom: 19,
            onPositionChanged: (camera, hasGesture) {
              _zoom = camera.zoom;

              if (hasGesture && !_exploring) {
                setState(() {
                  _exploring = true;
                  _followUser = false;
                  _selected = null;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pe.nexoindustrial.app',
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 54,
                size: const Size(46, 46),
                markers: regularMarkers,
                builder: (context, markers) {
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: NexoColors.mint,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Color(0x25000000), blurRadius: 10),
                      ],
                    ),
                    child: Text(
                      '${markers.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ),
            MarkerLayer(markers: featuredMarkers),
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: NexoColors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        _MapHeader(
          locationUnavailable: _locationUnavailable,
          onQueryChanged: (value) => setState(() {
            _query = value;
            _selected = null;
          }),
          onListTap: () => _openNearbyList(_candidates()),
        ),
        if (_exploring)
          Positioned(
            top: 162,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.icon(
                onPressed: _searchCurrentMapCenter,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Buscar en esta zona'),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 180,
          child: FloatingActionButton.small(
            heroTag: 'my-location',
            onPressed: _returnToUser,
            backgroundColor: Colors.white,
            foregroundColor: NexoColors.navy,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
        _OpportunitySheet(
          candidates: candidates.take(6).toList(growable: false),
          selected: _selected,
          onCloseSelected: () => setState(() => _selected = null),
          onOpenCompany: _openCompany,
          onOpenList: () => _openNearbyList(_candidates()),
        ),
      ],
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.locationUnavailable,
    required this.onQueryChanged,
    required this.onListTap,
  });

  final bool locationUnavailable;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onListTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [NexoColors.navy, NexoColors.teal],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const _NexoMark(),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Nexo Industrial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onListTap,
                    tooltip: 'Ver empresas cercanas',
                    icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Buscar empresa o RUC',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(child: _PriorityChip()),
                  if (locationUnavailable) ...[
                    const SizedBox(width: 8),
                    const Tooltip(
                      message:
                          'Sin ubicación disponible; se usa una zona de referencia.',
                      child: Icon(
                        Icons.location_off_outlined,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 17),
          SizedBox(width: 7),
          Flexible(
            child: Text(
              'Priorizar: mayor potencial comercial',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NexoMark extends StatelessWidget {
  const _NexoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: NexoColors.mint,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'N',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _OpportunitySheet extends StatelessWidget {
  const _OpportunitySheet({
    required this.candidates,
    required this.selected,
    required this.onCloseSelected,
    required this.onOpenCompany,
    required this.onOpenList,
  });

  final List<RankedCompany> candidates;
  final Company? selected;
  final VoidCallback onCloseSelected;
  final ValueChanged<Company> onOpenCompany;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: selected == null ? 0.17 : 0.26,
      initialChildSize: selected == null ? 0.29 : 0.36,
      maxChildSize: selected == null ? 0.58 : 0.48,
      snap: true,
      builder: (context, controller) {
        return Material(
          color: Colors.white,
          elevation: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: selected != null
              ? _SelectedCompanyPreview(
                  company: selected!,
                  controller: controller,
                  onClose: onCloseSelected,
                  onOpen: () => onOpenCompany(selected!),
                )
              : _NearbyOpportunities(
                  candidates: candidates,
                  controller: controller,
                  onOpenCompany: onOpenCompany,
                  onOpenList: onOpenList,
                ),
        );
      },
    );
  }
}

class _SelectedCompanyPreview extends StatelessWidget {
  const _SelectedCompanyPreview({
    required this.company,
    required this.controller,
    required this.onClose,
    required this.onOpen,
  });

  final Company company;
  final ScrollController controller;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      children: [
        const _SheetHandle(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                company.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        Text(
          company.locationLabel,
          style: const TextStyle(color: NexoColors.muted),
        ),
        const SizedBox(height: 16),
        const Text(
          'POR QUÉ INTERESA',
          style: TextStyle(
            color: NexoColors.orange,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(company.opportunityReason),
        const Divider(height: 28),
        const Text(
          'SIGUIENTE PASO',
          style: TextStyle(
            color: NexoColors.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(company.suggestedNextStep),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onOpen,
          child: const Text('Ver ficha comercial'),
        ),
      ],
    );
  }
}

class _NearbyOpportunities extends StatelessWidget {
  const _NearbyOpportunities({
    required this.candidates,
    required this.controller,
    required this.onOpenCompany,
    required this.onOpenList,
  });

  final List<RankedCompany> candidates;
  final ScrollController controller;
  final ValueChanged<Company> onOpenCompany;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        const _SheetHandle(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                candidates.any((item) => item.company.nearbyRankingEligible)
                    ? 'Oportunidades cerca de ti'
                    : 'Oportunidades en esta zona',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(onPressed: onOpenList, child: const Text('Ver lista')),
          ],
        ),
        if (candidates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No hay cuentas confiables en esta zona con los filtros actuales.',
              style: TextStyle(color: NexoColors.muted),
            ),
          )
        else
          ...candidates.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NexoColors.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.factory_outlined,
                  color: NexoColors.teal,
                ),
              ),
              title: Text(
                item.company.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                item.company.nearbyRankingEligible
                    ? '${item.distanceKm.toStringAsFixed(1)} km · '
                          '${item.company.activity}'
                    : '${item.company.activity} · referencia distrital',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onOpenCompany(item.company),
            ),
          ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: NexoColors.border,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
