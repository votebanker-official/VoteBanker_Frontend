String browserOrigin() => '';

Uri browserLocation() => Uri.base;

String? takeSessionValue(String key) => null;

void saveSessionValue(String key, String value) {}

void redirectBrowser(String url) {
  throw UnsupportedError('Social sign-in opens in the browser.');
}

void replaceBrowserPath(String path) {}

void clearAuthQuery() {}
