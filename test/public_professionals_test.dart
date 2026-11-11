import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/companies/data/asset_company_repository.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('professional links require a safe LinkedIn HTTPS host', () {
    const allowed = ProfessionalContact(
      name: 'Compras',
      role: 'Gerente',
      status: '2026_corporate_confirmed',
      reviewedOn: '2026-11-11',
      linkedinUrl: 'https://pe.linkedin.com/in/ejemplo',
    );
    expect(allowed.linkedinUri?.host, 'pe.linkedin.com');
    expect(allowed.isHistorical, isFalse);

    const unsafe = ProfessionalContact(
      name: 'Ejemplo',
      role: 'Histórico',
      status: 'historical_role_needs_reconfirmation',
      reviewedOn: '2026-11-11',
      linkedinUrl: 'https://linkedin.com.evil.test/in/ejemplo',
    );
    expect(unsafe.linkedinUri, isNull);
    expect(unsafe.isHistorical, isTrue);
    expect(unsafe.verificationLabel, contains('histórica'));
  });

  test('11 public professionals join 7 unique existing master RUCs', () async {
    final companies = await const AssetCompanyRepository().loadCompanies();
    expect(companies, hasLength(1907));
    final withPeople = companies.where((c) => c.people.isNotEmpty).toList();
    expect(withPeople, hasLength(7));
    expect(withPeople.expand((c) => c.people), hasLength(11));
    expect(withPeople.map((c) => c.ruc).toSet(), hasLength(7));
    expect(
      withPeople.every((c) => c.people.every((p) =>
          p.name.isNotEmpty && p.role.isNotEmpty && p.evidenceUri != null)),
      isTrue,
    );

    final volcan = companies.singleWhere((c) => c.ruc == '20383045267');
    expect(volcan.people, hasLength(2));
    expect(volcan.people.any((p) => p.name == 'Pieri Maguiña'), isTrue);
    final sotrami = companies.singleWhere((c) => c.ruc == '20258699239');
    expect(sotrami.people, hasLength(2));
    final minsur = companies.singleWhere((c) => c.ruc == '20100136741');
    expect(minsur.people.every((p) => p.isHistorical), isTrue);
  });

  test('professional identities never inflate direct phone/email coverage',
      () async {
    final companies = await const AssetCompanyRepository().loadCompanies();
    // Same commercial overlay as the previous release: people are separate.
    expect(companies.where((c) => c.contact.hasDirectContact), hasLength(270));
    expect(
      companies.where((c) => c.contact.phone?.isNotEmpty == true),
      hasLength(267),
    );
    expect(
      companies.where((c) => c.contact.emailUris.isNotEmpty),
      hasLength(157),
    );
  });
}
