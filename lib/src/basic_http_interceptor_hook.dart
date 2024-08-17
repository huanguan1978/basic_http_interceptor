part of '../../basic_http_interceptor.dart';

/// Hook, handle request, handle response
class InterceptorHook extends InterceptorContract {
  /// handle request
  final BaseRequest Function(BaseRequest) _requestHook;

  /// handle response
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
