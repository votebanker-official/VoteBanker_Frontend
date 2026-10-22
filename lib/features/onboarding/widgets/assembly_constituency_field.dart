import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../data/assembly_constituency.dart';

/// One choice from the assembly menu: a catalog row, or a typed name.
class _AssemblyMenuResult {
  const _AssemblyMenuResult.item(this.item) : typed = null;

  const _AssemblyMenuResult.typed(this.typed) : item = null;

  final AssemblyConstituency? item;
  final String? typed;
}

/// Assembly constituency selector. The search box is inside the menu.
///
/// A district with a saved list keeps that menu. A district with no list
/// becomes a text field so the name can be typed.
class AssemblyConstituencyField extends StatefulWidget {
  const AssemblyConstituencyField({
    required this.fieldKey,
    required this.value,
    required this.enabled,
    required this.stateName,
    required this.districtName,
    required this.hint,
    required this.manualHint,
    required this.searchHint,
    required this.noResultsLabel,
    required this.clearSearchLabel,
    required this.loadingLabel,
    required this.onLoad,
    required this.onChanged,
    required this.onTyped,
    this.errorText,
    super.key,
  });

  final Key fieldKey;
  final String? value;
  final bool enabled;
  final String stateName;
  final String districtName;
  final String hint;
  final String manualHint;
  final String searchHint;
  final String noResultsLabel;
  final String clearSearchLabel;
  final String loadingLabel;
  final String? errorText;
  final Future<AssemblyLookup> Function() onLoad;
  final ValueChanged<AssemblyConstituency?> onChanged;
  final ValueChanged<String> onTyped;

  @override
  State<AssemblyConstituencyField> createState() =>
      _AssemblyConstituencyFieldState();
}

class _AssemblyConstituencyFieldState extends State<AssemblyConstituencyField> {
  final _manualInput = TextEditingController();
  Future<AssemblyLookup>? _pending;
  String? _pendingKey;
  var _generation = 0;
  var _manual = false;

  @override
  void initState() {
    super.initState();
    _manualInput.text = widget.value ?? '';
    if (widget.enabled) _probe();
  }

  @override
  void didUpdateWidget(covariant AssemblyConstituencyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final locationChanged =
        oldWidget.stateName != widget.stateName ||
        oldWidget.districtName != widget.districtName;
    if (!locationChanged && oldWidget.enabled == widget.enabled) return;
    _manualInput.text = widget.value ?? '';
    _manual = false;
    _pending = null;
    _pendingKey = null;
    _generation++;
    if (widget.enabled) _probe();
  }

  @override
  void dispose() {
    _manualInput.dispose();
    super.dispose();
  }

  Future<AssemblyLookup> _load() {
    final key = '${widget.stateName}|${widget.districtName}';
    if (_pendingKey != key || _pending == null) {
      _pendingKey = key;
      _pending = widget.onLoad();
    }
    return _pending!;
  }

  Future<void> _probe() async {
    final generation = _generation;
    final lookup = await _load();
    if (!mounted || generation != _generation) return;
    final listed =
        lookup.status == AssemblyLookupStatus.ready && lookup.items.isNotEmpty;
    if (!listed) setState(() => _manual = true);
  }

  void _acceptTyped(String text) {
    final name = text.trim();
    if (name.isEmpty) return;
    _manualInput.text = name;
    setState(() => _manual = true);
    widget.onTyped(name);
  }

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
    final selected = await Navigator.of(context).push<_AssemblyMenuResult>(
      _AssemblyMenuRoute(
        anchor: anchor,
        selectedLabel: widget.value,
        searchHint: widget.searchHint,
        manualHint: widget.manualHint,
        noResultsLabel: widget.noResultsLabel,
        clearSearchLabel: widget.clearSearchLabel,
        loadingLabel: widget.loadingLabel,
        onLoad: _load,
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
    );
    if (!context.mounted || selected == null) return;
    final item = selected.item;
    if (item != null) {
      widget.onChanged(item);
      return;
    }
    final typed = selected.typed;
    if (typed != null) _acceptTyped(typed);
  }

  @override
  Widget build(BuildContext context) {
    if (_manual) return _manualField(context);
    final palette = context.palette;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: widget.fieldKey,
        borderRadius: BorderRadius.circular(14),
        onTap: widget.enabled ? () => _open(context) : null,
        child: InputDecorator(
          isEmpty: widget.value == null || widget.value!.isEmpty,
          decoration: InputDecoration(
            enabled: widget.enabled,
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: Icon(Icons.groups_outlined, color: palette.textMuted),
            suffixIcon: Icon(
              Icons.keyboard_arrow_down,
              color: palette.textMuted,
            ),
          ),
          child:
              widget.value == null || widget.value!.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                    widget.value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
        ),
      ),
    );
  }

  Widget _manualField(BuildContext context) {
    final palette = context.palette;
    return TextField(
      key: const ValueKey('profileAssemblyManual'),
      controller: _manualInput,
      enabled: widget.enabled,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      style: AppTextStyles.body(context),
      cursorColor: palette.accent,
      decoration: InputDecoration(
        hintText: widget.manualHint,
        errorText: widget.errorText,
        prefixIcon: Icon(Icons.groups_outlined, color: palette.textMuted),
      ),
      onChanged: widget.onTyped,
    );
  }
}

