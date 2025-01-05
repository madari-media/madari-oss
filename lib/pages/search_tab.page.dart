import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../features/connections/service/base_connection_service.dart';
import '../features/connections/types/base/base.dart';
import 'home_tab.page.dart';

class SearchPage extends StatefulWidget {
  static String get routeName => "/search";

  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearchFocused = false;
  String _debouncedSearchTerm = '';
  LibraryRecordResponse? searchLibrariesList;

  @override
  void initState() {
    super.initState();

    loadLibrariesWhichSupportSearch();
  }

  loadLibrariesWhichSupportSearch() async {
    final library =
        await AppEngine.engine.pb.collection("library").getFullList();

    final record = library
        .map(
      (item) => LibraryRecord.fromRecord(item),
    )
        .where((item) {
      return item.connectionType == "stremio_addons";
    }).toList();

    final List<LibraryRecord> records = [];

    for (final item in record) {
      final result =
          await BaseConnectionService.connectionByIdRaw(item.connection);

      final service = BaseConnectionService.connectionById(result);

      final filters = await service.getFilters(item);

      final hasFilter = filters.where((item) {
        return item.title == "search";
      }).isNotEmpty;

      if (hasFilter) {
        records.add(item);
        if (mounted) {
          searchLibrariesList = LibraryRecordResponse(
            data: records,
          );

          setState(() {});
        }
      }
    }

    searchLibrariesList = LibraryRecordResponse(
      data: records,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _debouncedSearchTerm = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 76),
        child: Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 18,
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        _isSearchFocused ? Colors.grey[800] : Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      setState(() => _isSearchFocused = hasFocus);
                    },
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for videos, PDFs, or images...',
                        prefixIcon: const Icon(
                          Icons.search,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                color: Colors.grey[400],
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _debouncedSearchTerm = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        child: _buildBody(),
        onRefresh: () {
          return loadLibrariesWhichSupportSearch();
        },
      ),
    );
  }

  Widget _buildBody() {
    return _debouncedSearchTerm.isEmpty
        ? Center(
            child: _buildEmptyState(),
          )
        : HomeTabPage(
            hideAppBar: true,
            search: _debouncedSearchTerm,
            defaultLibraries: searchLibrariesList,
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'Search for your favorite content',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
