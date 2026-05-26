import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/screens/legal/legal_document_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScaffold(
      title: 'Terms of Service',
      sections: [
        LegalDocumentSection(
          heading: 'Agreement',
          body:
              'By accessing or using Ink-N-Motion, you agree to be bound by these Terms '
              'of Service. If you do not agree, do not use the app.',
        ),
        LegalDocumentSection(
          heading: 'Entertainment & Creative Inspiration',
          body:
              'Ink-N-Motion is provided for entertainment and creative inspiration only. '
              'The app helps you explore tattoo ideas, generate concept art, and preview '
              'motion effects — it is not a substitute for professional services.',
        ),
        LegalDocumentSection(
          heading: 'Not Professional Tattoo Advice',
          body:
              'AI-generated tattoo concepts are illustrative only. They are NOT '
              'professional tattoo advice, medical guidance, or a guarantee of how a '
              'final tattoo will look on your body. Always work with a licensed tattoo '
              'artist before getting inked.',
        ),
        LegalDocumentSection(
          heading: 'Age Requirement',
          body:
              'You must be at least 18 years of age to use premium features, including '
              'paid credit packs and Ink Plus subscriptions. Users under 18 may only use '
              'free features with verifiable parental or guardian consent.',
        ),
        LegalDocumentSection(
          heading: 'Credits & Refunds',
          body:
              'Credits are consumed when used for AI concept generation or video '
              'animation. No refunds are issued on used credits.\n\n'
              'Unused credits may be eligible for a refund within 48 hours of purchase, '
              'subject to Apple App Store or Google Play policies and applicable law. '
              'Contact support@ink-n-motion.com for assistance.',
        ),
        LegalDocumentSection(
          heading: 'In-App Purchases',
          body:
              'All in-app purchases and subscriptions are processed by the Apple App '
              'Store or Google Play. Billing, renewals, and cancellations are governed '
              'by the respective store\'s terms. RevenueCat facilitates entitlement '
              'sync between the app and store receipts.',
        ),
        LegalDocumentSection(
          heading: 'Acceptable Use & Account Suspension',
          body:
              'You agree not to abuse the service, circumvent usage limits, upload '
              'unlawful content, harass others, or attempt to reverse engineer the app. '
              'We reserve the right to suspend or terminate accounts that violate these '
              'Terms or that we reasonably believe are engaged in fraudulent or abusive '
              'behavior.',
        ),
        LegalDocumentSection(
          heading: 'Intellectual Property',
          body:
              'Ink-N-Motion, its branding, UI, and underlying technology are owned by '
              'LabrHood Labs. You retain ownership of content you upload. AI-generated '
              'output is licensed to you for personal, non-commercial use unless '
              'otherwise agreed in writing.',
        ),
        LegalDocumentSection(
          heading: 'Disclaimer of Warranties',
          body:
              'THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES '
              'OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT GUARANTEE UNINTERRUPTED '
              'SERVICE, ERROR-FREE OPERATION, OR SPECIFIC AI RESULTS.',
        ),
        LegalDocumentSection(
          heading: 'Governing Law',
          body:
              'These Terms are governed by the laws of the United States, without regard '
              'to conflict-of-law principles. Any disputes shall be resolved in courts '
              'located in the United States, unless otherwise required by applicable law.',
        ),
        LegalDocumentSection(
          heading: 'Contact',
          body:
              'Questions about these Terms:\n'
              'support@ink-n-motion.com',
        ),
      ],
    );
  }
}
