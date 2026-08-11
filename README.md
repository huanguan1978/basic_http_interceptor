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

`MethodSwitchingClient` is useful when different requests should use different
HTTP channels at runtime.

You can extend this class and override `send()` to route each request according
to your business rules. This is a practical approach for AI requests, file
uploads, streamed requests, or any call that should bypass interceptors.

In the example below:

- normal requests go through the interceptor client;
- streamed requests and upload endpoints go through the default client.

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
