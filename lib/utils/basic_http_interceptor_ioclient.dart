import 'dart:io' show HttpClient;
import 'package:http/io_client.dart' show IOClient;
import 'package:http_interceptor/http_interceptor.dart'
    show InterceptorContract, InterceptedClient, Client;

/// Creates an [InterceptedClient] configured with the given [interceptors] and optional [proxy] settings.
///
/// Example:
/// ```dart
/// final client = interceptedClient(
///   interceptors: [
///     InterceptorHeader(requestHeader: {'Authorization': 'Bearer $token'}),
///     InterceptorLogger(logger, true),
///   ],
///   proxy: {
///     'https_proxy': 'http://127.0.0.1:7890/',
///     'http_proxy': 'http://127.0.0.1:7890/',
///     'all_proxy': 'socks5://127.0.0.1:7891/',
///     'no_proxy': 'localhost,127.0.0.1',
///   },
/// );
/// ```
InterceptedClient interceptedClient({
  required List<InterceptorContract> interceptors,
  Map<String, String> proxy = const {},
}) {
  Client? proxyClient;
  if (proxy.isNotEmpty) {
    proxyClient = IOClient(
      HttpClient()
        ..findProxy = (url) {
          return HttpClient.findProxyFromEnvironment(url, environment: proxy);
        },
    );
  }

  return InterceptedClient.build(
    interceptors: interceptors,
    client: proxyClient,
  );
}
