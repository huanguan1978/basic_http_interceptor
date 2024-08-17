part of '../../basic_http_interceptor.dart';

class InterceptorHook extends InterceptorContract {
  final BaseRequest Function(BaseRequest) _requestHook;
  final BaseResponse Function(BaseResponse) _responseHook;

  InterceptorHook(
      {required BaseRequest Function(BaseRequest) requestHook,
      required BaseResponse Function(BaseResponse) responseHook})
      : _requestHook = requestHook,
        _responseHook = responseHook;

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    return _requestHook(request);
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    return _responseHook(response);
  }
}
