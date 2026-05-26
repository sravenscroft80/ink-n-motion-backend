import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/data/style_template_catalog.dart';
import 'package:ink_n_motion/models/style_template.dart';
import 'package:ink_n_motion/screens/easy_video_preview_screen.dart';
import 'package:ink_n_motion/screens/premium_video_generation_screen.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/utils/navigation.dart';
import 'package:ink_n_motion/widgets/style_template_thumbnail.dart';

class StylePickerScreen extends ConsumerWidget {
  const StylePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(appStateProvider).selectedStyleTemplateId;
    final templates = StyleTemplateCatalog.templates;

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: InkColors.backgroundSecondary.withValues(alpha: 0.9),
        border: null,
        middle: const Text('Styles'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Motion styles'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: InkSpacing.md),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Choose a template to start the ${StyleRenderingType.easy.name} or '
                  '${StyleRenderingType.premium.name} rendering track.',
                  style: InkTypography.subhead,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(InkSpacing.md),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: InkSpacing.md,
                  crossAxisSpacing: InkSpacing.md,
                  childAspectRatio: 0.88,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final template = templates[index];
                    return _StyleTemplateCard(
                      template: template,
                      selected: selectedId == template.id,
                      onTap: () => _onTemplateSelected(context, ref, template),
                    );
                  },
                  childCount: templates.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTemplateSelected(
    BuildContext context,
    WidgetRef ref,
    StyleTemplate template,
  ) {
    ref.read(appStateProvider.notifier).setSelectedStyleTemplate(template.id);

    if (template.isEasy) {
      pushCupertino(context, const EasyVideoPreviewScreen());
      return;
    }
    pushCupertino(context, const PremiumVideoGenerationScreen());
  }
}

class _StyleTemplateCard extends StatelessWidget {
  const _StyleTemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final StyleTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = template.isPremium
        ? InkColors.accentNeonMagenta
        : InkColors.accentNeonCyan;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(InkSpacing.md),
        decoration: BoxDecoration(
          color: InkColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(InkRadius.md),
          border: Border.all(
            color: selected ? accent : InkColors.textTertiary.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StyleTemplateThumbnail(template: template),
            const Spacer(),
            Text(
              template.name,
              style: InkTypography.headline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: InkSpacing.xs),
            Text(
              template.isPremium ? 'Premium track' : 'Easy track',
              style: InkTypography.caption1.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
