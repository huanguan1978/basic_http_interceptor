/// Sub-library entrypoint re-exporting the underlying `http` package.
///
/// ## Design Rationale
/// The main library (`package:basic_http_interceptor/basic_http_interceptor.dart`)
/// intentionally does not export `package:http` to avoid global namespace pollution.
/// `package:http` defines several top-level convenience functions (`get`, `post`,
/// `put`, `delete`, `head`, `patch`, `read`, `readBytes`) as well as ubiquitous
/// type names like `Client`, `Request`, and `Response`.
///
/// In standard Dart practices, importing `package:http` without a namespace prefix
/// can easily cause identifier collisions with local functions, state management
/// frameworks (e.g. `GetX`), or alternative networking/gRPC/Shelf libraries.
///
/// By providing this dedicated sub-library entrypoint, applications using
/// `basic_http_interceptor` can access raw `http` classes and functions on demand
/// without having to declare a direct dependency on `http` in their `pubspec.yaml`.
///
/// ## Recommended Usage
/// Import this sub-library with a namespace prefix (typically `as http`):
/// ```dart
/// import 'package:basic_http_interceptor/http.dart' as http;
/// import 'package:basic_http_interceptor/basic_http_interceptor.dart';
///
/// Future<void> fetchData() async {
///   final http.Response response = await http.get(Uri.parse('https://api.example.com/data'));
///   if (response.statusCode == 200) {
///     print(response.body);
///   }
/// }
/// ```
library;

export 'package:http/http.dart';
