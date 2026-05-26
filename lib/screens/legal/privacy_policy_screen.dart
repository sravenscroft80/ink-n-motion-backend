import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/screens/legal/legal_document_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScaffold(
      title: 'Privacy Policy',
      sections: [
        LegalDocumentSection(
          heading: 'Effective Date',
          body: 'June 1, 2026',
        ),
        LegalDocumentSection(
          heading: 'Introduction',
          body:
              'Ink-N-Motion ("we," "our," or "us") is committed to protecting your '
              'privacy. This Privacy Policy describes what information we collect, how '
              'we use it, and your choices when you use the Ink-N-Motion application.',
        ),
        LegalDocumentSection(
          heading: 'What Data We Collect',
          body:
              'We may collect the following types of information:\n\n'
              '• Device ID and basic device information (platform, OS version, app version)\n'
              '• Usage analytics (feature interactions, session activity, generation counts)\n'
              '• Photos and images you upload for concept or animation generation\n'
              '• AI-generated images processed temporarily to deliver requested features\n'
              '• Purchase and subscription status via Apple App Store, Google Play, and RevenueCat',
        ),
        LegalDocumentSection(
          heading: 'We Do NOT Sell Personal Data',
          body:
              'We do not sell, rent, or trade your personal information to third parties '
              'for their marketing purposes. We use data only to operate, secure, and '
              'improve Ink-N-Motion.',
        ),
        LegalDocumentSection(
          heading: 'AI Processing',
          body:
              'AI-generated images and animations are processed through third-party AI '
              'providers, including OpenAI (concept/mockup generation) and Kling AI '
              '(video animation). When you use these features, your prompts and uploaded '
              'images may be transmitted to those services solely to fulfill your request. '
              'Each provider processes data under its own privacy policy.',
        ),
        LegalDocumentSection(
          heading: 'Image Storage',
          body:
              'Uploaded and generated images are not stored permanently on our servers. '
              'They are processed temporarily to complete your generation request and '
              'then discarded from our backend systems, subject to standard transient '
              'logs required for security and debugging.',
        ),
        LegalDocumentSection(
          heading: 'Credits & Subscriptions',
          body:
              'Credit balances, daily usage limits, subscription status, and related '
              'wallet data are stored locally on your device using secure on-device '
              'storage (SharedPreferences). This data may sync to cloud services only '
              'when account features are enabled in a future update.',
        ),
        LegalDocumentSection(
          heading: 'Security',
          body:
              'We apply reasonable technical and organizational safeguards to protect '
              'your information. No method of transmission or storage is 100% secure, '
              'and we cannot guarantee absolute security.',
        ),
        LegalDocumentSection(
          heading: 'Your Rights',
          body:
              'Depending on your location, you may have the right to access, correct, '
              'or delete personal data we hold. To exercise these rights, contact us at '
              'the email below.',
        ),
        LegalDocumentSection(
          heading: 'Contact',
          body:
              'Privacy questions or data requests:\n'
              'privacy@ink-n-motion.com',
        ),
      ],
    );
  }
}
