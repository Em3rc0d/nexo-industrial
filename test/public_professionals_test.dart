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

  test('33 public professionals join 21 unique existing master RUCs', () async {
    final companies = await const AssetCompanyRepository().loadCompanies();
    expect(companies, hasLength(1907));
    final withPeople = companies.where((c) => c.people.isNotEmpty).toList();
    expect(withPeople, hasLength(21));
    expect(withPeople.expand((c) => c.people), hasLength(33));
    expect(withPeople.map((c) => c.ruc).toSet(), hasLength(21));
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
    final cmh = companies.singleWhere((c) => c.ruc == '20136150473');
    expect(cmh.people, hasLength(2));
    expect(
      cmh.people.any((p) => p.name == 'Wendy Vanessa Ramirez Souza'),
      isTrue,
    );
    final catalina = companies.singleWhere((c) => c.ruc == '20509551767');
    expect(catalina.people, hasLength(2));
    expect(
      catalina.people
          .singleWhere((p) => p.name == 'David Macedo')
          .isHistorical,
      isTrue,
    );
    final bambas = companies.singleWhere((c) => c.ruc == '20538428524');
    expect(bambas.people.single.name, 'Hector Janampa');
    final minsur = companies.singleWhere((c) => c.ruc == '20100136741');
    expect(minsur.people.every((p) => p.isHistorical), isTrue);
  });

  test('published supplier email is separate and parent roles are explicit',
      () async {
    final companies = await const AssetCompanyRepository().loadCompanies();
    final veta = companies.singleWhere((c) => c.ruc == '20536126440');
    final victor = veta.people.singleWhere((p) => p.name == 'Víctor Arias Manchego');
    expect(victor.isHistorical, isTrue);
    expect(victor.workEmailUri?.scheme, 'mailto');
    expect(victor.workEmailUri?.path, 'victor.arias@vetadorada.pe');

    final nexa = companies.singleWhere((c) => c.ruc == '20492744833');
    final miguel = nexa.people.singleWhere((p) => p.name == 'Miguel Aguirre');
    expect(miguel.associationLabel, contains('grupo empresarial'));
    expect(miguel.workEmailUri, isNull);

    const unsafe = ProfessionalContact(
      name: 'Test',
      role: 'Test',
      status: '2026_self_reported',
      reviewedOn: '2026-11-11',
      workEmail: 'bad@@example.org',
    );
    expect(unsafe.workEmailUri, isNull);
  });

  test('professional identities never inflate direct phone/email coverage',
      () async {
    final companies = await const AssetCompanyRepository().loadCompanies();
    // Phone/email counts include the RUC contact patch, not the people overlay.
    expect(companies.where((c) => c.contact.hasDirectContact), hasLength(299));
    expect(
      companies.where((c) => c.contact.phone?.isNotEmpty == true),
      hasLength(292),
    );
    expect(
      companies.where((c) => c.contact.emailUris.isNotEmpty),
      hasLength(176),
    );
  });
}
