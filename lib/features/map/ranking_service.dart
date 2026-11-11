import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

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
    const distance = Distance();

    final ranked = companies
        .where((company) => company.matchesQuery(query))
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

  /// Display every account in the viewport. Ranking orders; it never hides
  /// geographic coverage behind a radius or a top-N commercial cutoff.
  List<RankedCompany> rankVisible(
    List<Company> companies,
    LatLngBounds bounds, {
    String query = '',
  }) => rank(
    companies.where((company) => bounds.contains(company.point)).toList(),
    bounds.center,
    query: query,
  );
}
