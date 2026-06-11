import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ink_n_motion/services/firestore_wallet_service.dart';
import 'package:ink_n_motion/utils/app_links.dart';
import 'package:ink_n_motion/utils/concept_image_loader.dart';
import 'package:ink_n_motion/utils/save_concept_image.dart';
import 'package:ink_n_motion/utils/share_origin.dart';
import 'package:ink_n_motion/screens/coverup_studio_picker.dart'
    if (dart.library.html) 'package:ink_n_motion/screens/coverup_studio_picker_web.dart'
    if (dart.library.io) 'package:ink_n_motion/screens/coverup_studio_picker_io.dart';
import 'package:share_plus/share_plus.dart';

enum _RevealMode { none, slider, shimmer }

/// Coverup Studio — upload existing tattoo photo and preview AI coverup concepts.
class CoverupStudioScreen extends StatefulWidget {
  const CoverupStudioScreen({super.key});

  @override
  State<CoverupStudioScreen> createState() => _CoverupStudioScreenState();
}

class _CoverupStudioScreenState extends State<CoverupStudioScreen>
    with SingleTickerProviderStateMixin {
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
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _resultImageUrl;
  Uint8List? _resultImageBytes;
  String? _errorMessage;

  // Reveal mode
  _RevealMode _revealMode = _RevealMode.none;
  double _sliderPosition = 0.5;
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;
  bool _shimmerRunning = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    ({Uint8List bytes, String name})? picked;

    if (kIsWeb) {
      picked = await pickCoverupImage();
    } else {
      final choice = await showCupertinoModalPopup<String>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Add Tattoo Photo'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop('camera'),
              child: const Text('Take Photo'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop('gallery'),
              child: const Text('Choose from Gallery'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );

      if (!mounted) return;
      if (choice == 'camera') {
        picked = await captureCoverupImage();
      } else if (choice == 'gallery') {
        picked = await pickCoverupImage();
      }
    }

    if (!mounted || picked == null) return;

    final result = picked;
    setState(() {
      _selectedImageBytes = result.bytes;
      _selectedImageName = result.name;
      _errorMessage = null;
    });
  }

  Future<void> _generateCoverup({bool isVariation = false}) async {
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

    final apiPrompt = isVariation
        ? '$prompt — fresh variation, reimagined composition'
        : prompt;

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

    if (wallet.totalBalance < InkTokenCost.coverupStudio) {
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
      _resultImageBytes = null;
      _revealMode = _RevealMode.none;
      _sliderPosition = 0.5;
      _shimmerRunning = false;
    });
    _shimmerController.stop();
    _shimmerController.reset();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://ink-n-motion-api.onrender.com/api/generate-coverup'),
      )
        ..fields['prompt'] = apiPrompt
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
        final imageUrl = data['imageUrl'] as String?;
        final resultBytes = imageUrl != null && imageUrl.isNotEmpty
            ? await loadConceptImageBytes(imageUrl)
            : null;
        if (!mounted) return;
        setState(() {
          _resultImageUrl = imageUrl;
          _resultImageBytes = (resultBytes != null && resultBytes.isNotEmpty)
              ? resultBytes
              : null;
        });
        await FirestoreWalletService.instance.deductTokens(
          uid,
          InkTokenCost.coverupStudio,
        );
      } else {
        setState(() {
          _errorMessage = 'Server error. Please try again.';
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Timed out — coverup renders can take up to 90 seconds';
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

  void _toggleShimmer() {
    setState(() {
      _shimmerRunning = !_shimmerRunning;
    });
    if (_shimmerRunning) {
      _shimmerController.repeat(reverse: true);
    } else {
      _shimmerController.stop();
      _shimmerController.reset();
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

  Future<void> _saveImage() async {
    final bytes = _resultImageBytes;
    if (bytes == null || bytes.isEmpty) return;

    if (kIsWeb) {
      _showNotice('Right-click the image to save');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await saveConceptImage(bytes, filename: 'ink_coverup');
      if (!mounted) return;
      if (saved) {
        _showNotice("Saved to your phone's Photos");
      } else {
        _showNotice(
          'Unable to save image. Allow Photos access and try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showNotice('Unable to save image. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareImage() async {
    final imageUrl = _resultImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;

    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: imageUrl));
      if (!mounted) return;
      _showNotice('Link copied to clipboard — paste into any app!');
      return;
    }

    final origin = shareOriginFromContext(context);
    setState(() => _isSaving = true);
    try {
      final bytes = await loadConceptImageBytes(imageUrl);
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        _showNotice('Unable to download image. Please try again.');
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          text: kShareMessage,
          files: [
            XFile.fromData(
              bytes,
              name: 'coverup_preview.png',
              mimeType: 'image/png',
            ),
          ],
          sharePositionOrigin: origin,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('CoverupStudioScreen._shareImage failed: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        _showNotice('Unable to share image. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmRegenerate() async {
    if (_isGenerating || _isSaving) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showNotice('Please wait while we set up your account.', title: 'Not Ready');
      return;
    }

    final wallet = await FirestoreWalletService.instance.getWallet(uid);
    if (wallet == null) {
      _showNotice(
        'Unable to load your token balance. Please try again.',
        title: 'Wallet Error',
      );
      return;
    }

    if (wallet.totalBalance < InkTokenCost.coverupStudio) {
      _showNotice(
        'You need 3 tokens for a coverup render. Visit the store to top up.',
        title: 'Not Enough Tokens',
      );
      return;
    }

    if (!mounted) return;
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Generate New Variation?'),
        content: const Text(
          'This will use 3 tokens and create a fresh interpretation of your '
          'coverup. Results will vary from the previous render.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(_generateCoverup(isVariation: true));
            },
            child: const Text('Use 3 Tokens'),
          ),
        ],
      ),
    );
  }

  void _showUnsavedRenderDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Unsaved Render'),
        content: const Text(
          'Your coverup preview will be lost if you go back. Save or share it first.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Go Back'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay & Save'),
          ),
        ],
      ),
    );
  }

  void _handlePopInvoked(bool didPop, Object? result) {
    if (didPop) return;
    if (_resultImageUrl == null || _isSaving) {
      Navigator.of(context).pop();
      return;
    }
    _showUnsavedRenderDialog();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePopInvoked,
      child: CupertinoPageScaffold(
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
                    onPressed: () => Navigator.maybePop(context),
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
                    style: TextStyle(color: _snippetGrey, fontSize: 14),
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
                                Icon(CupertinoIcons.photo,
                                    color: _hintGrey, size: 40),
                                SizedBox(height: 12),
                                Text(
                                  'Tap to upload tattoo photo',
                                  style: TextStyle(
                                      color: _hintGrey, fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'JPG or PNG',
                                  style: TextStyle(
                                      color: _mutedGrey, fontSize: 12),
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
                        '3 tokens per render',
                        style: TextStyle(color: _gold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Tip: all-blackout tattoos or full sleeves may produce varied results.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _snippetGrey,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                                      color: CupertinoColors.black),
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
                                '✦ Generate Coverup Preview',
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
                    const Center(
                      child: Text(
                        'Results & times may vary — keep the app open, this can take a minute.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _snippetGrey,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
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
                            color: _errorRed, fontSize: 13),
                      ),
                    ),
                  ],
                  if (_resultImageUrl != null &&
                      _selectedImageBytes != null) ...[
                    const SizedBox(height: 28),
                    _RevealModeRow(
                      current: _revealMode,
                      onChanged: (mode) {
                        if (_shimmerRunning) {
                          _shimmerController.stop();
                          _shimmerController.reset();
                        }
                        setState(() {
                          _revealMode = mode;
                          _shimmerRunning = false;
                          _sliderPosition = 0.5;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your Coverup Preview',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_revealMode == _RevealMode.none)
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _resultImageBytes != null
                              ? Image.memory(
                                  _resultImageBytes!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        CupertinoIcons.photo,
                                        color: _snippetGrey,
                                        size: 48,
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(
                                    CupertinoIcons.photo,
                                    color: _snippetGrey,
                                    size: 48,
                                  ),
                                ),
                        ),
                      ),
                    if (_revealMode == _RevealMode.slider)
                      _DragRevealWidget(
                        originalBytes: _selectedImageBytes!,
                        resultBytes: _resultImageBytes,
                        sliderPosition: _sliderPosition,
                        onSliderChanged: (v) =>
                            setState(() => _sliderPosition = v),
                      ),
                    if (_revealMode == _RevealMode.shimmer)
                      _ShimmerRevealWidget(
                        originalBytes: _selectedImageBytes!,
                        resultBytes: _resultImageBytes,
                        shimmerAnimation: _shimmerAnimation,
                        shimmerRunning: _shimmerRunning,
                        onToggle: _toggleShimmer,
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
                          isLoading: _isSaving,
                          onTap: _isSaving ? null : _saveImage,
                        ),
                        _ActionButton(
                          label: 'Share',
                          icon: CupertinoIcons.share,
                          backgroundColor: _surface,
                          foregroundColor: CupertinoColors.white,
                          isLoading: _isSaving,
                          onTap: _isSaving ? null : _shareImage,
                        ),
                        _ActionButton(
                          label: 'Re-generate',
                          icon: CupertinoIcons.refresh,
                          backgroundColor: _gold,
                          foregroundColor: CupertinoColors.black,
                          onTap: (_isGenerating || _isSaving)
                              ? null
                              : _confirmRegenerate,
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
    ),
    );
  }
}

class _RevealModeRow extends StatelessWidget {
  const _RevealModeRow({
    required this.current,
    required this.onChanged,
  });

  final _RevealMode current;
  final ValueChanged<_RevealMode> onChanged;

  static const Color _snippetGrey = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reveal Options',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _ModeChip(
              label: 'Preview',
              icon: CupertinoIcons.eye,
              active: current == _RevealMode.none,
              onTap: () => onChanged(_RevealMode.none),
            ),
            const SizedBox(width: 8),
            _ModeChip(
              label: 'Drag Compare',
              icon: CupertinoIcons.arrow_left_right,
              active: current == _RevealMode.slider,
              onTap: () => onChanged(_RevealMode.slider),
            ),
            const SizedBox(width: 8),
            _ModeChip(
              label: 'Glow Through',
              icon: CupertinoIcons.sparkles,
              active: current == _RevealMode.shimmer,
              onTap: () => onChanged(_RevealMode.shimmer),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          current == _RevealMode.slider
              ? 'Drag the divider to compare old vs new'
              : current == _RevealMode.shimmer
                  ? 'Tap the glow button to reveal your original ink underneath'
                  : 'Tap a reveal option above to explore the result',
          style: const TextStyle(color: _snippetGrey, fontSize: 11),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _gold.withValues(alpha: 0.15) : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _gold : _border,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _gold : const Color(0xFF999999), size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? _gold : const Color(0xFF999999),
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragRevealWidget extends StatelessWidget {
  const _DragRevealWidget({
    required this.originalBytes,
    required this.resultBytes,
    required this.sliderPosition,
    required this.onSliderChanged,
  });

  final Uint8List originalBytes;
  final Uint8List? resultBytes;
  final double sliderPosition;
  final ValueChanged<double> onSliderChanged;

  static const double _height = 220;
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF333333);
  static const Color _snippetGrey = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              final newPos =
                  (sliderPosition + details.delta.dx / totalWidth).clamp(0.02, 0.98);
              onSliderChanged(newPos);
            },
            onTapDown: (details) {
              final newPos =
                  (details.localPosition.dx / totalWidth).clamp(0.02, 0.98);
              onSliderChanged(newPos);
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(
                    originalBytes,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: ClipRect(
                    clipper: _RightClipper(sliderPosition),
                    child: resultBytes != null
                        ? Image.memory(
                            resultBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  CupertinoIcons.photo,
                                  color: _snippetGrey,
                                  size: 48,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              CupertinoIcons.photo,
                              color: _snippetGrey,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: totalWidth * sliderPosition - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: _gold,
                  ),
                ),
                Positioned(
                  left: totalWidth * sliderPosition - 18,
                  top: _height / 2 - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF000000).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_left_right,
                      color: CupertinoColors.black,
                      size: 16,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xCC000000),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'BEFORE',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xCC000000),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AFTER',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RightClipper extends CustomClipper<Rect> {
  const _RightClipper(this.position);
  final double position;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width * position, 0, size.width, size.height);

  @override
  bool shouldReclip(_RightClipper oldClipper) =>
      oldClipper.position != position;
}

