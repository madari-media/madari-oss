import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/settings/service/selected_profile.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../widgetter/plugin_layout.dart';
import '../../widgetter/state/widget_state_provider.dart';

class HomePage extends StatefulWidget {
  final bool hasSearch;
  final bool isExplore;

  const HomePage({
    super.key,
    this.hasSearch = false,
    this.isExplore = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _state = GlobalKey<LayoutManagerState>();

  late StreamSubscription<String?> _selectedProfile;

  Widget _buildLogo() {
    return Image.asset(
      'assets/icon/icon_mini.png',
      height: 32,
      fit: BoxFit.contain,
    );
  }

  @override
  void initState() {
    _selectedProfile =
        SelectedProfileService.instance.selectedProfileStream.listen((data) {
      _state.currentState?.refresh();
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _selectedProfile.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            _buildLogo(),
            const SizedBox(
              width: 12,
            ),
            const Text('Madari'),
          ],
        ),
        actions: [
          if (UniversalPlatform.isDesktop)
            IconButton(
              onPressed: () {
                _state.currentState?.refresh();
              },
              icon: const Icon(Icons.refresh),
            ),
          IconButton(
            onPressed: () {
              context.push("/downloads");
            },
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: LayoutManager(
        key: _state,
        hasSearch: widget.hasSearch,
      ),
    );
  }
}

class SearchBox extends StatefulWidget {
  final String? hintText;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const SearchBox({
    super.key,
    this.hintText,
    this.padding,
    this.height,
  });

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StateProvider>();
      _controller.text = provider.search;
    });
  }

  void _onSearchChanged(String value, StateProvider provider) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      provider.setSearch(value);
    });
  }

  void _clearSearch(StateProvider provider) {
    _controller.clear();
    provider.setSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Consumer<StateProvider>(
        builder: (context, provider, _) {
          return SearchBar(
            controller: _controller,
            hintText: widget.hintText ?? 'Search...',
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) => _onSearchChanged(value, provider),
            leading: Icon(
              Icons.search,
              color: colorScheme.onSurfaceVariant,
            ),
            trailing: [
              if (provider.search.trim() != "")
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _clearSearch(provider),
                ),
            ],
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            constraints: BoxConstraints.tightFor(
              height: widget.height ?? 46,
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          );
        },
      ),
    );
  }
}
