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
    final buf = StringBuffer();

    buf.writeln('- interceptResponse, begin, $ts');
    buf.writeln(response.statusCode);
    buf.writeln(response.headers.toString());

    final contentType = response.headers['content-type'];
    final contentLength = response.contentLength;
    final shouldProcessBody =
        (logBody || response.headers.containsKey('X-Debug-Body')) &&
            _isTextualContentType(contentType) &&
            (contentLength == null || contentLength <= logBodyMax);

    if (shouldProcessBody) {
      if (response is Response) {
        buf.writeln(response.body);
      }
      if (response is StreamedResponse) {
        response = await _logStreamedResponseBody(response, buf);
      }
    }

    buf.writeln('- interceptResponse, end.');

    _logger.info(buf);
    buf.clear();
    return response;
  }

  Future<StreamedResponse> _logStreamedResponseBody(
    StreamedResponse response,
    StringBuffer buf,
  ) async {
    final bodyBytes = await response.stream.toBytes();
    final bodyText = utf8.decode(bodyBytes, allowMalformed: true);
    buf.writeln(bodyText);

    return response.copyWith(
      stream: Stream.value(bodyBytes),
    );
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
