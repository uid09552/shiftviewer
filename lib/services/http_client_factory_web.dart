import 'package:http/http.dart' as http;

/// Web: the browser's TLS stack handles the certificate chain (including AIA
/// fetching of missing intermediates), so the default client is fine.
http.Client createHttpClient() => http.Client();
