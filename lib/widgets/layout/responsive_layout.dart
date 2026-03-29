import 'package:flutter/material.dart';
import 'resizable_sidebar.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget content;
  final Widget? detailPanel;
  final bool showDetailPanel;

  const ResponsiveLayout({
    super.key,
    required this.sidebar,
    required this.content,
    this.detailPanel,
    this.showDetailPanel = false,
  });

  static const double kCompact = 600;
  static const double kExpanded = 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < kCompact) {
          return _CompactLayout(
            sidebar: sidebar,
            content: content,
            detailPanel: detailPanel,
            showDetailPanel: showDetailPanel,
          );
        }

        if (width < kExpanded) {
          return _MediumLayout(
            sidebar: sidebar,
            content: content,
            detailPanel: detailPanel,
            showDetailPanel: showDetailPanel,
          );
        }

        return _ExpandedLayout(
          sidebar: sidebar,
          content: content,
          detailPanel: detailPanel,
          showDetailPanel: showDetailPanel,
        );
      },
    );
  }
}

// ── COMPACT: drawer sidebar, modal detail panel ──────────────────────────────
class _CompactLayout extends StatelessWidget {
  final Widget sidebar, content;
  final Widget? detailPanel;
  final bool showDetailPanel;

  const _CompactLayout({
    required this.sidebar,
    required this.content,
    this.detailPanel,
    required this.showDetailPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(width: 260, child: sidebar),
      body: Stack(
        children: [
          content,
          if (showDetailPanel && detailPanel != null)
            _ModalDetailSheet(child: detailPanel!),
        ],
      ),
    );
  }
}

// ── MEDIUM: fixed sidebar + content, overlay detail panel ────────────────────
class _MediumLayout extends StatelessWidget {
  final Widget sidebar, content;
  final Widget? detailPanel;
  final bool showDetailPanel;

  const _MediumLayout({
    required this.sidebar,
    required this.content,
    this.detailPanel,
    required this.showDetailPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 220, child: sidebar),
          const VerticalDivider(width: 1),
          Expanded(
            child: Stack(
              children: [
                content,
                if (showDetailPanel && detailPanel != null)
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    width: 320,
                    child: Material(elevation: 8, child: detailPanel!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── EXPANDED: true three-column ──────────────────────────────────────────────
class _ExpandedLayout extends StatelessWidget {
  final Widget sidebar, content;
  final Widget? detailPanel;
  final bool showDetailPanel;

  const _ExpandedLayout({
    required this.sidebar,
    required this.content,
    this.detailPanel,
    required this.showDetailPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Row(
            children: [
              ResizableSidebar(child: sidebar),
              const VerticalDivider(width: 1),
              Expanded(child: content),
              if (showDetailPanel && detailPanel != null) ...[
                const VerticalDivider(width: 1),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: showDetailPanel ? 320 : 0,
                  child: ClipRect(child: detailPanel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Modal overlay for compact screens ────────────────────────────────────────
class _ModalDetailSheet extends StatelessWidget {
  final Widget child;
  const _ModalDetailSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Consume tap to prevent closing the modal detail sheet when clicking inside it
      child: Container(
        color: Colors.black45,
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Material(child: child),
          ),
        ),
      ),
    );
  }
}
