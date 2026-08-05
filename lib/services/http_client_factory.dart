// Returns the http.Client the API layer should use.
//
// On native platforms the server at portainer.mhmhkh.org serves only its leaf
// certificate (no intermediate), which dart:io's TLS stack can't chain to a
// trusted root. The io implementation supplies a SecurityContext that trusts
// the bundled intermediate as a workaround. On web the browser handles TLS, so
// the default client is used. Remove the workaround once the server serves the
// full chain.
export 'http_client_factory_web.dart'
    if (dart.library.io) 'http_client_factory_io.dart';
