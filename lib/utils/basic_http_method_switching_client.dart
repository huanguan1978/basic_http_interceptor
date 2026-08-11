import 'package:http_interceptor/http_interceptor.dart' as http;

/// A client wrapper that dynamically switches between HTTP channels based on
/// the request scenario.
///
/// This client is intended for business cases where different kinds of
/// requests should use different transport paths, such as AI requests, file
/// uploads, streamed requests, or any request that should bypass interceptors.
///
/// It provides a single dispatch entry so each request can be routed to the
/// most appropriate underlying client at runtime.
///
/// The default implementation sends [http.StreamedRequest] instances through
/// the plain client and routes all other requests through the interceptor
/// client.
///
/// To implement a more specific routing strategy, extend this class and
/// override [send]. Subclasses can inspect the outgoing request and choose
/// between [interceptedClient] and [defaultClient] according to business
/// rules.
///
/// Example:
/// ```dart
/// import 'dart:io';
///
/// import 'package:basic_http_interceptor/basic_http_interceptor.dart';
/// import 'package:googleai_dart/googleai_dart.dart';
/// import 'package:http/io_client.dart';
/// import 'package:logging/logging.dart';
///
/// final logger = Logger('google-ai');
///
/// final proxy = {
///   'no_proxy': 'localhost,127.0.0.1,::1',
///   'https_proxy': 'https://127.0.0.1:7890/',
///   'http_proxy': 'http://127.0.0.1:7890/',
///   'all_proxy': 'socks5://127.0.0.1:7891/',
/// };
///
/// final httpClient = interceptedClient(
///   proxy: proxy,
///   interceptors: [
///     InterceptorLogger(logger, true),
///   ],
/// );
///
/// final defaultClient = IOClient(
///   HttpClient()
///     ..findProxy = (url) =>
///         HttpClient.findProxyFromEnvironment(url, environment: proxy),
/// );
///
/// final gaiClient = GoogleAIClient(
///   httpClient: MethodSwitchingClient(httpClient, defaultClient),
///   config: GoogleAIConfig.googleAI(
///     authProvider: ApiKeyProvider(apikey),
///     timeout: const Duration(minutes: 2),
///     retryPolicy: RetryPolicy.defaultPolicy,
///   ),
/// );
/// ```
class MethodSwitchingClient extends http.BaseClient {
  final http.Client _intercepted;
  final http.Client _defaulted;

  MethodSwitchingClient(this._intercepted, this._defaulted);

  /// The client that applies interceptors.
  ///
  /// Intended for subclasses that customize request routing.
  http.Client get interceptedClient => _intercepted;

  /// The plain client used when a request should bypass interceptors.
  ///
  /// Intended for subclasses that customize request routing.
  http.Client get defaultClient => _defaulted;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is http.StreamedRequest) return _defaulted.send(request);
    return _intercepted.send(request);
  }

  @override
  void close() {
    _intercepted.close();
    _defaulted.close();
  }
}
