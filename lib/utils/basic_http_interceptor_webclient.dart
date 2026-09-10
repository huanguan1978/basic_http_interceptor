import 'package:http_interceptor/http_interceptor.dart'
    show InterceptorContract, InterceptedClient;

/// Creates an [InterceptedClient] configured with the given [interceptors] and optional [proxy] settings.
///
/// On Web platforms, proxy configurations are handled natively by the browser.
///
/// Example:
/// ```dart
/// final client = interceptedClient(
///   interceptors: [
///     InterceptorHeader(requestHeader: {'Authorization': 'Bearer $token'}),
///     InterceptorLogger(logger, true),
///   ],
/// );
/// ```
InterceptedClient interceptedClient({
  required List<InterceptorContract> interceptors,
  Map<String, String> proxy = const {},
}) {
  return InterceptedClient.build(
    interceptors: interceptors,
  );
}
