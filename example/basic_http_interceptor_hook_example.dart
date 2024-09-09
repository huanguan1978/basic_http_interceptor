import 'package:logging/logging.dart';
import 'package:http_interceptor/http_interceptor.dart';

import 'package:basic_http_interceptor/basic_http_interceptor.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '${record.time}: [${record.level}] [${record.loggerName}] ${record.message}');
  });

  final logger = Logger('main');

  final List<InterceptorContract> interceptors = [
    InterceptorLogger(logger),
    InterceptorHook(
      requestHook: (request) {
        /*
        final header = request.headers;
        header.addAll({
          'appkey': '',
          'appid': '',
        });
        */

        final url = request.url.addParameters({
          'q': 'dart language tutorial',
        });

        final req = request.copyWith(
          // headers: header,
          url: url,
        );

        return req;
      },
      responseHook: (response) {
        return response;
      },
    )
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
}
