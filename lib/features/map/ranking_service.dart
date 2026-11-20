import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../companies/domain/company.dart';
import '../sites/domain/site.dart';
import '../sites/domain/runtime_spatial_projection.dart';

class RankedCompany {
  const RankedCompany(
    this._score, {
    required this.spatial,
    required this.distanceKm,
  });

  final RuntimeCompanySpatialView spatial;
  final double distanceKm;
  final double _score;

  Company get company => spatial.company;
}

class CompanyRankingService {
  const CompanyRankingService();

  List<RankedCompany> rank(
    List<RuntimeCompanySpatialView> companies,
    LatLng anchor, {
    String query = '',
  }) {
    const distance = Distance();

    final ranked = companies
        .where((item) => item.matchesQuery(query))
        .map((item) {
          final company = item.company;
          final distanceKm = distance.as(
            LengthUnit.Kilometer,
            anchor,
            item.point,
          );

          final proximity = item.canUseDistanceForRanking
              ? (1 / (1 + (distanceKm / 2))) * item.distanceEvidenceWeight
              : 0.0;

          final evidence = switch (item.locationQuality) {
            PlacementQuality.exactAddress => 1.0,
            PlacementQuality.addressReference => 0.92,
            PlacementQuality.interpolatedAddress => 0.58,
            PlacementQuality.propertyReference => 0.08,
            PlacementQuality.streetReference => 0.20,
            PlacementQuality.districtReference => 0.08,
          };

          final score = item.canUseDistanceForRanking
              ? (company.internalPotential * 0.58) +
                    (proximity * 0.32) +
                    (evidence * 0.10)
              : (company.internalPotential * 0.92) + (evidence * 0.08);

          return RankedCompany(
            score,
            spatial: item,
            distanceKm: distanceKm,
          );
        })
        .toList();

    ranked.sort((a, b) {
      if (a.spatial.canUseDistanceForRanking !=
          b.spatial.canUseDistanceForRanking) {
        return a.spatial.canUseDistanceForRanking ? -1 : 1;
      }

      final qualityComparison = b.spatial.distanceEvidenceWeight.compareTo(
        a.spatial.distanceEvidenceWeight,
      );

      if (qualityComparison != 0 &&
          (a.company.internalPotential - b.company.internalPotential).abs() <
              0.08) {
        return qualityComparison;
      }

      return b._score.compareTo(a._score);
    });

    return ranked;
  }

  List<RankedCompany> rankVisible(
    List<RuntimeCompanySpatialView> companies,
    LatLngBounds bounds, {
    String query = '',
  }) =>
      rank(
        companies.where((item) => bounds.contains(item.point)).toList(),
        bounds.center,
        query: query,
      );
}
