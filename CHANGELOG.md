## 0.1.8

### Architecture & DX Refactoring: Dedicated Sub-libraries for `http` & `http_interceptor`

- **Isolate Transitive Exports**: The main entrypoint (`package:basic_http_interceptor/basic_http_interceptor.dart`) no longer re-exports the entire `package:http_interceptor` (and transitively `package:http`).
- **Eliminate Global Namespace Pollution**: Prevents top-level convenience functions from `http` (`get`, `post`, `delete`, `put`, `head`, etc.) and pervasive type names (`Client`, `Request`, `Response`) from flooding the consumer's global scope, eliminating symbol collisions with Flutter widgets, local methods, and alternative networking libraries.
- **Dedicated Sub-library Entrypoints**:
  - `package:basic_http_interceptor/http.dart`: Re-exports `package:http` without requiring a direct dependency in the consumer's `pubspec.yaml`. Designed for prefixed imports (`import ... as http;`).
  - `package:basic_http_interceptor/http_interceptor.dart`: Re-exports `package:http_interceptor` for advanced interceptor configurations, contracts, and extension methods.

### Usage Examples

#### 1. Standard Usage (Clean & Isolated)
The main entrypoint remains completely clean, exposing only interceptor utilities and factory methods:
```dart
import 'package:basic_http_interceptor/basic_http_interceptor.dart';

final client = proxyClient(
  timeout: const Duration(seconds: 15),
  proxy: {'http_proxy': 'http://127.0.0.1:7890'},
);
```

#### 2. Accessing Raw HTTP Primitives (Prefixed Namespace)
Use the dedicated `http.dart` sub-library with the standard `as http` prefix:
```dart
import 'package:basic_http_interceptor/http.dart' as http;
import 'package:basic_http_interceptor/basic_http_interceptor.dart';

Future<void> fetchData() async {
  final http.Response res = await http.get(Uri.parse('https://api.example.com'));
  print(res.statusCode);
}
```

#### 3. Advanced Interceptor Customization
Access low-level interceptor contracts and extension methods via `http_interceptor.dart`:
```dart
import 'package:basic_http_interceptor/http_interceptor.dart';
import 'package:basic_http_interceptor/basic_http_interceptor.dart';

class CustomInterceptor implements InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async => request;

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async => response;
}
```

## 0.1.7

### Features
- Add `proxyClient` convenience factory: a versatile and extensible HTTP client builder where all parameters are optional and can be composed on demand (custom interceptors, default headers, timeout duration, proxy rules, and logger).
- Add automatic authorization header normalization and token inference helpers:
  - `normalizeAuthorizationHeaders`: Normalizes authorization headers case-insensitively.
  - `inferAuthorizationHeaderValue`: Automatically infers JWT Bearer tokens or Base64 Basic credentials when schemes are omitted.
  - `isJwt` & `isBase64Credentials`: Format validation helper utilities.

### Documentation & DX
- Update `README.md` with the `Reusable Client Factory` guide, highlighting optional parameter flexibility and modular configuration.
- Comprehensive unit test coverage for `proxyClient` and token inference helpers.

## 0.1.6

### Features
- Add `InterceptorTimeout` to enforce physical socket/connection abortion on timeout using `Abortable`, with optional `Logger` warnings and `onTimeout` callbacks.

### Improvements & DX
- Re-export `package:http_interceptor/http_interceptor.dart` completely. All standard HTTP classes (`Client`, `Request`, `Response`, `StreamedResponse`, `ClientException`, `RequestAbortedException`, etc.) and extension methods (`copyWith`, `addParameters`, etc.) are now accessible directly from `basic_http_interceptor`.
- Refresh English doc comments and include runnable usage examples for all interceptors and factory methods.
- Update `README.md` with complete modular interceptor recipes and cross-platform examples.

### Notes for Upgrading
- **Fully Backward Compatible**: No breaking changes.
- **Import Cleanup**: You can now safely remove redundant `import 'package:http/http.dart';` and `import 'package:http_interceptor/http_interceptor.dart';` statements across your codebase.

## 0.1.5

- Skip `StreamedResponse` body logging for compressed or known streamed content.
- Keep body logging unchanged for normal `Response` objects.

## 0.1.4

- Fix a streamed response logging stall when `content-encoding` is compressed (for example `gzip`).
- Skip body text logging for compressed streamed responses and keep transparent pass-through.
- Make `X-Debug-Body` header detection case-insensitive.

## 0.1.3

- Refine `InterceptorLogger` response logging to avoid fully consuming `StreamedResponse` bodies.
- Log streamed bodies in byte-based segments so SSE and long-lived streams stay responsive.
- Simplify non-streamed response logging to a single write.
- Improve `MethodSwitchingClient` routing docs for streaming, SSE, and upload scenarios.

## 0.1.2

- Add `MethodSwitchingClient` for dynamic request routing between interceptor and default HTTP clients.
- Document advanced usage with a concise subclass-based channel switching example.

## 0.1.1

- InterceptorLogger, add optional `logBodyMax` parameter.
- InterceptorLogger.interceptResponse, support `StreamedResponse` body logging.

## 0.1.0

- InterceptorLogger，buffer logs to reduce file I/O operations.

## 0.0.6

- InterceptorLogger，logBody = true, or exist header X-Debug-Body, output body.

## 0.0.5

- supports all six platforms, with client separated for non-web platforms.


## 0.0.4

- document update

## 0.0.3

- remove basic_http_interceptor_test.dart
- document update

## 0.0.2

- remove dependencies basic_logger.
- document update

## 0.0.1

- Initial version.
