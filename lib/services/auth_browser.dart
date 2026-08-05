// Platform-specific browser access for the OIDC redirect flow.
//
// The web implementation drives real browser navigation + localStorage; the
// stub keeps things compiling (and the app usable minus login) on other
// platforms, where a native flow (e.g. flutter_appauth) would be plugged in.
export 'auth_browser_stub.dart'
    if (dart.library.js_interop) 'auth_browser_web.dart';
