String? domainOf(String? url) {
  if (url == null) return null;
  final host = Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) return null;
  return host.startsWith('www.') ? host.substring(4) : host;
}
