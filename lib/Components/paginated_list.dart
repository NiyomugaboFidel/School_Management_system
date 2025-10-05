import 'package:flutter/material.dart';

/// Paginated List Widget
/// Provides efficient pagination with lazy loading
/// Automatically handles loading states and errors
class PaginatedListView<T> extends StatefulWidget {
  final Future<PaginatedResult<T>> Function(int page) fetchPage;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? separator;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final int pageSize;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const PaginatedListView({
    Key? key,
    required this.fetchPage,
    required this.itemBuilder,
    this.separator,
    this.emptyWidget,
    this.errorWidget,
    this.pageSize = 20,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadPage();
      }
    }
  }

  Future<void> _loadPage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.fetchPage(_currentPage);

      setState(() {
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        _currentPage++;
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
      _error = null;
      _isInitialLoad = true;
    });
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    // Initial loading state
    if (_isInitialLoad && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          );
    }

    // Empty state
    if (_items.isEmpty) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    // List with items
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder:
            (context, index) => widget.separator ?? const SizedBox.shrink(),
        itemBuilder: (context, index) {
          // Loading indicator at the end
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}

/// Paginated Result Model
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  }) : hasMore = (currentPage * pageSize) < totalCount;

  int get totalPages => (totalCount / pageSize).ceil();
}

/// Grid version of paginated list
class PaginatedGridView<T> extends StatefulWidget {
  final Future<PaginatedResult<T>> Function(int page) fetchPage;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final int pageSize;

  const PaginatedGridView({
    Key? key,
    required this.fetchPage,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 1,
    this.emptyWidget,
    this.errorWidget,
    this.pageSize = 20,
  }) : super(key: key);

  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadPage();
      }
    }
  }

  Future<void> _loadPage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.fetchPage(_currentPage);

      setState(() {
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        _currentPage++;
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
      _error = null;
      _isInitialLoad = true;
    });
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          );
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
          childAspectRatio: widget.childAspectRatio,
        ),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}
