part of '../../basic_http_interceptor.dart';

class InterceptorLogger extends InterceptorContract {
  final Logger _logger;

  InterceptorLogger(this._logger);

  @override
  /// Logger, request info, response info
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    _logger.info('- interceptRequest, ${DateTime.now().toIso8601String()}');
    _logger.info(request.headers.toString());
    _logger.info(request.toString());
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    _logger.info('- interceptResponse, ${DateTime.now().toIso8601String()}');
    _logger.info(response.statusCode);
    _logger.info(response.headers.toString());

    if (response is Response) {
      _logger.info((response).body);
    }
    return response;
  }
}
