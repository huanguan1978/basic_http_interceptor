part of '../../basic_http_interceptor.dart';

/// get InterceptedClient
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
