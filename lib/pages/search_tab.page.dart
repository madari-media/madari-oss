import 'dart:async';

import 'package:flutter/material.dart';

import 'home_tab.page.dart';

class SearchPage extends StatefulWidget {
  static String get routeName => "/search";

  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  Timer? _debounceTimer;
  bool _isSearchFocused = false;
  final List<String> _filterOptions = ['All', 'Videos', 'PDFs', 'Images'];
  String _debouncedSearchTerm = '';

  @override
  void initState() {
    super.initState();
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
        preferredSize: const Size(double.infinity, 114),
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
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterOptions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filterOptions[index];
                      final isSelected = _selectedFilter == filter;
                      return FilterChip(
                        label: Text(
                          filter,
                        ),
                        visualDensity: VisualDensity.compact,
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (bool selected) {
                          setState(() => _selectedFilter = filter);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _debouncedSearchTerm.isEmpty
          ? Center(
              child: _buildEmptyState(),
            )
          : HomeTabPage(
              hideAppBar: true,
              search: _debouncedSearchTerm,
            ),
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

  Widget _buildSearchResults() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1200
              ? 5
              : MediaQuery.of(context).size.width > 800
                  ? 4
                  : MediaQuery.of(context).size.width > 600
                      ? 3
                      : 2,
          childAspectRatio: 16 / 9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 200,
        ),
        itemBuilder: (context, index) => _buildResultCard(index),
        itemCount: 20,
      ),
    );
  }

  Widget _buildResultCard(int index) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Icon(
                    _selectedFilter == 'PDFs'
                        ? Icons.picture_as_pdf
                        : _selectedFilter == 'Videos'
                            ? Icons.play_circle_filled
                            : Icons.image,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Title ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '2024 • Category',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
