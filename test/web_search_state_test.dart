import 'package:evergreen/web/widgets/web_search_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web page search matches text case-insensitively', () {
    expect(matchesWebSearch('  acme ', ['Northwind ACME', 'Branch A']), isTrue);
    expect(matchesWebSearch('missing', ['Northwind ACME', null]), isFalse);
    expect(matchesWebSearch('  ', ['any value']), isTrue);
  });

  test('web search matches a phrase in one field', () {
    expect(
      matchesWebSearch('north branch', ['North Branch A']),
      isTrue,
    );
    expect(
      matchesWebSearch('north branch', ['Northwind', 'Branch A']),
      isFalse,
    );
  });

  test('header search matches every word across different fields', () {
    expect(
      matchesWebSearchTerms('north branch', ['Northwind', 'Branch A']),
      isTrue,
    );
    expect(
      matchesWebSearchTerms('north missing', ['Northwind', 'Branch A']),
      isFalse,
    );
  });

  test('web page search query is shared through its provider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(webModuleSearchQueryProvider.notifier).state = 'ticket 42';

    expect(container.read(webModuleSearchQueryProvider), 'ticket 42');
  });
}
