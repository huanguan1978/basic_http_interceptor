part of '../../basic_http_interceptor.dart';

/// Logger, request info, response info
class InterceptorLogger extends InterceptorContract {
  final Logger _logger;
  bool logBody = false;
  InterceptorLogger(this._logger, [this.logBody = false]);

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
    if (response is Response) {
      if (logBody || response.headers.containsKey('X-Debug-Body')) {
        buf.writeln(response.body);
      }
    }
    buf.writeln('- interceptResponse, end.');

    _logger.info(buf);
    buf.clear();
    return response;
  }
}
