String? domainOf(Uri? url) {
  final host = url?.host;
  if (host == null || host.isEmpty) return null;
  return host.startsWith('www.') ? host.substring(4) : host;
}
