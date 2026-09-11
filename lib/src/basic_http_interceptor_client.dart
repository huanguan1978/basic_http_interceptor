part of '../basic_http_interceptor.dart';

/// Creates an HTTP client configured with custom interceptors, request headers,
/// a request timeout, and a proxy.
///
/// The [interceptors] list is copied and used as the initial interceptor list,
/// so it is not modified by this method. If [logger] is provided, a logging
/// interceptor is appended after the custom interceptors. The [headers] map is
/// copied before its Authorization header is normalized, and its header
/// interceptor is appended after the timeout interceptor.
///
/// If [timeout] is provided, a timeout interceptor is appended after the
/// logging interceptor. The [proxy] map specifies the proxy settings used by
/// the client.
///
/// The package does not prescribe how [timeout], [proxy], or [headers] are
/// obtained. An application can provide its own resolver methods for values
/// entered through a UI, loaded from persistent settings, or read from the
/// system environment.
///
/// ```dart
/// final client = proxyClient(
///   timeout: loadTimeoutFromSettings(),
///   proxy: loadProxyFromSettings(),
///   headers: {'Authorization': token},
/// );
/// ```
InterceptedClient proxyClient({
  Map<String, String> headers = const {},
  Map<String, String> proxy = const {},
  List<InterceptorContract> interceptors = const [],
  Duration? timeout,
  Logger? logger,
}) {
  final allInterceptors = List<InterceptorContract>.from(interceptors);

  if (logger != null) {
    allInterceptors.add(InterceptorLogger(logger, true));
  }
  if (timeout != null) {
    allInterceptors.add(InterceptorTimeout(timeout, logger: logger));
  }

  final requestHeaders = normalizeAuthorizationHeaders(headers);
  if (requestHeaders.isNotEmpty) {
    allInterceptors.add(InterceptorHeader(requestHeader: requestHeaders));
  }

  return interceptedClient(interceptors: allInterceptors, proxy: proxy);
}

/// Returns a copy of [headers] with its Authorization header normalized.
///
/// Header names are matched case-insensitively. If an Authorization header is
/// present, its value is inferred by [inferAuthorizationHeaderValue] and the
/// output key is normalized to `Authorization`. The input map is not modified.
Map<String, String> normalizeAuthorizationHeaders(
  Map<String, String> headers,
) {
  final normalizedHeaders = Map<String, String>.from(headers);
  String? authorizationKey;

  for (final key in normalizedHeaders.keys) {
    if (key.toLowerCase() == 'authorization') {
      authorizationKey = key;
      break;
    }
  }

  if (authorizationKey == null) return normalizedHeaders;

  final authorization = inferAuthorizationHeaderValue(
    normalizedHeaders[authorizationKey]!,
  );
  normalizedHeaders.removeWhere(
    (key, _) => key.toLowerCase() == 'authorization',
  );
  if (authorization.isNotEmpty) {
    normalizedHeaders['Authorization'] = authorization;
  }

  return normalizedHeaders;
}

/// Infers and adds an authorization scheme to an untyped authorization token.
///
/// Existing `Basic`, `Bearer`, and `Digest` values are returned unchanged.
/// Otherwise, structurally valid JWTs are prefixed with `Bearer`, and valid
/// Base64-encoded `username:password` credentials are prefixed with `Basic`.
/// Values that do not match either format are returned unchanged.
///
/// This method only infers the header format; it does not verify a JWT
/// signature or authenticate the credentials.
String inferAuthorizationHeaderValue(String authorization) {
  if (authorization.isEmpty) return authorization;
  if (authorization.startsWith('Basic ')) return authorization;
  if (authorization.startsWith('Bearer ')) return authorization;
  if (authorization.startsWith('Digest ')) return authorization;

  if (isJwt(authorization)) return 'Bearer $authorization';
  if (isBase64Credentials(authorization)) return 'Basic $authorization';

  return authorization;
}

/// Validates whether [token] has the structural format of a JSON Web Token.
///
/// This checks the number of segments and parses the Base64Url-encoded header
/// and payload as JSON. It does not verify the JWT cryptographic signature.
bool isJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 2 && parts.length != 3) return false;

  try {
    for (var index = 0; index < 2; index++) {
      final normalized = base64Url.normalize(parts[index]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      jsonDecode(decoded);
    }
    return true;
  } catch (_) {
    return false;
  }
}

/// Validates whether [base64String] decodes to a `username:password` pair.
///
/// The decoded value must contain a colon, as required by Basic Authentication
/// credentials. This method validates format only; it does not authenticate
/// the credentials.
bool isBase64Credentials(String base64String) {
  if (base64String.isEmpty) return false;

  try {
    final decoded = utf8.decode(base64.decode(base64String));
    return decoded.contains(':');
  } catch (_) {
    return false;
  }
}
