part of '../../basic_http_interceptor.dart';

/// Header Manipulation
class InterceptorHeader extends InterceptorContract {
  /// request header
  final Map<String, String> requestHeader;

  InterceptorHeader({required this.requestHeader});

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    if (requestHeader.isNotEmpty) {
      request.headers.addAll(requestHeader);
    }

    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    return response;
  }
}
