import 'package:http_interceptor/http_interceptor.dart' as http;

/// A client wrapper that dynamically routes requests between HTTP clients
/// based on request type and content.
///
/// This client is useful when different requests should take different paths,
/// such as AI requests, file uploads, streamed requests, or any request that
/// should bypass interceptors.
///
/// It provides a single entry point that routes each request to the most
/// appropriate underlying client at runtime.
///
/// The default routing behavior stays lightweight:
/// - [http.StreamedRequest] uses the plain client
/// - Gemini SSE-style requests use the plain client
/// - OpenAI and Anthropic streaming requests also use the plain client when
///   their JSON body contains `"stream": true`
///
/// If you only need simple per-request routing, pass
/// [useDefaultClientWhen] at construction time. This callback has the highest
/// priority and is a convenient way to override the default routing behavior.
///
/// If you need finer-grained control, extend this class and override
/// [shouldUseDefaultClient]. That lets you implement custom routing based on
/// the request method, URL, headers, or body content.
///
/// This client is especially useful when:
/// - some requests should keep interceptor behavior
/// - some requests must bypass interceptors, such as long-lived connections,
///   SSE, or streaming uploads
/// - different third-party APIs need different HTTP client paths
///
/// Example:
/// ```dart
/// import 'package:basic_http_interceptor/basic_http_interceptor.dart';
/// import 'package:googleai_dart/googleai_dart.dart';
/// import 'package:logging/logging.dart';
///
/// final logger = Logger('google-ai');
///
/// final interceptedClient = interceptedClient(
///   interceptors: [
///     InterceptorLogger(logger, true),
///   ],
/// );
///
/// final defaultClient = Client();
///
/// final client = MethodSwitchingClient(
///   interceptedClient,
///   defaultClient,
///   useDefaultClientWhen: (request) {
///     return request.url.host.contains('api.openai.com') ||
///         request.url.host.contains('api.anthropic.com');
///   },
/// );
///
/// final gaiClient = GoogleAIClient(
///   httpClient: client,
///   config: GoogleAIConfig.googleAI(
///     authProvider: ApiKeyProvider(apikey),
///   ),
/// );
/// ```
///
/// If you need even more control, extend this class and override
/// [shouldUseDefaultClient] to fully customize the routing logic.
class MethodSwitchingClient extends http.BaseClient {
  final http.Client _intercepted;
  final http.Client _defaulted;
  final bool Function(http.BaseRequest request)? _useDefaultClientWhen;

  MethodSwitchingClient(
    this._intercepted,
    this._defaulted, {
    bool Function(http.BaseRequest request)? useDefaultClientWhen,
  }) : _useDefaultClientWhen = useDefaultClientWhen;

  /// The client that applies interceptors.
  http.Client get interceptedClient => _intercepted;

  /// The plain client used for requests that should bypass interceptors.
  http.Client get defaultClient => _defaulted;

  /// Returns `true` when [request] should be sent through [defaultClient].
  ///
  /// The constructor callback has the highest priority. If no callback is
  /// provided, the built-in minimal routing rules are used.
  ///
  /// Override this method in a subclass if your project needs custom routing
  /// based on request method, URL, headers, or body content.
  bool shouldUseDefaultClient(http.BaseRequest request) {
    final decision = _useDefaultClientWhen;
    if (decision != null) {
      return decision(request);
    }

    if (request is http.StreamedRequest) {
      return true;
    }

    if (_isGeminiStreamingRequest(request)) {
      return true;
    }

    if (_isKnownJsonStreamingRequest(request)) {
      return true;
    }

    return false;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (shouldUseDefaultClient(request)) {
      return _defaulted.send(request);
    }
    return _intercepted.send(request);
  }

  @override
  void close() {
    _intercepted.close();
    _defaulted.close();
  }

  /// Detects Gemini streaming requests using stable URL features.
  bool _isGeminiStreamingRequest(http.BaseRequest request) {
    final url = request.url;

    final host = url.host.toLowerCase();
    if (!_isKnownStreamingHost(host)) {
      return false;
    }

    if (url.queryParameters['alt'] == 'sse') {
      return true;
    }

    if (url.path.contains(':streamGenerateContent')) {
      return true;
    }

    if (url.path.contains(':generateContent') &&
        (url.path.contains('-image') || url.path.contains('-tts'))) {
      return true;
    }

    return false;
  }

  /// Detects OpenAI and Anthropic streaming requests with minimal body checks.
  ///
  /// This only inspects known hosts and only reads text bodies from
  /// [http.Request]. It avoids parsing arbitrary payloads or consuming
  /// streamed request bodies.
  bool _isKnownJsonStreamingRequest(http.BaseRequest request) {
    if (request is! http.Request) {
      return false;
    }

    final host = request.url.host.toLowerCase();
    if (!_isKnownStreamingHost(host)) {
      return false;
    }

    final body = request.body;
    if (body.isEmpty) {
      return false;
    }

    return RegExp(r'"stream"\s*:\s*true').hasMatch(body);
  }

  /// Returns `true` for known API hosts that commonly enable streaming with a
  /// JSON `"stream": true` field.
  bool _isKnownStreamingHost(String host) {
    return host.contains('generativelanguage.googleapis.com') ||
        host.contains('api.openai.com') ||
        host.contains('api.anthropic.com');
  }
}
