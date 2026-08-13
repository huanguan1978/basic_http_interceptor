<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

basic http interceptor for beginners.

## Features

- http logger interceptor
- http header interceptor
- http request/response hook
- http proxy

## Getting started

```shell
    dart pub add basic_http_interceptor
```

## Usage

> Important (v0.1.4+): `InterceptorLogger` provides stable logging for `StreamedResponse` with transparent pass-through. For compressed responses (for example `content-encoding: gzip`), body text logging is skipped to avoid stream stalls.

```dart
  final logger = Logger('main');

  final List<InterceptorContract> interceptors = [
    // logBody = true, or exist header X-Debug-Body, output body
    InterceptorLogger(logger, true),
  ];

  final interClient = interceptedClient(
    interceptors: interceptors,
  );

  // https://www.google.com/search?q=hello+world
  final url = buildUrlString(
    'https://www.google.com',
    {'q': 'hello world'},
  );

  interClient.get(url.toUri()).then((Response response) {
    logger.info('--- response ---');
    logger.info(response.request?.method);
    logger.info(response.request?.url.toString());
    logger.info(response.statusCode);
    // logger.info(response.headers.toString());
    // logger.info(response.body.toString());
  });

```

## Additional information

- http header interceptor

```dart
  final jwt = '';
  final requestHeader = {
    'Authorization': 'Bearer $jwt',
  };

  final List<InterceptorContract> interceptors = [
    InterceptorHeader(requestHeader: requestHeader),
  ];

  final interClient = interceptedClient(
    interceptors: interceptors,
  );
```

- http proxy

```dart
  final List<InterceptorContract> interceptors = [
  ];
  
  final proxy = {
    'no_proxy': 'localhost,127.0.0.1,::1',
    'https_proxy': 'https://127.0.0.1:7890/',
    'http_proxy': 'http://127.0.0.1:7890/',
    'all_proxy': 'socks5://127.0.0.1:7891/',
  };

  final interClient = interceptedClient(
    interceptors: interceptors,
    proxy:proxy,
  );
```

- http hook

```dart

  BaseRequest requestHandle(BaseRequest request ){
    // handle http headers
    final header = request.headers;
    header.addAll({
        'appkey': '',
        'appid': '',
    });

    // handle url param
    final url = request.url;
    url.addParameters({
        'timestamp': DateTime.now().microsecondsSinceEpoch,
    });

    final req = request.copyWith(
        headers:header,
        url:url,
    );

    return req;
  }

  BaseResponse responseHandle(BaseResponse response ){
    return response;
  }

  final interceptorHook = InterceptorHook(
    requestHook:requestHandle,
    responseHook:responseHandle,
  );
  final List<InterceptorContract> interceptors = [
    interceptorHook,
  ];
  
  final interClient = interceptedClient(
    interceptors: interceptors,
  );
```

## Advanced usage

`MethodSwitchingClient` is designed for cases where different requests in the
same workflow need to travel through different HTTP channels.

Its purpose is not to replace a regular HTTP client. Instead, it gives you a
single routing point where you can decide which underlying client should
handle each request, so your transport strategy stays centralized and easy to
maintain.

Typical use cases include:

- sending normal requests through the interceptor client so you keep logging,
  header injection, hooks, or proxy support
- sending streamed requests, SSE, long-lived connections, or upload requests
  through the default client so they are not affected by interceptors
- routing AI APIs, special third-party endpoints, or specific URL patterns
  according to your business rules
- bypassing interceptors for some requests while keeping them enabled for
  others

If your routing rules are simple, you can extend `MethodSwitchingClient` and
override `send()` to choose the right client for each request.
If your routing logic is more complex, you can combine any conditions you need,
such as request path, HTTP method, headers, or body content.

This pattern gives you a few important benefits:

- your application code does not need to be cluttered with repeated "should
  this request bypass interceptors?" checks
- interceptor-based behavior and plain HTTP behavior can coexist in the same
  project
- your routing strategy stays flexible and can evolve with your application

The example below shows a realistic routing setup: normal requests go through
the interceptor client, while upload, streaming, or special API requests go
through the default client.

```dart
import 'dart:io';

import 'package:basic_http_interceptor/basic_http_interceptor.dart';
import 'package:http/io_client.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:logging/logging.dart';

class AiRoutingClient extends MethodSwitchingClient {
  AiRoutingClient(super.intercepted, super.defaulted);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    final isUpload = request.url.path.contains('/upload');
    final shouldBypassInterceptors =
        request is StreamedRequest || isUpload;

    if (shouldBypassInterceptors) {
      return defaultClient.send(request);
    }

    return interceptedClient.send(request);
  }
}

final logger = Logger('google-ai');

final proxy = {
  'no_proxy': 'localhost,127.0.0.1,::1',
  'https_proxy': 'https://127.0.0.1:7890/',
  'http_proxy': 'http://127.0.0.1:7890/',
  'all_proxy': 'socks5://127.0.0.1:7891/',
};

final httpClient = interceptedClient(
  proxy: proxy,
  interceptors: [
    InterceptorLogger(logger, true),
  ],
);

final defaultClient = IOClient(
  HttpClient()
    ..findProxy = (url) =>
        HttpClient.findProxyFromEnvironment(url, environment: proxy),
);

final aiClient = AiRoutingClient(httpClient, defaultClient);
```
