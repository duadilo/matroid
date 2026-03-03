import 'package:flutter/material.dart';

import 'charts_content.dart';
import 'latex_content.dart';
import 'markdown_content.dart';
import 'media_content.dart';

// ---------------------------------------------------------------------------
// ShowcaseContent — tabbed view combining Math, Markdown, Charts and Media
// ---------------------------------------------------------------------------

class ShowcaseContent extends StatefulWidget {
  const ShowcaseContent({super.key});

  @override
  State<ShowcaseContent> createState() => _ShowcaseContentState();
}

class _ShowcaseContentState extends State<ShowcaseContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ---- Tab bar -------------------------------------------------------
        Container(
          color: colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: colorScheme.outlineVariant,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.functions),            text: 'Math'),
              Tab(icon: Icon(Icons.article_outlined),     text: 'Markdown'),
              Tab(icon: Icon(Icons.bar_chart_outlined),   text: 'Charts'),
              Tab(icon: Icon(Icons.perm_media_outlined),  text: 'Media'),
            ],
          ),
        ),
        // ---- Content -------------------------------------------------------
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _KeepAlive(child: LatexContent()),
              _KeepAlive(child: MarkdownContent()),
              _KeepAlive(child: ChartsContent()),
              _KeepAlive(child: MediaContent()),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Keep-alive wrapper — preserves editor state when switching tabs
// ---------------------------------------------------------------------------

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
