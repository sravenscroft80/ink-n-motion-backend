import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// Curated tattoo books and magazines — opens Amazon links.
class InkChroniclesScreen extends StatelessWidget {
  const InkChroniclesScreen({super.key});

  static const String _navTitle = 'Resource Library';
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _cardBackground = Color(0xFF1A1A1A);

  static const List<Map<String, String>> _books = [
    {
      'title': 'Superior Tattoo Bible',
      'author': 'Superior Tattoo',
      'description':
          'The definitive reference for tattoo flash art, covering every major style with hundreds of designs.',
      'category': 'REFERENCE',
      'url': 'https://www.amazon.com/dp/1929133847?tag=Inknmotion20-20',
    },
    {
      'title': 'Bodies of Subversion',
      'author': 'Margot Mifflin',
      'description':
          'A secret history of women and tattoos — the most comprehensive account of women in tattoo culture.',
      'category': 'HISTORY',
      'url': 'https://www.amazon.com/dp/1576876136?tag=Inknmotion20-20',
    },
    {
      'title': 'The Japanese Tattoo',
      'author': 'Sandi Fellman',
      'description':
          'Stunning photographic study of traditional Japanese irezumi and the masters behind it.',
      'category': 'JAPANESE',
      'url': 'https://www.amazon.com/dp/0896597989?tag=Inknmotion20-20',
    },
    {
      'title': 'The Tattoo History Source Book',
      'author': 'Steve Gilbert',
      'description':
          'An anthology of historical records on tattooing from ancient times to the modern era.',
      'category': 'HISTORY',
      'url': 'https://www.amazon.com/dp/1890451061?tag=Inknmotion20-20',
    },
    {
      'title': 'Tattoo Machine',
      'author': 'Jeff Johnson',
      'description':
          'A memoir from a tattooist on the front lines — raw, funny, and deeply human.',
      'category': 'MEMOIR',
      'url': 'https://www.amazon.com/dp/0767931076?tag=Inknmotion20-20',
    },
    {
      'title': '1000 Tattoos',
      'author': 'Henk Schiffmacher',
      'description':
          'A spectacular visual journey through 3,000 years of tattoo art from every culture on earth.',
      'category': 'ART',
      'url':
          'https://www.amazon.com/s?k=1000+Tattoos+Henk+Schiffmacher+Taschen&tag=Inknmotion20-20',
    },
    {
      'title': 'The Tattoo Encyclopedia',
      'author': 'Terisa Green',
      'description':
          'A guide to choosing your tattoo — covering over 1,000 symbols, their meanings, and origins.',
      'category': 'REFERENCE',
      'url':
          'https://www.amazon.com/s?k=Tattoo+Encyclopedia+Terisa+Green&tag=Inknmotion20-20',
    },
    {
      'title': 'Tattoo Flash Art Vol. 1',
      'author': 'Various Artists',
      'description':
          'Classic American flash art from the golden age of tattooing — a collector\'s treasure.',
      'category': 'FLASH ART',
      'url':
          'https://www.amazon.com/s?k=Tattoo+Flash+Art+Vol+1+classic+american&tag=Inknmotion20-20',
    },
  ];

  Future<void> _openAmazon(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _showLinkError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showLinkError(context);
      }
    }
  }

  void _showLinkError(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Unable to Open Link'),
        content: const Text('Could not open Amazon in your browser.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: _background,
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(
                            CupertinoIcons.back,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _navTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Essential reads for the ink-obsessed',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _books.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i < _books.length - 1 ? 10 : 0,
                      ),
                      child: _BookCard(
                        book: _books[i],
                        onTap: () => _openAmazon(context, _books[i]['url']!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.onTap,
  });

  final Map<String, String> book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkTactileButton(
      onPressed: onTap,
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: InkChroniclesScreen._cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryPill(label: book['category']!),
              const SizedBox(height: InkSpacing.sm),
              Text(
                book['title']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: InkColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: InkSpacing.xs),
              Text(
                book['author']!,
                style: InkTypography.footnote.copyWith(
                  color: InkColors.accentGold,
                ),
              ),
              const SizedBox(height: InkSpacing.sm),
              Text(
                book['description']!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: InkTypography.footnote.copyWith(
                  color: InkColors.textSecondary,
                ),
              ),
              const SizedBox(height: InkSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View on Amazon →',
                  style: InkTypography.footnote.copyWith(
                    color: InkColors.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: InkColors.accentGold,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: InkChroniclesScreen._background,
          ),
        ),
      ),
    );
  }
}
