part of '../basic_http_interceptor.dart';

/// An interceptor that attaches a predefined set of HTTP headers to every outgoing request.
///
/// Example:
/// ```dart
/// final client = interceptedClient(
///   interceptors: [
///     InterceptorHeader(requestHeader: {
///       'Authorization': 'Bearer $jwtToken',
///       'Accept': 'application/json',
///     }),
///   ],
/// );
/// ```
class InterceptorHeader extends InterceptorContract {
  /// The headers to attach to each outgoing request.
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
