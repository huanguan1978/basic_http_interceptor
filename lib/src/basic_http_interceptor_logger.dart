part of '../basic_http_interceptor.dart';

/// Logger, request info, response info
class InterceptorLogger extends InterceptorContract {
  final Logger _logger;

  /// Whether request and response bodies should be logged by default.
  ///
  /// When this is `false`, body logging can still be enabled per message with
  /// the `X-Debug-Body` header.
  bool logBody = false;

  /// Maximum number of response body bytes to buffer for logging.
  ///
  /// This limit is applied when logging [StreamedResponse] bodies so the
  /// interceptor does not retain arbitrarily large payloads in memory.
  int logBodyMax = 2 * 1024 * 1024;

  InterceptorLogger(
    this._logger, [
    this.logBody = false,
    this.logBodyMax = 2 * 1024 * 1024,
  ]);

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    final ts = DateTime.now().toLocal().millisecondsSinceEpoch;
    final buf = StringBuffer();

    buf.writeln('- interceptRequest, begin, $ts');
    buf.writeln(request.headers.toString());
    buf.writeln(request.toString()); // $method $url
    if (request is Request) {
      buf.writeln('contentLength:${request.contentLength}');
      if (logBody || request.headers.containsKey('X-Debug-Body')) {
        buf.writeln(request.body);
      }
    }
    buf.writeln('- interceptRequest, end.');

    _logger.info(buf);
    buf.clear();
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final ts = DateTime.now().toLocal().millisecondsSinceEpoch;
    final metaBuf = StringBuffer();

    metaBuf.writeln('- interceptResponse, begin, $ts');
    metaBuf.writeln(response.statusCode);
    metaBuf.writeln(response.headers.toString());

    final contentType = response.headers['content-type'];
    final shouldProcessBody =
        (logBody || response.headers.containsKey('X-Debug-Body')) &&
            _isTextualContentType(contentType);

    if (shouldProcessBody) {
      _logger.info(metaBuf);
      metaBuf.clear();

      if (response is Response) {
        final responseBuf = StringBuffer()
          ..writeln('- interceptResponse, body, $ts')
          ..writeln(response.body)
          ..writeln('- interceptResponse, end.');
        _logger.info(responseBuf);
        return response;
      }

      if (response is StreamedResponse) {
        return _logStreamedResponseBody(response, ts);
      }
    }

    metaBuf.writeln('- interceptResponse, end.');

    _logger.info(metaBuf);
    metaBuf.clear();
    return response;
  }

  StreamedResponse _logStreamedResponseBody(
    StreamedResponse response,
    int ts,
  ) {
    final bodyBuffer = BytesBuilder(copy: false);
    var bufferedBytes = 0;
    var segmentIndex = 0;

    void flushBufferedSegment({bool finalSegment = false}) {
      if (bufferedBytes == 0) {
        return;
      }

      segmentIndex++;
      final segmentText = utf8.decode(
        bodyBuffer.takeBytes(),
        allowMalformed: true,
      );
      final segmentBuf = StringBuffer();
      segmentBuf
          .writeln('- interceptResponse, body segment $segmentIndex, $ts');
      if (finalSegment) {
        segmentBuf.writeln('- interceptResponse, final segment.');
      }
      segmentBuf.writeln(segmentText);
      _logger.info(segmentBuf);
      bufferedBytes = 0;
    }

    int appendBytes(List<int> bytes) {
      var offset = 0;

      while (offset < bytes.length) {
        if (logBodyMax <= 0) {
          bodyBuffer.add(bytes.sublist(offset));
          bufferedBytes += bytes.length - offset;
          flushBufferedSegment();
          return 0;
        }

        final remainingCapacity = logBodyMax - bufferedBytes;
        final chunkLength = remainingCapacity < bytes.length - offset
            ? remainingCapacity
            : bytes.length - offset;

        bodyBuffer.add(bytes.sublist(offset, offset + chunkLength));
        bufferedBytes += chunkLength;
        offset += chunkLength;

        if (bufferedBytes >= logBodyMax) {
          flushBufferedSegment();
        }
      }

      return bufferedBytes;
    }

    final transformedStream = response.stream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          appendBytes(chunk);
          sink.add(chunk);
        },
        handleError: (Object error, StackTrace stackTrace, sink) {
          flushBufferedSegment(finalSegment: true);
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) {
          flushBufferedSegment(finalSegment: true);
          final endBuf = StringBuffer()..writeln('- interceptResponse, end.');
          _logger.info(endBuf);
          sink.close();
        },
      ),
    );

    return response.copyWith(stream: transformedStream);
  }

  bool _isTextualContentType(String? contentType) {
    if (contentType == null) return false;

    final normalized = contentType.toLowerCase();
    return normalized.startsWith('text/') ||
        normalized.contains('json') ||
        normalized.contains('xml') ||
        normalized.contains('javascript') ||
        normalized.contains('x-www-form-urlencoded');
  }

  // cls_lastline
}
