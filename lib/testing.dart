/// Sub-library entrypoint re-exporting `package:http/testing.dart`.
///
/// ## Design Rationale
/// In HTTP client development, [MockClient] is essential for deterministic
/// unit testing without triggering actual network calls.
///
/// By providing this dedicated testing sub-library, applications using
/// `basic_http_interceptor` can mock HTTP responses directly in their test
/// suites without declaring a separate dependency on `package:http` in
/// their `pubspec.yaml`.
///
/// ## Recommended Usage
/// Import this sub-library in test files (under the `test/` directory):
/// ```dart
/// import 'dart:convert';
/// import 'package:basic_http_interceptor/basic_http_interceptor.dart';
/// import 'package:basic_http_interceptor/http.dart';
/// import 'package:basic_http_interceptor/testing.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   test('mocks HTTP request with interceptor', () async {
///     final mockClient = MockClient((request) async {
///       return Response(jsonEncode({'status': 'ok'}), 200);
///     });
///
///     final client = InterceptedClient.build(
///       client: mockClient,
///       interceptors: [],
///     );
///
///     final response = await client.get(Uri.parse('https://example.com'));
///     expect(response.statusCode, 200);
///   });
/// }
/// ```
library;

export 'package:http/testing.dart';
