import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pwnage/pwnage_app.dart';
import 'package:pwnage/services/api_service.dart';

class SourcesButton extends StatelessWidget {
  final Set<PostDataType> filter;
  final void Function(Set<PostDataType> filter) onUpdateFilter;

  const SourcesButton({
    super.key,
    required this.filter,
    required this.onUpdateFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Hero(
          tag: 'hero-tag',
          createRectTween: (begin, end) => RectTween(begin: begin, end: end),
          child: OutlinedButton(
            onPressed: () => _showFilterModal(context, ref),
            child: Text('SOURCES'),
          ),
        );
      },
    );
  }

  void _showFilterModal(BuildContext context, WidgetRef ref) async {
    final newFilter = await Navigator.of(context).push<Set<PostDataType>>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        // transitionDuration: Duration(milliseconds: 800),
        // reverseTransitionDuration: Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => _FilterSheet(filter: filter),
      ),
    );
    if (context.mounted && newFilter != null) {
      onUpdateFilter(newFilter);
    }
  }
}

class _FilterSheet extends StatefulWidget {
  final Set<PostDataType> filter;

  const _FilterSheet({super.key, required this.filter});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<PostDataType> _filter = Set.of(widget.filter);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_filter);
        }
        return;
      },
      child: _FilterSheetHero(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
            border: Border.all(color: red),
            color: Colors.black,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'SOURCES OF PWNAGE',
                      style: TextTheme.of(context).headlineSmall,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final type in PostDataType.values)
                    Builder(
                      builder: (context) {
                        final value = _filter.contains(type);
                        final enabled =
                            !_filter.contains(type) || _filter.length > 1;
                        return ListTile(
                          enabled: enabled,
                          onTap: () => setState(
                            () => !value
                                ? _filter.add(type)
                                : _filter.remove(type),
                          ),
                          leading: SizedBox.square(
                            dimension: 16,
                            child: _SourceIcon(
                              type: type,
                              color: enabled
                                  ? Colors.white
                                  : Theme.of(context).disabledColor,
                            ),
                          ),
                          title: Text(type.label),
                          trailing: value
                              ? Icon(Icons.check)
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheetHero extends StatelessWidget {
  final Widget child;

  const _FilterSheetHero({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 154),
        child: Hero(
          tag: 'hero-tag',
          createRectTween: (begin, end) => RectTween(begin: begin, end: end),
          child: child,
        ),
      ),
    );
  }
}

class SourceBadge extends StatelessWidget {
  final PostDataType type;

  const SourceBadge({super.key, required this.type});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          SizedBox.square(dimension: 16, child: _SourceIcon(type: type)),
          const SizedBox(width: 12),
          Text(switch (type) {
            PostDataType.youtubeVideo => 'YouTube',
            PostDataType.forumThread => 'Forum',
            PostDataType.patreonPost => 'Patreon',
          }),
        ],
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  final PostDataType type;
  final Color color;

  const _SourceIcon({
    super.key,
    required this.type,
    this.color = Colors.white54,
  });

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      PostDataType.youtubeVideo => SvgPicture.asset(
        'assets/icons/youtube_logo.svg',
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
      PostDataType.forumThread => Icon(Icons.forum, size: 20, color: color),
      PostDataType.patreonPost => SvgPicture.asset(
        'assets/icons/patreon_logo.svg',
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    };
  }
}
