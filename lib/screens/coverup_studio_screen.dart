import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ink_n_motion/services/firestore_wallet_service.dart';
import 'package:ink_n_motion/screens/coverup_studio_picker.dart'
    if (dart.library.html) 'package:ink_n_motion/screens/coverup_studio_picker_web.dart'
    if (dart.library.io) 'package:ink_n_motion/screens/coverup_studio_picker_io.dart';

/// Coverup Studio — upload existing tattoo photo and preview AI coverup concepts.
class CoverupStudioScreen extends StatefulWidget {
  const CoverupStudioScreen({super.key});

  @override
  State<CoverupStudioScreen> createState() => _CoverupStudioScreenState();
}

class _CoverupStudioScreenState extends State<CoverupStudioScreen> {
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldDisabled = Color(0xFF8B7D2A);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF333333);
  static const Color _hintGrey = Color(0xFF666666);
  static const Color _mutedGrey = Color(0xFF444444);
  static const Color _snippetGrey = Color(0xFF999999);
  static const Color _errorRed = Color(0xFFCC3333);

  final TextEditingController _promptController = TextEditingController();

  bool _isGenerating = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _resultImageUrl;
  String? _errorMessage;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await pickCoverupImage();
    if (!mounted || picked == null) return;

    setState(() {
      _selectedImageBytes = picked.bytes;
      _selectedImageName = picked.name;
      _errorMessage = null;
    });
  }

  Future<void> _generateCoverup() async {
    if (_selectedImageBytes == null) {
      _showNotice('Please upload a photo of your tattoo first');
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _errorMessage = 'Please describe your coverup design';
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
    if (!wallet.freeCoverUpUsed) {
      isFreeRender = true;
    } else if (wallet.totalBalance < InkTokenCost.coverupStudio) {
      _showNotice(
        'You need 3 tokens for a coverup render. Visit the store to top up.',
        title: 'Not Enough Tokens',
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _resultImageUrl = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://ink-n-motion-api.onrender.com/api/generate-coverup',
        ),
      )
        ..fields['prompt'] = prompt
        ..fields['style'] = 'coverup_tattoo'
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            _selectedImageBytes!,
            filename: _selectedImageName ?? 'tattoo.jpg',
          ),
        );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _resultImageUrl = data['imageUrl'] as String?;
        });
        if (isFreeRender) {
          await FirestoreWalletService.instance.claimFreeCoverUp(uid);
        } else {
          await FirestoreWalletService.instance.deductTokens(
            uid,
            InkTokenCost.coverupStudio,
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
        _errorMessage =
            'Timed out — coverup renders can take up to 90 seconds';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
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
                      'Coverup Studio',
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
                    'Transform Your Existing Ink',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload a photo of your tattoo, then describe your coverup vision',
                    style: TextStyle(
                      color: _snippetGrey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Step 1 — Your Tattoo Photo',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.photo,
                                  color: _hintGrey,
                                  size: 40,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Tap to upload tattoo photo',
                                  style: TextStyle(
                                    color: _hintGrey,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'JPG or PNG',
                                  style: TextStyle(
                                    color: _mutedGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Step 2 — Describe Your Coverup',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _promptController,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(color: CupertinoColors.white),
                    placeholder:
                        'e.g. Cover with a large Japanese koi fish, bold color, flowing water elements...',
                    placeholderStyle: const TextStyle(color: _hintGrey),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.sparkles, color: _gold, size: 14),
                      SizedBox(width: 6),
                      Text(
                        '3 tokens per render  ·  First render free',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isGenerating ? null : _generateCoverup,
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
                                '✦  Generate Coverup Preview',
                                style: TextStyle(
                                  color: CupertinoColors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
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
                  if (_resultImageUrl != null) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Your Coverup Preview',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This is an AI concept — share with your artist for the final design',
                      style: TextStyle(
                        color: _snippetGrey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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
                          _resultImageUrl!,
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
                        _ActionButton(
                          label: 'Save',
                          icon: CupertinoIcons.arrow_down_circle,
                          backgroundColor: _surface,
                          foregroundColor: CupertinoColors.white,
                          onTap: _saveImage,
                        ),
                        _ActionButton(
                          label: 'Share',
                          icon: CupertinoIcons.share,
                          backgroundColor: _surface,
                          foregroundColor: CupertinoColors.white,
                          onTap: _shareImage,
                        ),
                        _ActionButton(
                          label: 'Re-generate',
                          icon: CupertinoIcons.refresh,
                          backgroundColor: _gold,
                          foregroundColor: CupertinoColors.black,
                          onTap: _isGenerating ? null : _generateCoverup,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Results are AI concepts — always consult a professional tattoo artist',
                        style: TextStyle(
                          color: _snippetGrey,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
