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
