import 'package:evergreen/web/widgets/web_search_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web page search matches text case-insensitively', () {
    expect(matchesWebSearch('  acme ', ['Northwind ACME', 'Branch A']), isTrue);
    expect(matchesWebSearch('missing', ['Northwind ACME', null]), isFalse);
    expect(matchesWebSearch('  ', ['any value']), isTrue);
  });

  test('web page search query is shared through its provider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(webModuleSearchQueryProvider.notifier).state = 'ticket 42';

    expect(container.read(webModuleSearchQueryProvider), 'ticket 42');
  });
}
