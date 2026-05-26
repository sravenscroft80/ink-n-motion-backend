import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';

/// Simple scrollable legal / info document shell.
class LegalDocumentScaffold extends StatelessWidget {
  const LegalDocumentScaffold({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<LegalDocumentSection> sections;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: InkColors.backgroundPrimary.withValues(alpha: 0.94),
        border: null,
        middle: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                InkSpacing.md,
                InkSpacing.lg,
                InkSpacing.xl,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = sections[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == sections.length - 1 ? 0 : InkSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (section.heading != null) ...[
                            Text(
                              section.heading!,
                              style: InkTypography.headline.copyWith(
                                color: const Color(0xFFD4A017),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: InkSpacing.sm),
                          ],
                          Text(
                            section.body,
                            style: InkTypography.body.copyWith(
                              color: InkColors.textPrimary.withValues(alpha: 0.86),
                              height: 1.62,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: sections.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalDocumentSection {
  const LegalDocumentSection({
    this.heading,
    required this.body,
  });

  final String? heading;
  final String body;
}