class _ShimmerRevealWidget extends StatelessWidget {
  const _ShimmerRevealWidget({
    required this.originalBytes,
    required this.resultBytes,
    required this.shimmerAnimation,
    required this.shimmerRunning,
    required this.onToggle,
  });

  final Uint8List originalBytes;
  final Uint8List? resultBytes;
  final Animation<double> shimmerAnimation;
  final bool shimmerRunning;
  final VoidCallback onToggle;

  static const double _height = 220;
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF333333);
  static const Color _snippetGrey = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: _height,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: shimmerAnimation,
            builder: (context, child) {
              final resultOpacity = (1.0 - shimmerAnimation.value * 0.85)
                  .clamp(0.0, 1.0);
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.memory(
                      originalBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: resultOpacity,
                      child: resultBytes != null
                          ? Image.memory(
                              resultBytes!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    CupertinoIcons.photo,
                                    color: _snippetGrey,
                                    size: 48,
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                color: _snippetGrey,
                                size: 48,
                              ),
                            ),
                    ),
                  ),
                  if (shimmerRunning)
                    Positioned.fill(
                      child: Opacity(
                        opacity: shimmerAnimation.value * 0.12,
                        child: Container(
                          color: _gold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: shimmerRunning
                  ? _gold.withValues(alpha: 0.15)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _gold,
                width: shimmerRunning ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  shimmerRunning
                      ? CupertinoIcons.stop_fill
                      : CupertinoIcons.sparkles,
                  color: _gold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  shimmerRunning ? 'Stop Glow' : '✦ Reveal Original Ink',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final bool isLoading;

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
        child: isLoading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: foregroundColor,
                ),
              )
            : Column(
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
