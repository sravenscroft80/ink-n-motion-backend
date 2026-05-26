import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/services/navigation.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/discover/discover_content_widgets.dart';

class StyleArchiveScreen extends StatelessWidget {
  const StyleArchiveScreen({super.key});

  static const String screenTitle = 'Tattoo Style Archive';

  void _openStyleDetail(BuildContext context, String styleId) {
    InkNavigation.pushStyleDetail(context, styleId);
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverContentScaffold(
      title: screenTitle,
      body: DiscoverContentLoader(
        builder: (context, content) {
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              InkSpacing.md,
              InkSpacing.md,
              InkSpacing.md,
              InkSpacing.xl,
            ),
            itemCount: content.styleArchive.length,
            itemBuilder: (context, index) {
              final entry = content.styleArchive[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: InkSpacing.sm),
                child: DiscoverStyleListTile(
                  entry: entry,
                  onTap: () => _openStyleDetail(context, entry.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
