/*
 * Copyright (c) 2022-present New Relic Corporation. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';

import 'package:newrelic_mobile/newrelic_http_client.dart';

class NewRelicHttpOverrides extends HttpOverrides {
  final String Function(Uri? url, Map<String, String>? environment)?
      findProxyFromEnvironmentFn;
  final HttpClient Function(SecurityContext? context)? createHttpClientFn;
  final HttpOverrides? current;

  NewRelicHttpOverrides({
    this.current,
    this.findProxyFromEnvironmentFn,
    this.createHttpClientFn,
  });

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = NewRelicHttpClient(
        client: createHttpClientFn != null
            ? createHttpClientFn!(context)
            : current?.createHttpClient(context) ??
                super.createHttpClient(context));

    // Preserve the existing proxy override when wrapping its HTTP client.
    client.findProxy = (uri) {
      final environment = Map<String, String>.from(Platform.environment);

      return current?.findProxyFromEnvironment(uri, environment) ??
          findProxyFromEnvironmentFn?.call(uri, environment) ??
          super.findProxyFromEnvironment(uri, environment);
    };

    return client;
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    final modifiableEnvironment = Map<String, String>.from(environment ?? {});

    return findProxyFromEnvironmentFn?.call(url, modifiableEnvironment) ??
        current?.findProxyFromEnvironment(url, modifiableEnvironment) ??
        super.findProxyFromEnvironment(url, modifiableEnvironment);
  }
}
