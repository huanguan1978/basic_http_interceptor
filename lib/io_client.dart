/// Sub-library entrypoint re-exporting `package:http/io_client.dart` with
/// convenience factory helpers for proxy configuration.
///
/// ## Design Rationale
/// 1. **Web Compatibility**: [IOClient] depends directly on `dart:io` (`HttpClient`),
///    which is unavailable on Web platforms. By isolating [IOClient] in this
///    dedicated sub-library entrypoint, the main library
///    (`package:basic_http_interceptor/basic_http_interceptor.dart`) and platform-agnostic
///    sub-libraries (`package:basic_http_interceptor/http.dart`) remain 100% compatible
///    with Flutter Web and Dart Web / WASM.
/// 2. **Transitive Re-export**: VM, Flutter mobile, and desktop applications can
///    access [IOClient] directly without needing to declare a direct dependency on
///    `package:http` in their `pubspec.yaml`.
/// 3. **Non-Intercepted Raw Client**: Applications frequently need a lightweight,
///    raw HTTP client preconfigured with proxy settings (e.g. as the fallback client
///    in [MethodSwitchingClient], or for raw streaming/large downloads where interceptor
///    overhead is undesirable). [proxyIoClient] provides this out of the box without
///    requiring callers to write boilerplate `dart:io` code.
///
/// ## Application Scenarios
/// - Routing traffic through HTTP, HTTPS, or SOCKS5 proxies without interceptor overhead.
/// - Providing the underlying default client for [MethodSwitchingClient].
/// - Development environments requiring custom SSL certificate verification callbacks.
///
/// ## Usage Examples
///
/// ### Creating a Proxy-Enabled Raw IOClient
/// ```dart
/// import 'package:basic_http_interceptor/io_client.dart';
///
/// final client = proxyIoClient(
///   proxy: {
///     'https_proxy': 'https://127.0.0.1:7890/',
///     'http_proxy': 'http://127.0.0.1:7890/',
///     'all_proxy': 'socks5://127.0.0.1:7891/',
///     'no_proxy': 'localhost,127.0.0.1',
///   },
/// );
/// ```
///
/// ### Using with MethodSwitchingClient
/// ```dart
/// import 'package:basic_http_interceptor/basic_http_interceptor.dart';
/// import 'package:basic_http_interceptor/io_client.dart';
///
/// final rawClient = proxyIoClient(proxy: {'https_proxy': 'https://127.0.0.1:7890/'});
/// final intercepted = interceptedClient(interceptors: [...]);
///
/// final client = MethodSwitchingClient(
///   intercepted,
///   rawClient,
///   useDefaultClientWhen: (req) => req.url.path.contains('/stream'),
/// );
/// ```
///
/// ### Accessing Standard IOClient Directly
/// ```dart
/// import 'dart:io' as io;
/// import 'package:basic_http_interceptor/io_client.dart';
///
/// final customHttpClient = io.HttpClient()
///   ..idleTimeout = const Duration(seconds: 15);
/// final client = IOClient(customHttpClient);
/// ```
library;

import 'dart:io' as io;
import 'package:http/io_client.dart';

export 'package:http/io_client.dart';

/// Creates a raw, non-intercepted [IOClient] configured with optional [proxy] rules
/// and custom SSL certificate validation settings.
///
/// Unlike [interceptedClient], this client is **not** wrapped by any interceptors,
/// making it ideal for performance-sensitive requests (e.g., SSE, AI token streaming,
/// large file transfers) or as the default client in [MethodSwitchingClient].
///
/// - [proxy]: Environment map supporting `http_proxy`, `https_proxy`, `all_proxy`,
///   and `no_proxy`.
/// - [badCertificateCallback]: Optional callback to customize or bypass SSL
///   certificate verification (e.g. self-signed certificates in local development).
IOClient proxyIoClient({
  Map<String, String> proxy = const {},
  bool Function(io.X509Certificate cert, String host, int port)?
      badCertificateCallback,
}) {
  final httpClient = io.HttpClient();
  if (proxy.isNotEmpty) {
    httpClient.findProxy = (url) {
      return io.HttpClient.findProxyFromEnvironment(url, environment: proxy);
    };
  }
  if (badCertificateCallback != null) {
    httpClient.badCertificateCallback = badCertificateCallback;
  }
  return IOClient(httpClient);
}
