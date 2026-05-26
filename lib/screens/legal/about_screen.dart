import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color _gold = Color(0xFFD4A017);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: InkColors.backgroundPrimary.withValues(alpha: 0.94),
        border: null,
        middle: const Text('About Ink-N-Motion'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                InkSpacing.lg,
                InkSpacing.lg,
                InkSpacing.lg,
                InkSpacing.xl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Ink-N-Motion',
                    style: InkTypography.title2.copyWith(
                      color: _gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: InkSpacing.xs),
                  Text(
                    'Where your art comes alive',
                    style: InkTypography.headline.copyWith(
                      color: InkColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: InkSpacing.lg),
                  _infoRow('Version', '1.0.0'),
                  const SizedBox(height: InkSpacing.sm),
                  _infoRow('Built by', 'LabrHood Labs'),
                  const SizedBox(height: InkSpacing.lg),
                  Text(
                    'Our Mission',
                    style: InkTypography.headline.copyWith(
                      color: _gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: InkSpacing.sm),
                  Text(
                    'Ink-N-Motion helps tattoo enthusiasts explore ideas, discover '
                    'styles, and bring static ink concepts to life through motion. '
                    'Describe a tattoo in words, generate a concept image with AI, '
                    'then animate it in Studio — bridging inspiration and the artist\'s chair. '
                    'We built this app for collectors, creators, and anyone who sees tattoos as living art.',
                    style: InkTypography.body.copyWith(
                      color: InkColors.textPrimary.withValues(alpha: 0.86),
                      height: 1.62,
                    ),
                  ),
                  const SizedBox(height: InkSpacing.lg),
                  Text(
                    'Credits',
                    style: InkTypography.headline.copyWith(
                      color: _gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: InkSpacing.sm),
                  Text(
                    'Powered by Kling AI, OpenAI, and Flutter',
                    style: InkTypography.body.copyWith(
                      color: InkColors.textPrimary.withValues(alpha: 0.86),
                      height: 1.62,
                    ),
                  ),
                  const SizedBox(height: InkSpacing.xl),
                  CupertinoListSection.insetGrouped(
                    backgroundColor: InkColors.backgroundPrimary,
                    children: [
                      CupertinoListTile(
                        title: const Text('Visit LabrHood'),
                        subtitle: const Text('labrhood.com'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () => _openLabrHood(context),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: InkTypography.subhead.copyWith(
              color: InkColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: InkTypography.subhead.copyWith(
            color: InkColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _openLabrHood(BuildContext context) async {
    final uri = Uri.parse('https://labrhood.com');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      // ignore: use_build_context_synchronously
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Unable to Open Link'),
          content: const Text('Could not open labrhood.com in your browser.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
