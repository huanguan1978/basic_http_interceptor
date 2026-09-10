part of '../basic_http_interceptor.dart';

typedef TimeoutCallback = void Function(BaseRequest request);

/// An interceptor that enforces a physical connection timeout on HTTP requests using `Abortable`.
///
/// When the timeout duration elapses before the response arrives:
/// - The underlying socket/HTTP connection is aborted immediately.
/// - A warning is recorded to [logger] if provided.
/// - An [onTimeout] callback is invoked if provided.
///
/// Example:
/// ```dart
/// final client = interceptedClient(
///   interceptors: [
///     InterceptorTimeout(
///       Duration(seconds: 10),
///       logger: logger,
///       onTimeout: (request) {
///         print('Request timed out: ${request.method} ${request.url}');
///       },
///     ),
///   ],
/// );
/// ```
class InterceptorTimeout extends InterceptorContract {
  /// The maximum duration to wait for a request/response before aborting.
  final Duration timeout;

  /// Optional logger to record timeout abort warnings.
  final Logger? logger;

  /// Optional callback invoked when a request times out and is aborted.
  final TimeoutCallback? onTimeout;

  final Expando<Timer> _timers = Expando<Timer>('InterceptorTimeout_timers');

  InterceptorTimeout(
    this.timeout, {
    this.logger,
    this.onTimeout,
  });

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    if (timeout <= Duration.zero) {
      return request;
    }

    if (request case Abortable(:final abortTrigger) when abortTrigger != null) {
      return request;
    }

    final completer = Completer<void>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete();
        _handleTimeout(request);
      }
    });

    final abortableRequest = _wrapWithAbortTrigger(request, completer.future);
    _timers[abortableRequest] = timer;
    return abortableRequest;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final req = response.request;
    if (req != null) {
      _timers[req]?.cancel();
    }
    return response;
  }

  void _handleTimeout(BaseRequest request) {
    logger?.warning(
      '- InterceptorTimeout: request timed out after ${timeout.inMilliseconds}ms and was aborted (${request.method} ${request.url})',
    );
    if (onTimeout != null) {
      try {
        onTimeout!(request);
      } catch (e, st) {
        logger?.severe(
          '- InterceptorTimeout: error in onTimeout callback: $e',
          e,
          st,
        );
      }
    }
  }

  BaseRequest _wrapWithAbortTrigger(
    BaseRequest request,
    Future<void> abortTrigger,
  ) {
    if (request is Request) {
      final abortable = AbortableRequest(
        request.method,
        request.url,
        abortTrigger: abortTrigger,
      )
        ..headers.addAll(request.headers)
        ..maxRedirects = request.maxRedirects
        ..followRedirects = request.followRedirects
        ..persistentConnection = request.persistentConnection
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;
      return abortable;
    }

    if (request is MultipartRequest) {
      final abortable = AbortableMultipartRequest(
        request.method,
        request.url,
        abortTrigger: abortTrigger,
      )
        ..headers.addAll(request.headers)
        ..maxRedirects = request.maxRedirects
        ..followRedirects = request.followRedirects
        ..persistentConnection = request.persistentConnection
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
      return abortable;
    }

    return request;
  }
}
