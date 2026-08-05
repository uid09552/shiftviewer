/// Non-web fallback. The redirect-based flow can't run here, so [redirect]
/// throws; storage is kept in-memory so token restore/refresh code still runs
/// without crashing. Native platforms should replace this with an AppAuth flow.
class AuthBrowser {
  AuthBrowser();

  final Map<String, String> _mem = {};

  bool get isSupported => false;

  Uri currentUri() => Uri.parse('');

  void redirect(String url) => throw UnsupportedError(
      'OIDC redirect login is only implemented for web in this build.');

  void replaceUrl(String path) {}

  String? storageGet(String key) => _mem[key];

  void storageSet(String key, String value) => _mem[key] = value;

  void storageRemove(String key) => _mem.remove(key);
}
