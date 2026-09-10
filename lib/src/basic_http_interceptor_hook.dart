part of '../basic_http_interceptor.dart';

/// An interceptor that transforms requests and responses using custom callback functions.
///
/// Example:
/// ```dart
/// final client = interceptedClient(
///   interceptors: [
///     InterceptorHook(
///       requestHook: (request) {
///         request.headers['X-Timestamp'] = DateTime.now().toIso8601String();
///         return request;
///       },
///       responseHook: (response) {
///         return response;
///       },
///     ),
///   ],
/// );
/// ```
class InterceptorHook extends InterceptorContract {
  /// Callback to inspect or modify the outgoing request.
  final BaseRequest Function(BaseRequest) _requestHook;

  /// Callback to inspect or modify the incoming response.
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
