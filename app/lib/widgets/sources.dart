import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pwnage/services/api_service.dart';

class SourcesButton extends ConsumerWidget {
  final Set<PostDataType> filter;
  final void Function(Set<PostDataType> filter) onUpdateFilter;

  const SourcesButton({
    super.key,
    required this.filter,
    required this.onUpdateFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        return OutlinedButton(
          onPressed: () => _showFilterModal(context, ref),
          child: Text('Sources'),
        );
      },
    );
  }

  void _showFilterModal(BuildContext context, WidgetRef ref) async {
    final newFilter = await showModalBottomSheet<Set<PostDataType>>(
      context: context,
      clipBehavior: Clip.hardEdge,
      isScrollControlled: false,
      builder: (context) => _FilterSheet(filter: Set.of(filter)),
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
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Sources of Pwnage',
              style: TextTheme.of(context).bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
          for (final type in PostDataType.values)
            CheckboxListTile(
              value: _filter.contains(type),
              enabled: !_filter.contains(type) || _filter.length > 1,
              onChanged: (value) {
                setState(
                  () =>
                      value == true ? _filter.add(type) : _filter.remove(type),
                );
              },
              title: Row(
                children: [
                  SizedBox.square(
                    dimension: 16,
                    child: _SourceIcon(type: type, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Text(type.label),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
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
