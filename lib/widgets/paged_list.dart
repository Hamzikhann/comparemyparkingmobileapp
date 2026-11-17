import 'package:flutter/material.dart';

/// One page of results from the server.
class PageResult<T> {
  final List<T> items;
  final int total;
  const PageResult(this.items, this.total);
}

typedef PageFetcher<T> = Future<PageResult<T>> Function(int offset, int limit);

/// Infinite-scroll list: loads [pageSize] items, then the next page when the
/// user nears the bottom. Pull down to refresh. Give it a new [key] (e.g. from
/// the search text and filters) to start again from the first page.
class PagedList<T> extends StatefulWidget {
  final PageFetcher<T> fetch;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final String emptyText;
  final EdgeInsetsGeometry padding;

  /// Optional line above the list, e.g. "1,240 bookings".
  final Widget Function(int total)? header;

  const PagedList({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.pageSize = 20,
    this.emptyText = 'Nothing found',
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.header,
  });

  @override
  State<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends State<PagedList<T>> {
  final _items = <T>[];
  final _scroll = ScrollController();
  int _total = 0;
  bool _loading = false;
  bool _firstLoadDone = false;
  bool _reachedEnd = false; // set only by a successful page
  String? _error;
  int _generation = 0; // ignores answers to requests made before a refresh

  bool get _hasMore => !_reachedEnd;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadNext();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _loadNext();
  }

  Future<void> _loadNext() async {
    if (_loading || _reachedEnd || _error != null) return;
    final gen = _generation;
    setState(() => _loading = true);
    try {
      final page = await widget.fetch(_items.length, widget.pageSize);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        // A short page means the server has nothing more, whatever total says
        if (page.items.length < widget.pageSize) _total = _items.length;
        _reachedEnd = _items.length >= _total;
        _firstLoadDone = true;
      });
      // A first page that doesn't fill the screen: fetch more straight away
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients &&
            _scroll.position.maxScrollExtent <= 0 && _hasMore) {
          _loadNext();
        }
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e.toString();
        _firstLoadDone = true;
      });
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    _generation++;
    setState(() {
      _items.clear();
      _total = 0;
      _error = null;
      _firstLoadDone = false;
      _reachedEnd = false;
      _loading = false;
    });
    await _loadNext();
  }

  void _retry() {
    setState(() => _error = null);
    _loadNext();
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstLoadDone && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  Text(_error ?? widget.emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _error != null
                              ? Colors.red.shade700
                              : Colors.grey.shade600)),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ]),
              ),
            ),
          ],
        ),
      );
    }

    final hasHeader = widget.header != null;
    final footerCount = 1;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: (hasHeader ? 1 : 0) + _items.length + footerCount,
        itemBuilder: (context, i) {
          if (hasHeader) {
            if (i == 0) return widget.header!(_total);
            i -= 1;
          }
          if (i < _items.length) return widget.itemBuilder(context, _items[i], i);
          // Footer: spinner while loading, retry on error, end marker otherwise
          if (_error != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                TextButton(onPressed: _retry, child: const Text('Retry')),
              ]),
            );
          }
          if (_hasMore || _loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5))),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('No more results',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }
}
