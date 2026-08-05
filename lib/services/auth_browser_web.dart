import 'package:web/web.dart' as web;

/// Web implementation backed by `window.location`, `localStorage` and
/// `history`.
class AuthBrowser {
  const AuthBrowser();

  bool get isSupported => true;

  /// The current page URL, used to detect the OIDC callback query params.
  Uri currentUri() => Uri.parse(web.window.location.href);

  /// Full-page navigation to the authorization endpoint.
  void redirect(String url) {
    web.window.location.href = url;
  }

  /// Replaces the current history entry (strips `?code=...&state=...` after the
  /// callback so a reload doesn't re-trigger the exchange).
  void replaceUrl(String path) {
    web.window.history.replaceState(null, '', path);
  }

  String? storageGet(String key) => web.window.localStorage.getItem(key);

  void storageSet(String key, String value) =>
      web.window.localStorage.setItem(key, value);

  void storageRemove(String key) => web.window.localStorage.removeItem(key);
}
