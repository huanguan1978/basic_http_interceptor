import 'dart:io' show HttpClient;
import 'package:http/io_client.dart' show IOClient;
import 'package:http_interceptor/http_interceptor.dart'
    show InterceptorContract, InterceptedClient, Client;

/// get InterceptedClient of IoClient with proxy
InterceptedClient interceptedClient({
  required List<InterceptorContract> interceptors,
  Map<String, String> proxy = const {},
}) {
  Client? proxyClient;
  if (proxy.isNotEmpty) {
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
