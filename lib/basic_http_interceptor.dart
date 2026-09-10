/// Lightweight, pluggable HTTP interceptors for logging, default headers,
/// functional hooks, proxy configurations, and request timeout abortion.
library basic_http_interceptor;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http_interceptor/extensions/streamed_response.dart';
import 'package:http_interceptor/http_interceptor.dart'
    show
        Abortable,
        AbortableMultipartRequest,
        AbortableRequest,
        BaseRequest,
        BaseResponse,
        InterceptorContract,
        MultipartRequest,
        Request,
        Response,
        StreamedResponse;

import 'package:logging/logging.dart';

export 'package:http_interceptor/http_interceptor.dart';

export 'package:http_interceptor/utils/query_parameters.dart'
    show buildUrlString;

export 'utils/basic_http_interceptor_webclient.dart'
    if (dart.library.io) 'utils/basic_http_interceptor_ioclient.dart';
export 'utils/basic_http_method_switching_client.dart';

part 'src/basic_http_interceptor_logger.dart';
part 'src/basic_http_interceptor_header.dart';
part 'src/basic_http_interceptor_hook.dart';
part 'src/basic_http_interceptor_timeout.dart';

// export 'src/basic_http_interceptor_base.dart';

// TODO: Export any libraries intended for clients of this package.
