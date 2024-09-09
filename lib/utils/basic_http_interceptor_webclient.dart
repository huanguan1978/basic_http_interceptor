import 'package:http_interceptor/http_interceptor.dart'
    show InterceptorContract, InterceptedClient;

/// get InterceptedClient
InterceptedClient interceptedClient({
  required List<InterceptorContract> interceptors,
  Map<String, String> proxy = const {},
}) {
  return InterceptedClient.build(
    interceptors: interceptors,
  );
}
