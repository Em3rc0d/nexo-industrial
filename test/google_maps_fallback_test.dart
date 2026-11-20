import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/sites/data/runtime_spatial_projection_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('non-navigable runtime view uses a Google Maps search URL', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();
    final item =
        snapshot.spatialViews.firstWhere((view) => !view.navigationEligible);

    final uri = item.googleMapsSearchUri;
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['query'], contains(item.company.name));
  });

  test('navigable runtime view uses authoritative Placement coordinates', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();
    final item =
        snapshot.spatialViews.firstWhere((view) => view.navigationEligible);

    final uri = item.googleMapsDirectionsUri;
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['api'], '1');
    expect(
      uri.queryParameters['destination'],
      '${item.placement.latitude},${item.placement.longitude}',
    );
  });
}
