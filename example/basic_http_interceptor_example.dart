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
  final jwt = '';
  final requestHeader = {
    'Authorization': 'Bearer $jwt',
  };

  final List<InterceptorContract> interceptors = [
    InterceptorLogger(logger),
    InterceptorHeader(requestHeader: requestHeader),
  ];

  final proxy = {
    'no_proxy': 'localhost,127.0.0.1,::1',
    'https_proxy': 'https://127.0.0.1:7890/',
    'http_proxy': 'http://127.0.0.1:7890/',
    'all_proxy': 'socks5://127.0.0.1:7891/',
  };

  final interClient = interceptedClient(
    interceptors: interceptors,
    proxy: proxy,
  );

  // https://www.google.com/search?q=hello+world
  final url = buildUrlString(
    'https://www.google.com',
    {'q': 'hello world'},
  );

  // http://localhost:8000/testdb
  //final url = buildUrlString('http://localhost:8000/testdb', null);

  final uri = Uri.parse(url);
  interClient.get(uri).then((Response response) {
    logger.info('--- response ---');
    logger.info(response.request?.method);
    logger.info(response.request?.url.toString());
    logger.info(response.statusCode);
    // logger.info(response.headers.toString());
    // logger.info(response.body.toString());
  });
}
