# basic_http_interceptor

[![pub package](https://img.shields.io/pub/v/basic_http_interceptor.svg)](https://pub.dev/packages/basic_http_interceptor)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A lightweight, pluggable, and battery-included HTTP interceptor toolkit for Dart and Flutter applications.

---

## Why `basic_http_interceptor`?

- 🧩 **Modular & Pluggable**: Mix and match standalone interceptors for logging, headers, timeout abortion, and functional hooks like building blocks.
- ⚡ **Zero-Boilerplate Wrapper**: Set up an `InterceptedClient` with proxies and interceptor chains in just a few lines of code.
- 📦 **Complete Re-export**: Single entry point that fully re-exports `package:http` and `package:http_interceptor`—including all request/response classes and handy extensions (`copyWith`, `addParameters`, etc.).
- 🌐 **Cross-Platform Ready**: Out-of-the-box support for HTTP, HTTPS, and SOCKS5 proxies across all desktop and mobile platforms, with seamless fallback on Web.

---

## Interceptors at a Glance

| Interceptor | Description | Key Features |
| :--- | :--- | :--- |
| **`InterceptorTimeout`** | Physical connection timeout | Backed by `Abortable`; cuts underlying TCP/socket connections, logs warnings, and triggers callbacks. |
| **`InterceptorLogger`** | High-performance logger | Single-record buffering to minimize disk I/O, protects streamed/binary bodies, supports `X-Debug-Body`. |
| **`InterceptorHeader`** | Request header injector | Injects default headers (JWT Bearer tokens, API keys, content types). |
| **`InterceptorHook`** | Functional middleware | Transforms requests and responses using simple closures without creating custom classes. |

---

## Getting Started

Add the package to your `pubspec.yaml`:

```shell
dart pub add basic_http_interceptor
```

Or for Flutter projects:

```shell
flutter pub add basic_http_interceptor
```

---

## Quick Start

Only a single import is required to access the entire HTTP and interceptor ecosystem:

```dart
import 'package:basic_http_interceptor/basic_http_interceptor.dart';
import 'package:logging/logging.dart';

void main() async {
  final logger = Logger('HTTP');

  final client = interceptedClient(
    interceptors: [
      // 1. Inject default headers
      InterceptorHeader(requestHeader: {
        'Authorization': 'Bearer YOUR_JWT_TOKEN',
        'Accept': 'application/json',
      }),
      // 2. Abort connection on 60s timeout
      InterceptorTimeout(
        Duration(seconds: 60),
        logger: logger,
      ),
      // 3. Log request & response
      InterceptorLogger(logger, true),
    ],
    proxy: {
      'https_proxy': 'https://127.0.0.1:7890/',
      'http_proxy': 'http://127.0.0.1:7890/',
      'all_proxy': 'socks5://127.0.0.1:7891/',
      'no_proxy': 'localhost,127.0.0.1',
    },
  );

  final url = buildUrlString(
    'https://api.example.com/data',
    {'query': 'dart'},
  );

  final response = await client.get(Uri.parse(url));
  print('Status: ${response.statusCode}');
}
```

---

## Modular Recipes

### 1. Connection Timeout & Hard Abortion (`InterceptorTimeout`)

Unlike standard `Future.timeout` which only stops waiting in Dart while leaving the network socket open in the background, `InterceptorTimeout` leverages Dart's `Abortable` mechanism to **physically terminate the underlying socket/TCP connection**.

```dart
final client = interceptedClient(
  interceptors: [
    InterceptorTimeout(
      Duration(seconds: 60),
      logger: logger, // Automatically writes a warning when timed out
      onTimeout: (request) {
        print('Aborted timed out request: ${request.method} ${request.url}');
      },
    ),
  ],
);
```

### 2. High-Performance Logging (`InterceptorLogger`)

`InterceptorLogger` formats and logs requests and responses with production-ready safeguards:
- **I/O Optimization**: Buffers multi-line metadata into single log records to avoid excessive file write operations.
- **Stream Protection**: Skips logging or limits buffer size on compressed (`gzip`, `br`, `zstd`) and binary/streamed responses (e.g., SSE, video/audio) to avoid blocking memory.
- **Selective Body Logging**: Set `logBody = false` globally and pass `X-Debug-Body: true` in specific request headers to debug individual endpoints.

```dart
final client = interceptedClient(
  interceptors: [
    InterceptorLogger(
      logger,
      false, // logBody: false by default
      2 * 1024 * 1024, // logBodyMax: maximum 2MB buffer for stream inspection
    ),
  ],
);
```

### 3. Header Injection (`InterceptorHeader`)

Attach global headers such as authentication tokens, custom user-agents, or tracking IDs:

```dart
final client = interceptedClient(
  interceptors: [
    InterceptorHeader(requestHeader: {
      'Authorization': 'Bearer $jwtToken',
      'X-App-Version': '1.0.0',
    }),
  ],
);
```

### 4. Functional Request & Response Hooks (`InterceptorHook`)

Inspect or transform requests/responses on the fly without subclassing:

```dart
final client = interceptedClient(
  interceptors: [
    InterceptorHook(
      requestHook: (request) {
        // Dynamically append query parameters or headers
        final updatedUrl = request.url.addParameters({
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        });
        return request.copyWith(url: updatedUrl);
      },
      responseHook: (response) {
        // Inspect or transform response data
        return response;
      },
    ),
  ],
);
```

### 5. Multi-Protocol Proxies

Easily route traffic through HTTP, HTTPS, or SOCKS5 proxies:

```dart
final client = interceptedClient(
  interceptors: [...],
  proxy: {
    'http_proxy': 'http://127.0.0.1:7890/',
    'https_proxy': 'https://127.0.0.1:7890/',
    'all_proxy': 'socks5://127.0.0.1:7891/',
    'no_proxy': 'localhost,127.0.0.1,::1',
  },
);
```

---

## Advanced: Dynamic Request Routing (`MethodSwitchingClient`)

`MethodSwitchingClient` provides a centralized routing point to dispatch requests between an **interceptor client** and a **default/raw HTTP client** dynamically.

This is particularly useful when:
- Normal API requests should go through logging and header interceptors.
- AI Streaming requests (OpenAI, Anthropic, Gemini), SSE, or large file uploads need to bypass interceptors for performance.

```dart
import 'package:basic_http_interceptor/basic_http_interceptor.dart';
import 'package:logging/logging.dart';

final logger = Logger('Network');

// 1. Client with full interceptor suite
final httpClient = interceptedClient(
  interceptors: [
    InterceptorLogger(logger, true),
    InterceptorHeader(requestHeader: {'Authorization': 'Bearer $token'}),
  ],
);

// 2. Plain default client (platform-agnostic: IOClient on native, BrowserClient on Web)
final defaultClient = Client();

// 3. Dynamic switching client with custom routing
final client = MethodSwitchingClient(
  httpClient,
  defaultClient,
  useDefaultClientWhen: (request) {
    // Bypass interceptors for streaming endpoints or file uploads
    final isStreaming = request.url.path.contains('/stream') ||
        request.headers['accept'] == 'text/event-stream';
    return isStreaming || request is StreamedRequest;
  },
);
```

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 💖 Support the Project
If you find this tool helpful and would like to see it continue to improve and evolve, please consider showing your support.

*   ⭐ **Star the Repo**: This is a great encouragement. Your stars help more people discover this tool and gain more recognition in the community.
*   ☕ **Support the Developer (Global)**: Any contribution, however small, is a huge affirmation of my work. You can support via [GitHub Sponsors](https://github.com/sponsors/huanguan1978) or [Buy Me a Coffee](https://buymeacoffee.com/huanguan1978).
*   🐼 **Support via Ifdian (Mainland China)**: Users in China can also show support via [Ifdian](https://ifdian.net/a/huanguan1978).

*Thank you for your support, which is a vital boost that keeps me focused on the project's continuous iteration; because of you, more people can benefit from this tool much sooner.*