class _AssemblyMenuRoute extends PopupRoute<_AssemblyMenuResult> {
  _AssemblyMenuRoute({
    required this.anchor,
    required this.selectedLabel,
    required this.searchHint,
    required this.manualHint,
    required this.noResultsLabel,
    required this.clearSearchLabel,
    required this.loadingLabel,
    required this.onLoad,
    required this.maxHeight,
  });

  final Rect anchor;
  final String? selectedLabel;
  final String searchHint;
  final String manualHint;
  final String noResultsLabel;
  final String clearSearchLabel;
  final String loadingLabel;
  final Future<AssemblyLookup> Function() onLoad;
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
          delegate: _AssemblyMenuLayout(anchor: anchor, maxHeight: maxHeight),
          child: _AssemblySearchPanel(
            selectedLabel: selectedLabel,
            searchHint: searchHint,
            manualHint: manualHint,
            noResultsLabel: noResultsLabel,
            clearSearchLabel: clearSearchLabel,
            loadingLabel: loadingLabel,
            onLoad: onLoad,
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

class _AssemblyMenuLayout extends SingleChildLayoutDelegate {
  _AssemblyMenuLayout({required this.anchor, required this.maxHeight});

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
  bool shouldRelayout(covariant _AssemblyMenuLayout oldDelegate) {
    return anchor != oldDelegate.anchor || maxHeight != oldDelegate.maxHeight;
  }
}

class _AssemblySearchPanel extends StatefulWidget {
  const _AssemblySearchPanel({
    required this.selectedLabel,
    required this.searchHint,
    required this.manualHint,
    required this.noResultsLabel,
    required this.clearSearchLabel,
    required this.loadingLabel,
    required this.onLoad,
  });

  final String? selectedLabel;
  final String searchHint;
  final String manualHint;
  final String noResultsLabel;
  final String clearSearchLabel;
  final String loadingLabel;
  final Future<AssemblyLookup> Function() onLoad;

  @override
  State<_AssemblySearchPanel> createState() => _AssemblySearchPanelState();
}

class _AssemblySearchPanelState extends State<_AssemblySearchPanel> {
  final _query = TextEditingController();
  AssemblyLookup? _lookup;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lookup = await widget.onLoad();
    if (!mounted) return;
    setState(() {
      _lookup = lookup;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final lookup = _lookup;
    final visible =
        lookup == null
            ? const <AssemblyConstituency>[]
            : filterConstituencies(lookup.items, _query.text);
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
                  key: const ValueKey('assemblySearch'),
                  controller: _query,
                  autofocus: true,
                  autocorrect: _missing(lookup),
                  enableSuggestions: _missing(lookup),
                  textCapitalization:
                      _missing(lookup)
                          ? TextCapitalization.words
                          : TextCapitalization.none,
                  textInputAction:
                      _missing(lookup)
                          ? TextInputAction.done
                          : TextInputAction.search,
                  style: AppTextStyles.body(context),
                  cursorColor: palette.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText:
                        _missing(lookup) ? widget.manualHint : widget.searchHint,
                    prefixIcon: Icon(
                      _missing(lookup) ? Icons.edit_outlined : Icons.search,
                      color: palette.textMuted,
                    ),
                    suffixIcon:
                        _missing(lookup)
                            ? IconButton(
                              key: const ValueKey('useTypedConstituency'),
                              tooltip: widget.manualHint,
                              onPressed:
                                  _query.text.trim().isEmpty
                                      ? null
                                      : () => _acceptTyped(context),
                              icon: Icon(Icons.check, color: palette.accent),
                            )
                            : _query.text.isEmpty
                            ? null
                            : IconButton(
                              key: const ValueKey('clearAssemblySearch'),
                              tooltip: widget.clearSearchLabel,
                              onPressed: () {
                                _query.clear();
                                setState(() {});
                              },
                              icon: Icon(Icons.close, color: palette.textMuted),
                            ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (_missing(lookup)) _acceptTyped(context);
                  },
                ),
              ),
              Divider(height: 1, color: palette.border),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.max(0, constraints.maxHeight - 76),
                ),
                child: _body(context, lookup, visible),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _missing(AssemblyLookup? lookup) {
    if (_loading || lookup == null) return false;
    return lookup.status != AssemblyLookupStatus.ready || lookup.items.isEmpty;
  }

  void _acceptTyped(BuildContext context) {
    final name = _query.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(_AssemblyMenuResult.typed(name));
  }

  Widget _body(
    BuildContext context,
    AssemblyLookup? lookup,
    List<AssemblyConstituency> visible,
  ) {
    if (_loading || lookup == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              key: ValueKey('assemblyLoading'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.loadingLabel,
                style: AppTextStyles.muted(context),
              ),
            ),
          ],
        ),
      );
    }
    if (_missing(lookup)) {
      return const SizedBox(height: 12);
    }
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Text(
          widget.noResultsLabel,
          key: const ValueKey('noConstituenciesFound'),
          textAlign: TextAlign.center,
          style: AppTextStyles.muted(context),
        ),
      );
    }
    final palette = context.palette;
    return SingleChildScrollView(
      key: const ValueKey('assemblyMenuList'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in visible)
            InkWell(
              onTap: () => Navigator.of(
                context,
              ).pop(_AssemblyMenuResult.item(item)),
              child: Container(
                alignment: AlignmentDirectional.centerStart,
                constraints: const BoxConstraints(
                  minHeight: kMinInteractiveDimension,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color:
                    item.label == widget.selectedLabel
                        ? palette.accent.withValues(alpha: 0.12)
                        : null,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
