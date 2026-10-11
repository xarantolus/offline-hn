enum FilterListUrlProblem { notAnAddress, notWeb, alreadyListed }

/// The address to store for what was typed, or why it cannot be one.
({String? url, FilterListUrlProblem? problem}) checkFilterListUrl(
  String typed,
  Iterable<String> existing,
) {
  final uri = Uri.tryParse(typed.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return (url: null, problem: FilterListUrlProblem.notAnAddress);
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return (url: null, problem: FilterListUrlProblem.notWeb);
  }
  final url = uri.toString();
  if (existing.contains(url)) {
    return (url: null, problem: FilterListUrlProblem.alreadyListed);
  }
  return (url: url, problem: null);
}
