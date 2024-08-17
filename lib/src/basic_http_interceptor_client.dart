part of '../../basic_http_interceptor.dart';

/// 按需生成HTTP拦截客户端
InterceptedClient interceptedClient({
  required List<InterceptorContract> interceptors,
  Map<String, String> proxy = const {},
  bool isWeb = false,
}) {
  Client? proxyClient;
  if (proxy.isNotEmpty && !isWeb) {
    proxyClient = IOClient(
      HttpClient()
        ..findProxy = (url) {
          return HttpClient.findProxyFromEnvironment(url, environment: proxy);
        },
    );
  }

  return InterceptedClient.build(
    interceptors: interceptors,
    client: proxyClient,
  );
}
