import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';

void main() {
  test(
    'historical representative does not imply a reachable direct contact',
    () {
      const contact = CompanyContact(
        registryName: 'Ejemplo',
        registryRole: 'Gerente',
      );
      expect(contact.hasAny, isTrue);
      expect(contact.hasDirectContact, isFalse);
      expect(contact.emailUris, isEmpty);
    },
  );
  test(
    'multiple published emails open independent mailto drafts without sending',
    () {
      const contact = CompanyContact(
        email:
            'ventas+industrial@ejemplo.pe / info@ejemplo.pe; info@ejemplo.pe',
      );
      expect(contact.emailUris.map((uri) => uri.path), [
        'ventas+industrial@ejemplo.pe',
        'info@ejemplo.pe',
      ]);
      expect(
        contact.emailUris.every(
          (uri) => uri.scheme == 'mailto' && uri.query.isEmpty,
        ),
        isTrue,
      );
    },
  );
  test('web channel does not imply email and unsafe links cannot launch', () {
    const contact = CompanyContact(contactPage: 'https://example.org/contact');
    expect(contact.hasAny, isTrue);
    expect(contact.hasDirectContact, isFalse);
    expect(contact.contactPageUri?.host, 'example.org');
    expect(
      const CompanyContact(contactPage: 'javascript:alert(1)').contactPageUri,
      isNull,
    );
  });
}
