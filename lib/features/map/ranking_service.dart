import 'package:latlong2/latlong.dart';

import '../companies/domain/company.dart';

class RankedCompany {
  const RankedCompany({
    required this.company,
    required this.distanceKm,
    required double score,
  }) : _score = score;

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

          final proximity = company.nearbyRankingEligible
              ? 1 / (1 + (distanceKm / 2))
              : 0.0;
          final evidence = switch (company.locationConfidence) {
            LocationConfidence.confirmed => 1.0,
            LocationConfidence.fiscalOnly => 0.72,
            LocationConfidence.districtReference => 0.15,
            LocationConfidence.uncertain => 0.05,
          };

          final score = company.nearbyRankingEligible
              ? (company.internalPotential * 0.55) +
                  (proximity * 0.35) +
                  (evidence * 0.10)
              : (company.internalPotential * 0.90) + (evidence * 0.10);

          return RankedCompany(
            company: company,
            distanceKm: distanceKm,
            score: score,
          );
        })
        .toList();

    ranked.sort((a, b) => b._score.compareTo(a._score));
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
