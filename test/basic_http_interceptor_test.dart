import 'dart:async';

import 'package:basic_http_interceptor/basic_http_interceptor.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
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

    test(
        'lowercase X-Debug-Body header should still enable streamed body logging',
        () async {
      final logger = Logger('test');
      final interceptor = InterceptorLogger(logger, false, 8);
      final controller = StreamController<List<int>>();
      final response = StreamedResponse(
        controller.stream,
        200,
        headers: {
          'content-type': 'application/json',
          'x-debug-body': 'true',
        },
      );

      final wrapped = await interceptor.interceptResponse(response: response);

      // The streamed-response logger returns a copyWith(stream: transformedStream),
      // so a different object instance is the direct proof that the
      // _logStreamedResponseBody path was taken.
      expect(wrapped, isNot(same(response)));
      expect(wrapped, isA<StreamedResponse>());

      controller.add([104, 101, 108, 108, 111]);
      controller.add([32, 119, 111, 114, 108, 100]);
      controller.close();

      final data = <int>[];
      await for (final chunk in (wrapped as StreamedResponse).stream) {
        data.addAll(chunk);
      }

      expect(String.fromCharCodes(data), equals('hello world'));
    });

    test('gzip encoded streamed response should bypass body text logging path',
        () async {
      final logger = Logger('test');
      final interceptor = InterceptorLogger(logger, false, 8);
      final controller = StreamController<List<int>>();
      final response = StreamedResponse(
        controller.stream,
        200,
        headers: {
          'content-type': 'application/json',
          'content-encoding': 'gzip',
          'x-debug-body': 'true',
        },
      );

      final wrapped = await interceptor.interceptResponse(response: response);

      expect(identical(wrapped, response), isTrue);
      expect(wrapped, isA<StreamedResponse>());

      controller.add([31, 139, 8, 0, 0, 0, 0, 0]);
      controller.close();

      final data = <int>[];
      await for (final chunk in (wrapped as StreamedResponse).stream) {
        data.addAll(chunk);
      }

      expect(data, equals([31, 139, 8, 0, 0, 0, 0, 0]));
    });
  });
}
