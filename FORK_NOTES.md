# Company fork maintenance

This branch merges upstream `v1.3.5` (`4cd4224`) into `merge-1.1.14`
(`4ab0bdd`).

Keep these company HTTP proxy behaviors when merging future upstream releases:

- Forward each instrumented client's proxy lookup to the existing `HttpOverrides`.
- Copy environment maps before passing them to proxy resolvers, so resolvers can
  modify them without mutating `Platform.environment` or a caller's map.
- Preserve custom client factories and custom proxy resolvers.

The implementation now lives in `lib/newrelic_http_overrides_io.dart`. The old
`lib/newrelic_http_overrides.dart` is only a conditional export; keeping a commit
in Git history does not guarantee that its behavior survived this file split.

The empty distributed-trace data guard is already present upstream. Its Android
and iOS behavior is covered by additional tests in `test/newrelic_mobile_test.dart`.
Proxy regression tests are in `test/company_http_proxy_test.dart`.

Run `flutter test` before publishing a merged branch. Android consumers must align
the New Relic instrumentation plugin with this branch's Android agent version,
currently `7.8.5`.
