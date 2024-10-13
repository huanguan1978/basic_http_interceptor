part of '../../basic_http_interceptor.dart';

class InterceptorLogger extends InterceptorContract {
  final Logger _logger;
  bool logBody = false;
  InterceptorLogger(this._logger, [this.logBody = false]);

  @override

  /// Logger, request info, response info
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    _logger
        .info('- interceptRequest, begin, ${DateTime.now().toIso8601String()}');
    _logger.info(request.headers.toString());
    _logger.info(request.toString()); // $method $url
    if (request is Request) {
      _logger.info('contentLength:${request.contentLength}');
      if (logBody || request.headers.containsKey('X-Debug-Body')) {
        _logger.info(request.body);
      }
    }
    _logger.info('- interceptRequest, end.');
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    _logger.info(
        '- interceptResponse, begin, ${DateTime.now().toIso8601String()}');
    _logger.info(response.statusCode);
    _logger.info(response.headers.toString());

    if (response is Response) {
      if (logBody || response.headers.containsKey('X-Debug-Body')) {
        _logger.info(response.body);
      }
    }
    _logger.info('- interceptResponse, end.');
    return response;
  }
}
