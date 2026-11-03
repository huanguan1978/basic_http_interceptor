/// Sub-library entrypoint re-exporting the underlying `http_interceptor` package.
///
/// ## Design Rationale
/// Re-exports the complete `package:http_interceptor` toolkit for advanced
/// interceptor patterns (such as custom [InterceptorContract] implementations,
/// [RetryPolicy], or low-level [InterceptedHttp] builders) without exposing
/// them or their transitive dependencies in the main `basic_http_interceptor`
/// entrypoint.
///
/// ## Recommended Usage
/// Import this sub-library with a namespace prefix or selective show/hide:
/// ```dart
/// import 'package:basic_http_interceptor/http_interceptor.dart' as http_interceptor;
/// import 'package:basic_http_interceptor/basic_http_interceptor.dart';
///
/// class CustomRetryPolicy extends http_interceptor.RetryPolicy {
///   @override
///   int maxRetryAttempts = 3;
/// }
/// ```
library;

export 'package:http_interceptor/http_interceptor.dart';
