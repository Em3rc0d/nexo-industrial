import 'package:latlong2/latlong.dart';

import '../companies/domain/company.dart';

class RankedCompany {
  const RankedCompany(
    this._score, {
    required this.company,
    required this.distanceKm,
  });

  final Company company;
  final double distanceKm;
  final double _score;
}

class CompanyRankingService {
  const CompanyRankingService();

  List<RankedCompany> rank(
    List<Company> companies,
    LatLng anchor, {
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    const distance = Distance();

    final ranked = companies
        .where((company) {
          if (normalizedQuery.isEmpty) return true;

          return company.name.toLowerCase().contains(normalizedQuery) ||
              company.ruc.toLowerCase().contains(normalizedQuery) ||
              company.sector.toLowerCase().contains(normalizedQuery) ||
              company.activity.toLowerCase().contains(normalizedQuery);
        })
        .map((company) {
          final distanceKm = distance.as(
            LengthUnit.Kilometer,
            anchor,
            company.point,
          );

          final proximity = company.canUseDistanceForRanking
              ? (1 / (1 + (distanceKm / 2))) * company.distanceEvidenceWeight
              : 0.0;

          final evidence = switch (company.locationQuality) {
            LocationQuality.exactAddress => 1.0,
            LocationQuality.addressReference => 0.92,
            LocationQuality.interpolatedAddress => 0.58,
            LocationQuality.streetReference => 0.20,
            LocationQuality.districtReference => 0.08,
          };

          final score = company.canUseDistanceForRanking
              ? (company.internalPotential * 0.58) +
                    (proximity * 0.32) +
                    (evidence * 0.10)
              : (company.internalPotential * 0.92) + (evidence * 0.08);

          return RankedCompany(score, company: company, distanceKm: distanceKm);
        })
        .toList();

    ranked.sort((a, b) {
      if (a.company.canUseDistanceForRanking !=
          b.company.canUseDistanceForRanking) {
        return a.company.canUseDistanceForRanking ? -1 : 1;
      }

      final qualityComparison = b.company.distanceEvidenceWeight.compareTo(
        a.company.distanceEvidenceWeight,
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

  double radiusForZoom(double zoom) {
    if (zoom >= 16) return 1.5;
    if (zoom >= 14) return 3.5;
    if (zoom >= 12) return 7;
    if (zoom >= 10) return 14;
    return 24;
  }
}
