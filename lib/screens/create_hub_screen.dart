import 'package:flutter/cupertino.dart';
import '../services/navigation.dart';

class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CREATE',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your tattoo. Your vision.',
                style: TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 28),
              _CreateCard(
                image: 'assets/images/create_concept.png',
                badge: 'FREE DAILY',
                badgeColor: Color(0xFFD4AF37),
                title: '2D Concept Generator',
                subtitle:
                    'Describe your tattoo and get an AI-designed concept in seconds.',
                onTap: () => Navigator.of(context).pushNamed(InkRoutes.aiCoach),
              ),
              const SizedBox(height: 16),
              _CreateCard(
                image: 'assets/images/create_coverup.png',
                badge: '3 TOKENS',
                badgeColor: Color(0xFF4FC3F7),
                title: 'Coverup Studio',
                subtitle:
                    'Upload your existing tattoo and preview a coverup design over it.',
                onTap: () =>
                    Navigator.of(context).pushNamed(InkRoutes.coverupStudio),
              ),
              const SizedBox(height: 16),
              _CreateCard(
                image: 'assets/images/create_video.png',
                badge: '10 TOKENS',
                badgeColor: Color(0xFFD4AF37),
                title: 'Animate My Ink',
                subtitle:
                    'Turn any tattoo photo into a stunning 10-second animated video.',
                onTap: () =>
                    Navigator.of(context).pushNamed(InkRoutes.animateMyInk),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  final String image;
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateCard({
    required this.image,
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.asset(
              image,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 190,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF5F5F5),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xCCF5F5F5),
                      fontSize: 13,
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
