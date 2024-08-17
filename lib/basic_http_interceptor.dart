/// Support for doing something awesome.
///
/// More dartdocs go here.
library basic_http_interceptor;

import 'package:logging/logging.dart';

import 'package:http_interceptor/http_interceptor.dart'
    show
        BaseRequest,
        BaseResponse,
        InterceptorContract,
        Response,
        InterceptedClient,
        Client;

import 'dart:io' show HttpClient;

import 'package:http/io_client.dart' show IOClient;

part 'src/basic_http_interceptor_logger.dart';
part 'src/basic_http_interceptor_header.dart';
part 'src/basic_http_interceptor_hook.dart';
part 'src/basic_http_interceptor_client.dart';

// export 'src/basic_http_interceptor_base.dart';

// TODO: Export any libraries intended for clients of this package.
