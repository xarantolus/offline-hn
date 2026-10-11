import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/app_services_scope.dart';
import 'package:offline_hn/data/model/filter_list_status.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/policy/filter_list_url.dart';
import 'package:offline_hn/pages/settings/update_lists_tile.dart';
import 'package:offline_hn/ui/format.dart';
import 'package:offline_hn/ui/settings_section.dart';
import 'package:offline_hn/ui/tokens.dart';
import 'package:page_capture/filters.dart';

class FilterListsPage extends StatefulWidget {
  const FilterListsPage({super.key});

  @override
  State<FilterListsPage> createState() => _FilterListsPageState();
}

class _FilterListsPageState extends State<FilterListsPage> {
  late final AppServices _services = AppServicesScope.of(context);
  late final Stream<AppSettings> _settings = _services.settings.watch();

  Future<void> _add(List<String> current) async {
    final url = await showDialog<String>(
      context: context,
      builder: (_) => _AddListDialog(existing: current),
    );
    if (url == null) return;
    await _services.settings.set(Settings.filterListUrls, [...current, url]);
  }

  Future<void> _remove(List<String> current, String url) =>
      _services.settings.set(Settings.filterListUrls, [
        for (final u in current)
          if (u != url) u,
      ]);

  Future<void> _reset() => _services.settings.reset(Settings.filterListUrls);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filter lists')),
      body: StreamBuilder<AppSettings>(
        stream: _settings,
        builder: (context, snapshot) {
          final settings = snapshot.data;
          if (settings == null) return const SizedBox.shrink();
          final urls = settings.filterListUrls;
          return ListView(
            padding: EdgeInsets.only(
              top: Spacing.lg,
              bottom: MediaQuery.viewPaddingOf(context).bottom + Spacing.lg,
            ),
            children: [
              SettingsSection(
                title: 'Lists',
                children: [
                  if (urls.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(Spacing.gutter),
                      child: Text(
                        'No lists. Pages are saved without ad or tracker '
                        'blocking.',
                        style: context.tokens.hint,
                      ),
                    ),
                  for (final url in urls)
                    _ListTile(
                      url: url,
                      status: settings.filterListStatus[url],
                      onRemove: () => _remove(urls, url),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.xl),
              SettingsSection(
                title: 'Manage',
                children: [
                  ListTile(
                    title: Text('Add a list', style: context.tokens.label),
                    trailing: const Icon(Icons.add),
                    onTap: () => _add(urls),
                  ),
                  ListTile(
                    title: Text(
                      'Reset to defaults',
                      style: context.tokens.label,
                    ),
                    trailing: const Icon(Icons.restore),
                    onTap: _reset,
                  ),
                  UpdateListsTile(services: _services),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.url,
    required this.status,
    required this.onRemove,
  });

  final String url;
  final FilterListStatus? status;
  final VoidCallback onRemove;

  String _summary(BuildContext context) {
    final updated = status?.updatedAt;
    if (updated == null) return 'Not downloaded yet';
    final l10n = MaterialLocalizations.of(context);
    final rules = status!.networkRules + status!.cosmeticRules;
    return 'Updated ${l10n.formatMediumDate(updated.toLocal())} · '
        '${pluralize(rules, 'rule')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final error = status?.error;
    return ListTile(
      title: Text(url, style: t.label.copyWith(fontSize: 14), maxLines: 2),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_summary(context), style: t.hint),
          if (error != null)
            Text(
              'Last attempt failed: $error',
              style: t.hint.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Remove',
        icon: const Icon(Icons.delete_outline),
        onPressed: onRemove,
      ),
    );
  }
}

class _AddListDialog extends StatefulWidget {
  const _AddListDialog({required this.existing});

  final List<String> existing;

  @override
  State<_AddListDialog> createState() => _AddListDialogState();
}

class _AddListDialogState extends State<_AddListDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final checked = checkFilterListUrl(_controller.text, widget.existing);
    final url = checked.url;
    if (url != null) {
      Navigator.of(context).pop(url);
      return;
    }
    setState(() {
      _error = switch (checked.problem) {
        FilterListUrlProblem.notAnAddress => 'That is not an address',
        FilterListUrlProblem.notWeb => 'Use an http or https address',
        FilterListUrlProblem.alreadyListed => 'That list is already added',
        null => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a filter list'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          hintText: FilterSources.defaultLists.first,
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
