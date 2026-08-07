/// Support for doing something awesome.
///
/// More dartdocs go here.
library basic_http_interceptor;

import 'dart:convert';

import 'package:http_interceptor/extensions/streamed_response.dart';
import 'package:http_interceptor/http_interceptor.dart'
    show
        BaseRequest,
        BaseResponse,
        InterceptorContract,
        Request,
        Response,
        StreamedResponse;

import 'package:logging/logging.dart';

export 'package:http_interceptor/utils/query_parameters.dart'
    show buildUrlString;

export 'utils/basic_http_interceptor_webclient.dart'
    if (dart.library.io) 'utils/basic_http_interceptor_ioclient.dart';

part 'src/basic_http_interceptor_logger.dart';
part 'src/basic_http_interceptor_header.dart';
part 'src/basic_http_interceptor_hook.dart';

// export 'src/basic_http_interceptor_base.dart';

// TODO: Export any libraries intended for clients of this package.
