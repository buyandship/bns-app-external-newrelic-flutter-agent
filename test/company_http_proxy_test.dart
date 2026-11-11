// SPDX-License-Identifier: Apache-2.0

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:newrelic_mobile/newrelic_http_client.dart';
import 'package:newrelic_mobile/newrelic_http_overrides.dart';

import 'newrelic_http_client_test.mocks.dart';

class _ProxyOverrides extends HttpOverrides {
  _ProxyOverrides({required this.client, required this.resolve});

  final HttpClient client;
  final String Function(Uri, Map<String, String>?) resolve;

  @override
  HttpClient createHttpClient(SecurityContext? context) => client;

  @override
  String findProxyFromEnvironment(
    Uri url,
    Map<String, String>? environment,
  ) =>
      resolve(url, environment);
}

String Function(Uri) proxyResolver(MockHttpClient client) {
  return verify(client.findProxy = captureAny).captured.single as String
      Function(Uri);
}

void main() {
  final uri = Uri.parse('https://example.com');

  test('client forwards proxy lookup to existing overrides with a writable map',
      () {
    final client = MockHttpClient();
    final originalEnvironment = Map<String, String>.from(Platform.environment);
    final overrides = NewRelicHttpOverrides(
      current: _ProxyOverrides(
        client: client,
        resolve: (url, environment) {
          expect(url, uri);
          environment!['https_proxy'] = 'localhost:8888';
          return 'PROXY localhost:8888';
        },
      ),
      findProxyFromEnvironmentFn: (_, __) => 'DIRECT',
    );

    final wrapped = overrides.createHttpClient(null) as NewRelicHttpClient;

    expect(wrapped.client, same(client));
    expect(proxyResolver(client)(uri), 'PROXY localhost:8888');
    expect(Platform.environment, originalEnvironment);
  });

  test('client uses a custom resolver when no existing override is supplied',
      () {
    final client = MockHttpClient();
    final overrides = NewRelicHttpOverrides(
      createHttpClientFn: (_) => client,
      findProxyFromEnvironmentFn: (url, environment) {
        environment!['https_proxy'] = 'localhost:9999';
        return 'PROXY localhost:9999';
      },
    );

    overrides.createHttpClient(null);

    expect(proxyResolver(client)(uri), 'PROXY localhost:9999');
  });

  test(
      'direct lookup forwards to existing overrides without mutating its input',
      () {
    final environment = Map<String, String>.unmodifiable({'region': 'tw'});
    final overrides = NewRelicHttpOverrides(
      current: _ProxyOverrides(
        client: MockHttpClient(),
        resolve: (_, environment) {
          expect(environment!['region'], 'tw');
          environment['https_proxy'] = 'localhost:8888';
          return 'PROXY localhost:8888';
        },
      ),
    );

    expect(overrides.findProxyFromEnvironment(uri, environment),
        'PROXY localhost:8888');
    expect(environment, {'region': 'tw'});
  });

  test(
      'direct lookup prefers an explicit resolver and copies null environments',
      () {
    final overrides = NewRelicHttpOverrides(
      current: _ProxyOverrides(
        client: MockHttpClient(),
        resolve: (_, __) => throw StateError('Unexpected fallback'),
      ),
      findProxyFromEnvironmentFn: (_, environment) {
        expect(environment, isEmpty);
        environment!['https_proxy'] = 'localhost:9999';
        return 'PROXY localhost:9999';
      },
    );

    expect(
        overrides.findProxyFromEnvironment(uri, null), 'PROXY localhost:9999');
  });

  test('custom client factory accepts a null security context', () {
    final client = MockHttpClient();
    final overrides = NewRelicHttpOverrides(
      createHttpClientFn: (context) {
        expect(context, isNull);
        return client;
      },
    );

    expect((overrides.createHttpClient(null) as NewRelicHttpClient).client,
        same(client));
  });

  test('default proxy lookup still falls back to the Dart implementation', () {
    expect(NewRelicHttpOverrides().findProxyFromEnvironment(uri, {}), 'DIRECT');
  });
}
