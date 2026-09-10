import 'dart:async';

import 'package:basic_http_interceptor/basic_http_interceptor.dart';
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

    test('gzip header does not bypass full body logging for Response',
        () async {
      Logger.root.level = Level.ALL;
      final messages = <String>[];
      final sub = Logger.root.onRecord.listen((event) {
        messages.add(event.message.toString());
      });

      final logger = Logger('test.response');
      final interceptor = InterceptorLogger(logger, false, 8);
      final response = Response(
        'hello response',
        200,
        headers: {
          'content-type': 'application/json',
          'content-encoding': 'gzip',
          'x-debug-body': 'true',
        },
      );

      final wrapped = await interceptor.interceptResponse(response: response);

      await sub.cancel();

      expect(identical(wrapped, response), isTrue);
      expect(messages.join('\n'), contains('hello response'));
      expect(
        messages.join('\n'),
        isNot(contains('skip body log: compressed content-encoding=gzip')),
      );
    });
  });

  group('InterceptorTimeout tests', () {
    test('wraps plain Request into AbortableRequest with abortTrigger',
        () async {
      final interceptor = InterceptorTimeout(Duration(milliseconds: 100));
      final request = Request('GET', Uri.parse('https://example.com/test'));
      final intercepted =
          await interceptor.interceptRequest(request: request);

      expect(intercepted, isA<AbortableRequest>());
      final abortable = intercepted as AbortableRequest;
      expect(abortable.abortTrigger, isNotNull);
    });

    test('triggers onTimeout callback and logger warning when timeout expires',
        () async {
      final logger = Logger('test.timeout');
      final logMessages = <String>[];
      final sub = Logger.root.onRecord.listen((e) => logMessages.add(e.message));

      BaseRequest? timedOutRequest;
      final interceptor = InterceptorTimeout(
        Duration(milliseconds: 30),
        logger: logger,
        onTimeout: (req) {
          timedOutRequest = req;
        },
      );

      final request = Request('POST', Uri.parse('https://example.com/api'));
      final intercepted =
          await interceptor.interceptRequest(request: request);

      expect(intercepted, isA<AbortableRequest>());
      final abortable = intercepted as AbortableRequest;

      // Wait for abortTrigger to complete
      await abortable.abortTrigger;
      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(timedOutRequest, equals(request));
      expect(
        logMessages.join('\n'),
        contains('request timed out after 30ms and was aborted'),
      );

      await sub.cancel();
    });

    test('cancels timeout timer when response is intercepted in time',
        () async {
      var timeoutCalled = false;
      final interceptor = InterceptorTimeout(
        Duration(milliseconds: 50),
        onTimeout: (_) {
          timeoutCalled = true;
        },
      );

      final request = Request('GET', Uri.parse('https://example.com/fast'));
      final intercepted =
          await interceptor.interceptRequest(request: request);

      final response = Response('ok', 200, request: intercepted);
      await interceptor.interceptResponse(response: response);

      // Wait past timeout duration
      await Future<void>.delayed(Duration(milliseconds: 80));

      expect(timeoutCalled, isFalse);
    });

    test('does not overwrite existing custom abortTrigger', () async {
      final customCompleter = Completer<void>();
      final customRequest = AbortableRequest(
        'GET',
        Uri.parse('https://example.com/custom'),
        abortTrigger: customCompleter.future,
      );

      final interceptor = InterceptorTimeout(Duration(seconds: 10));
      final intercepted =
          await interceptor.interceptRequest(request: customRequest);

      expect(identical(intercepted, customRequest), isTrue);
      expect((intercepted as AbortableRequest).abortTrigger,
          equals(customCompleter.future));
    });
  });
}
