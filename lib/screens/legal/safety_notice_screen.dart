import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/screens/legal/legal_document_scaffold.dart';

class SafetyNoticeScreen extends StatelessWidget {
  const SafetyNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScaffold(
      title: 'Safety Notice',
      sections: [
        LegalDocumentSection(
          heading: 'Creative Inspiration Only',
          body:
              'AI-generated images in Ink-N-Motion are for creative inspiration only. '
              'They are not final tattoo designs, medical illustrations, or professional '
              'recommendations. Treat all output as a starting point for conversation '
              'with a qualified artist — not as a finished plan.',
        ),
        LegalDocumentSection(
          heading: 'Consult a Licensed Tattoo Artist',
          body:
              'Always consult a licensed, professional tattoo artist before getting any '
              'tattoo. A trained artist can evaluate your idea, adapt it to your body, '
              'and apply it safely using proper hygiene and technique.',
        ),
        LegalDocumentSection(
          heading: 'Placement, Sizing & Skin Compatibility',
          body:
              'Placement, sizing, and skin compatibility must be discussed with a '
              'professional. Factors such as body curvature, muscle movement, aging skin, '
              'and long-term readability cannot be fully assessed by AI. Your artist will '
              'help you choose placement and scale that work for your body.',
        ),
        LegalDocumentSection(
          heading: 'Results May Vary',
          body:
              'AI does not account for individual skin tone, texture, healing patterns, '
              'or how ink settles over time. Colors, contrast, and fine detail may look '
              'different on skin than in a digital preview. Expect variation between '
              'AI output and a healed tattoo.',
        ),
        LegalDocumentSection(
          heading: 'Not Medical or Professional Advice',
          body:
              'Ink-N-Motion is not suitable for medical advice, dermatological diagnosis, '
              'or professional tattoo consultation. Do not use the app to evaluate skin '
              'conditions, allergic reactions, or aftercare for existing tattoos. '
              'Seek medical attention for any health concerns.',
        ),
        LegalDocumentSection(
          heading: 'Hygiene & Aftercare',
          body:
              'Tattooing breaks the skin. Only licensed professionals operating in '
              'sanitary conditions should perform tattoos. Follow your artist\'s aftercare '
              'instructions exactly — not guidance from this app.',
        ),
        LegalDocumentSection(
          heading: 'Emergency',
          body:
              'If you experience severe pain, infection signs, or an allergic reaction '
              'after a tattoo, contact a medical professional immediately.',
        ),
      ],
    );
  }
}
