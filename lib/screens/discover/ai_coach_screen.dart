import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ink_n_motion/services/firestore_wallet_service.dart';

/// AI Concept Generator — single-prompt 2D tattoo concept renders.
class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  static const String heroImageAsset = 'assets/images/ai_coach.png';

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldDisabled = Color(0xFF8B7D2A);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF333333);
  static const Color _hintGrey = Color(0xFF666666);
  static const Color _snippetGrey = Color(0xFF999999);
  static const Color _errorRed = Color(0xFFCC3333);

  final TextEditingController _promptController = TextEditingController();

  bool _isGenerating = false;
  String _loadStatus = '';
  String? _generatedImageUrl;
  String? _errorMessage;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateConcept() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _errorMessage = 'Please describe your tattoo vision first.';
      });
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showNotice('Please wait while we set up your account.', title: 'Not Ready');
      return;
    }

    final wallet = await FirestoreWalletService.instance.getWallet(uid);
    if (wallet == null) {
      _showNotice('Unable to load your token balance. Please try again.', title: 'Wallet Error');
      return;
    }

    bool isFreeRender = false;
    if (wallet.hasFreeDailyConcept) {
      isFreeRender = true;
    } else if (wallet.totalBalance < InkTokenCost.aiConcept) {
      _showNotice(
        'You need 1 token for a concept render. Visit the store to top up.',
        title: 'Not Enough Tokens',
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedImageUrl = null;
      _loadStatus = 'Generating your concept...';
    });

    unawaited(
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (!mounted || !_isGenerating) return;
        setState(() {
          _loadStatus = 'Rendering final image...';
        });
      }),
    );

    try {
      final response = await http
          .post(
            Uri.parse(
              'https://ink-n-motion-api.onrender.com/api/generate-concept',
            ),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'prompt': prompt,
              'style': '2d_tattoo_concept',
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _generatedImageUrl = data['imageUrl'] as String?;
        });
        if (isFreeRender) {
          await FirestoreWalletService.instance.claimFreeDailyConcept(uid);
        } else {
          await FirestoreWalletService.instance.deductTokens(
            uid,
            InkTokenCost.aiConcept,
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Server error. Please try again.';
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Timed out. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _loadStatus = '';
        });
      }
    }
  }

  void _showNotice(String message, {String? title}) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
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

  void _saveImage() {
    _showNotice('Right-click the image to save');
  }

  void _shareImage() {
    _showNotice('Share coming soon');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'AI Concept Generator',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Describe Your Tattoo Vision',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Include placement, size, color, and style if known',
                    style: TextStyle(
                      color: _snippetGrey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.sparkles, color: _gold, size: 14),
                      SizedBox(width: 6),
                      Text(
                        '1 free render per day  ·  Subscription unlocks 3 variations',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _promptController,
                    maxLines: 5,
                    minLines: 3,
                    style: const TextStyle(color: CupertinoColors.white),
                    placeholder:
                        'e.g. A serpent coiled around a compass rose, forearm, black and grey, fine line...',
                    placeholderStyle: const TextStyle(color: _hintGrey),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isGenerating ? null : _generateConcept,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isGenerating ? _goldDisabled : _gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _isGenerating
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CupertinoActivityIndicator(
                                    color: CupertinoColors.black,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Generating...',
                                    style: TextStyle(
                                      color: CupertinoColors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                '✦  Generate Concept',
                                style: TextStyle(
                                  color: CupertinoColors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (_isGenerating) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _loadStatus,
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x22CC3333),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _errorRed),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: _errorRed,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  if (_generatedImageUrl != null) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Your Concept',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _generatedImageUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CupertinoActivityIndicator(
                                color: _gold,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                color: _snippetGrey,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ResultActionButton(
                          icon: CupertinoIcons.arrow_down_circle,
                          label: 'Save',
                          backgroundColor: _surface,
                          foregroundColor: CupertinoColors.white,
                          onTap: _saveImage,
                        ),
                        _ResultActionButton(
                          icon: CupertinoIcons.share,
                          label: 'Share',
                          backgroundColor: _surface,
                          foregroundColor: CupertinoColors.white,
                          onTap: _shareImage,
                        ),
                        _ResultActionButton(
                          icon: CupertinoIcons.refresh,
                          label: 'New Concept',
                          backgroundColor: _gold,
                          foregroundColor: CupertinoColors.black,
                          onTap: _isGenerating ? null : _generateConcept,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultActionButton extends StatelessWidget {
  const _ResultActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
