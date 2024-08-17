import 'package:basic_http_interceptor/basic_http_interceptor.dart';
import 'package:test/test.dart';

void main() {
  group('InterceptorHeader tests', () {
    final jwt = '';
    final requestHeader = {
      'Authorization': 'Bearer $jwt',
    };
    final interceptorHeader = InterceptorHeader(requestHeader: requestHeader);

    setUp(() {
      // Additional setup goes here.
    });

    test('requestHeader Test', () {
      expect(interceptorHeader.requestHeader, contains('Authorization'));
    });
  });
}
