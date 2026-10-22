import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../data/state_search.dart';

/// Closed state field that opens a searchable menu. The search box lives in
/// the menu, not on the profile form.
class SearchableStateField extends StatelessWidget {
  const SearchableStateField({
    required this.fieldKey,
    required this.hint,
    required this.icon,
    required this.value,
    required this.options,
    required this.enabled,
    required this.onChanged,
    required this.searchHint,
    required this.noResultsLabel,
    required this.clearSearchLabel,
    this.prepareOptions,
    this.searchFieldKey = const ValueKey('stateSearch'),
    this.clearButtonKey = const ValueKey('clearStateSearch'),
    this.emptyMessageKey = const ValueKey('noStatesFound'),
    this.listKey = const ValueKey('stateMenuList'),
    this.errorText,
    super.key,
  });

  final Key fieldKey;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> options;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String?> onChanged;
  final String searchHint;
  final String noResultsLabel;
  final String clearSearchLabel;
  final List<String> Function(List<String> options)? prepareOptions;
  final Key searchFieldKey;
  final Key clearButtonKey;
  final Key emptyMessageKey;
  final Key listKey;

  Future<void> _open(BuildContext context) async {
    final fieldBox = context.findRenderObject();
    final overlay = Navigator.of(context).overlay?.context.findRenderObject();
    if (fieldBox is! RenderBox ||
        !fieldBox.hasSize ||
        overlay is! RenderBox ||
        !overlay.hasSize) {
      return;
    }

    final anchor =
        fieldBox.localToGlobal(Offset.zero, ancestor: overlay) & fieldBox.size;
    final selected = await Navigator.of(context).push<String>(
      _StateMenuRoute(
        anchor: anchor,
        states: options,
        selected: value,
        searchHint: searchHint,
        noResultsLabel: noResultsLabel,
        clearSearchLabel: clearSearchLabel,
        prepareOptions: prepareOptions ?? prioritizeStates,
        searchFieldKey: searchFieldKey,
        clearButtonKey: clearButtonKey,
        emptyMessageKey: emptyMessageKey,
        listKey: listKey,
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
    );
    if (!context.mounted || selected == null) {
      return;
    }
    onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: fieldKey,
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? () => _open(context) : null,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            enabled: enabled,
            hintText: hint,
            errorText: errorText,
            prefixIcon: Icon(icon, color: palette.textMuted),
            suffixIcon: Icon(
              Icons.keyboard_arrow_down,
              color: palette.textMuted,
            ),
          ),
          child:
              value == null
                  ? const SizedBox.shrink()
                  : Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _StateMenuRoute extends PopupRoute<String> {
  _StateMenuRoute({
    required this.anchor,
    required this.states,
    required this.selected,
    required this.searchHint,
    required this.noResultsLabel,
    required this.clearSearchLabel,
    required this.prepareOptions,
    required this.searchFieldKey,
    required this.clearButtonKey,
    required this.emptyMessageKey,
    required this.listKey,
    required this.maxHeight,
  });

  final Rect anchor;
  final List<String> states;
  final String? selected;
  final String searchHint;
  final String noResultsLabel;
  final String clearSearchLabel;
  final List<String> Function(List<String> options) prepareOptions;
  final Key searchFieldKey;
  final Key clearButtonKey;
  final Key emptyMessageKey;
  final Key listKey;
  final double maxHeight;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        CustomSingleChildLayout(
          delegate: _StateMenuLayout(anchor: anchor, maxHeight: maxHeight),
          child: _StateSearchPanel(
            states: states,
            selected: selected,
            searchHint: searchHint,
            noResultsLabel: noResultsLabel,
            clearSearchLabel: clearSearchLabel,
            prepareOptions: prepareOptions,
            searchFieldKey: searchFieldKey,
            clearButtonKey: clearButtonKey,
            emptyMessageKey: emptyMessageKey,
            listKey: listKey,
          ),
        ),
      ],
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class _StateMenuLayout extends SingleChildLayoutDelegate {
  _StateMenuLayout({required this.anchor, required this.maxHeight});

  final Rect anchor;
  final double maxHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: anchor.width,
      maxWidth: anchor.width,
      maxHeight: math.max(0, math.min(maxHeight, constraints.maxHeight - 16)),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var top = anchor.bottom + 4;
    if (top + childSize.height > size.height - 8) {
      final above = anchor.top - 4 - childSize.height;
      top =
          above >= 8 ? above : math.max(8, size.height - childSize.height - 8);
    }
    var left = anchor.left;
    if (left + childSize.width > size.width - 8) {
      left = math.max(8, size.width - childSize.width - 8);
    }
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(covariant _StateMenuLayout oldDelegate) {
    return anchor != oldDelegate.anchor || maxHeight != oldDelegate.maxHeight;
  }
}

class _StateSearchPanel extends StatefulWidget {
  const _StateSearchPanel({
    required this.states,
    required this.selected,
    required this.searchHint,
    required this.noResultsLabel,
    required this.clearSearchLabel,
    required this.prepareOptions,
    required this.searchFieldKey,
    required this.clearButtonKey,
    required this.emptyMessageKey,
    required this.listKey,
  });

  final List<String> states;
  final String? selected;
  final String searchHint;
  final String noResultsLabel;
  final String clearSearchLabel;
  final List<String> Function(List<String> options) prepareOptions;
  final Key searchFieldKey;
  final Key clearButtonKey;
  final Key emptyMessageKey;
  final Key listKey;

  @override
  State<_StateSearchPanel> createState() => _StateSearchPanelState();
}

class _StateSearchPanelState extends State<_StateSearchPanel> {
  final _query = TextEditingController();
  late final List<String> _ordered = widget.prepareOptions(widget.states);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _clear() {
    _query.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final visible = statesMatchingPrefix(_ordered, _query.text);
    return Material(
      color: palette.surfaceSecondary,
      elevation: 6,
      shadowColor: palette.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  key: widget.searchFieldKey,
                  controller: _query,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.search,
                  style: AppTextStyles.body(context),
                  cursorColor: palette.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.searchHint,
                    prefixIcon: Icon(Icons.search, color: palette.textMuted),
                    suffixIcon:
                        _query.text.isEmpty
                            ? null
                            : IconButton(
                              key: widget.clearButtonKey,
                              tooltip: widget.clearSearchLabel,
                              onPressed: _clear,
                              icon: Icon(Icons.close, color: palette.textMuted),
                            ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Divider(height: 1, color: palette.border),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.max(0, constraints.maxHeight - 76),
                ),
                child:
                    visible.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          child: Text(
                            widget.noResultsLabel,
                            key: widget.emptyMessageKey,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.muted(context),
                          ),
                        )
                        : SingleChildScrollView(
                          key: widget.listKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final state in visible)
                                InkWell(
                                  onTap: () => Navigator.of(context).pop(state),
                                  child: Container(
                                    alignment: AlignmentDirectional.centerStart,
                                    constraints: const BoxConstraints(
                                      minHeight: kMinInteractiveDimension,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    color:
                                        state == widget.selected
                                            ? palette.accent.withValues(
                                              alpha: 0.12,
                                            )
                                            : null,
                                    child: Text(
                                      state,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
