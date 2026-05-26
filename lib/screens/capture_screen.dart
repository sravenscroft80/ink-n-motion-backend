import 'dart:async';

import 'package:camera/camera.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';

import 'package:ink_n_motion/data/style_template_catalog.dart';
import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';
import 'package:ink_n_motion/screens/easy_video_preview_screen.dart';
import 'package:ink_n_motion/screens/premium_video_generation_screen.dart';
import 'package:ink_n_motion/services/image_asset_service.dart';
import 'package:ink_n_motion/utils/concept_image_loader.dart';
import 'package:ink_n_motion/utils/navigation.dart';

import 'package:ink_n_motion/utils/asset_flow.dart';

import 'package:ink_n_motion/utils/design_tokens.dart';

import 'package:ink_n_motion/utils/studio_style_mapper.dart';

import 'package:ink_n_motion/utils/ink_haptics.dart';

import 'package:ink_n_motion/widgets/capture/captured_image_view.dart';

import 'package:ink_n_motion/widgets/capture/shutter_flash_overlay.dart';

import 'package:ink_n_motion/widgets/capture/studio_controls.dart';

import 'package:ink_n_motion/widgets/capture/studio_style_picker.dart';

import 'package:ink_n_motion/widgets/capture/tattoo_reticle_overlay.dart';

import 'package:ink_n_motion/state/providers.dart';



/// Live camera capture with shutter flash, review, and style-picker handoff.

class CaptureScreen extends ConsumerStatefulWidget {

  const CaptureScreen({

    super.key,

    this.embeddedInShell = false,

    this.discoverySummary,

    this.generatedConceptUrl,

  });



  /// When true, omits the navigation bar — the shell top bar is shown instead.

  final bool embeddedInShell;

  /// Optional AI Coach blueprint used to pre-select a motion style.

  final TattooDiscoverySummary? discoverySummary;

  /// Optional AI-generated concept image from AI Coach handoff.

  final String? generatedConceptUrl;



  @override

  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();

}



class _CaptureScreenState extends ConsumerState<CaptureScreen> {

  final GlobalKey<ShutterFlashOverlayState> _flashKey = GlobalKey();

  final ImageAssetService _imageAssetService = ImageAssetService();

  CameraController? _cameraController;

  bool _initializing = true;

  String? _initError;

  String? _capturedPath;

  Uint8List? _capturedBytes;

  String? _selectedStyleLabel;

  bool _isCapturing = false;

  String? _loadedHandoffUrl;

  bool get _isReviewing =>
      _capturedPath != null || (_capturedBytes != null && _capturedBytes!.isNotEmpty);



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      _ensureDefaultStyle();

      unawaited(_loadHandoffConceptImage());

    });

    _initializeCamera();

  }



  @override

  void didUpdateWidget(CaptureScreen oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (oldWidget.generatedConceptUrl != widget.generatedConceptUrl) {

      WidgetsBinding.instance.addPostFrameCallback((_) {

        unawaited(_loadHandoffConceptImage());

      });

    }

  }



  Future<void> _loadHandoffConceptImage() async {

    final imageSource = widget.generatedConceptUrl ??

        ref.read(studioHandoffProvider)?.generatedImageUrl;

    if (imageSource == null || imageSource.trim().isEmpty) return;

    if (_loadedHandoffUrl == imageSource) return;



    final bytes = await loadConceptImageBytes(imageSource);

    if (!mounted || bytes == null || bytes.isEmpty) return;



    _loadedHandoffUrl = imageSource;

    _applySelectedImage('ai_coach_concept.png', bytes: bytes);

    ref.read(studioHandoffProvider.notifier).state = null;

  }



  void _ensureDefaultStyle() {

    final notifier = ref.read(appStateProvider.notifier);

    final handoffTemplate =
        StudioStyleMapper.templateIdForSummary(widget.discoverySummary);

    if (handoffTemplate != null) {
      notifier.setSelectedStyleTemplate(handoffTemplate);
      final match = StudioStylePicker.allStudioOptions.firstWhere(
        (option) => option.templateId == handoffTemplate,
        orElse: () => StudioStylePicker.allStudioOptions.first,
      );
      if (mounted) {
        setState(() => _selectedStyleLabel = match.label);
      }
      return;
    }

    if (widget.embeddedInShell) {
      return;
    }

    final currentId = ref.read(appStateProvider).selectedStyleTemplateId;

    if (currentId == null) {
      notifier.setSelectedStyleTemplate(
        StudioStylePicker.defaultOptions[1].templateId,
      );
      if (mounted) {
        setState(() {
          _selectedStyleLabel = StudioStylePicker.defaultOptions[1].label;
        });
      }
    }
  }

  void _applySelectedImage(String path, {Uint8List? bytes}) {
    setState(() {
      _capturedPath = path;
      _capturedBytes = bytes;
    });
    commitSelectedImage(ref, path, bytes: bytes);
  }

  void _onStyleSelected(StudioStyleOption option) {
    setState(() => _selectedStyleLabel = option.label);
  }

  void _onGenerateDesignConcept() {
    if (!_isReviewing || _selectedStyleLabel == null) return;

    final styleId = ref.read(appStateProvider).selectedStyleTemplateId;
    final template = StyleTemplateCatalog.findById(styleId);
    if (template == null) return;

    final path = _capturedPath;
    if (path != null) {
      commitSelectedImage(ref, path, bytes: _capturedBytes);
    }

    if (template.isPremium) {
      pushCupertino(context, const PremiumVideoGenerationScreen());
      return;
    }
    pushCupertino(context, const EasyVideoPreviewScreen());
  }



  @override

  void dispose() {

    if (!kIsWeb) {
      _cameraController?.dispose();
    }

    super.dispose();

  }



  Future<void> _initializeCamera() async {

    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _initError = null;
      });
      return;
    }

    setState(() {

      _initializing = true;

      _initError = null;

    });



    try {

      final cameras = await availableCameras();

      if (cameras.isEmpty) {

        throw CameraException('no_camera', 'No cameras available on this device.');

      }



      final camera = cameras.firstWhere(

        (description) => description.lensDirection == CameraLensDirection.back,

        orElse: () => cameras.first,

      );



      final controller = CameraController(

        camera,

        ResolutionPreset.high,

        enableAudio: false,

        imageFormatGroup: ImageFormatGroup.jpeg,

      );



      await controller.initialize();



      if (!mounted) {

        await controller.dispose();

        return;

      }



      await _cameraController?.dispose();

      setState(() {

        _cameraController = controller;

        _initializing = false;

      });

    } on CameraException catch (e) {

      _setInitError(e.description ?? e.code);

    } catch (e) {

      _setInitError(e.toString());

    }

  }



  void _setInitError(String message) {

    if (!mounted) return;

    setState(() {

      _initError = message;

      _initializing = false;

    });

  }



  Future<void> _onShutterPressed() async {

    if (kIsWeb) {
      await _captureWithImagePicker(ImageSource.camera);
      return;
    }

    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized || _isCapturing) {

      return;

    }



    setState(() => _isCapturing = true);

    await _flashKey.currentState?.flash();



    try {

      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {

        _capturedPath = file.path;

        _capturedBytes = bytes;

        _isCapturing = false;

      });

      commitSelectedImage(ref, file.path, bytes: bytes);

    } on CameraException catch (e) {

      if (!mounted) return;

      setState(() => _isCapturing = false);

      await _showErrorDialog(e.description ?? 'Capture failed.');

    } catch (_) {

      if (!mounted) return;

      setState(() => _isCapturing = false);

      await _showErrorDialog('Capture failed. Please try again.');

    }

  }



  Future<void> _captureWithImagePicker(ImageSource source) async {

    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    if (source == ImageSource.camera) {
      await _flashKey.currentState?.flash();
    }

    try {

      final result = await _imageAssetService.pickImage(source: source);

      if (!mounted) return;

      if (result == null) {
        setState(() => _isCapturing = false);
        return;
      }

      setState(() {

        _capturedPath = result.path;

        _capturedBytes = result.bytes;

        _isCapturing = false;

      });

      commitSelectedImage(ref, result.path, bytes: result.bytes);

    } catch (e) {

      if (!mounted) return;

      setState(() => _isCapturing = false);

      await _showErrorDialog(
        kIsWeb
            ? 'Unable to open the camera on this browser. Try Upload instead.'
            : 'Capture failed. Please try again.',
      );

    }

  }



  void _onRetake() {

    setState(() {
      _capturedPath = null;
      _capturedBytes = null;
    });

  }



  void _onUsePhoto() {

    final path = _capturedPath;

    if (path == null) return;

    commitSelectedImage(ref, path, bytes: _capturedBytes);

  }



  Future<void> _onSaveBlueprint() async {
    final handoff = ref.read(studioHandoffProvider);
    final text = handoff?.summary.reasoning?.trim() ?? '';
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Saved'),
        content: const Text('Prompt copied to clipboard.'),
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

  Future<void> _onShareBlueprint() async {
    final handoff = ref.read(studioHandoffProvider);
    final text = handoff?.summary.reasoning?.trim() ?? '';
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _pickFromGallery() async {

    final result = await _imageAssetService.pickImage(source: ImageSource.gallery);

    if (!mounted || result == null) return;

    _applySelectedImage(result.path, bytes: result.bytes);

  }



  Future<void> _showErrorDialog(String message) async {

    await InkHaptics.blockedOrError();

    if (!mounted) return;

    await showCupertinoDialog<void>(

      context: context,

      builder: (ctx) => CupertinoAlertDialog(

        title: const Text('Camera'),

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



  @override

  Widget build(BuildContext context) {

    final canPop = Navigator.of(context).canPop();

    final selectedStyleId = ref.watch(appStateProvider).selectedStyleTemplateId;



    return CupertinoPageScaffold(

      backgroundColor: InkColors.backgroundPrimary,

      navigationBar: widget.embeddedInShell

          ? null

          : CupertinoNavigationBar(

              backgroundColor:

                  InkColors.backgroundSecondary.withValues(alpha: 0.9),

              border: null,

              middle: Text(_isReviewing ? 'Review' : 'Capture'),

              leading: canPop

                  ? CupertinoNavigationBarBackButton(

                      previousPageTitle: 'Back',

                      onPressed: () => Navigator.of(context).maybePop(),

                    )

                  : null,

            ),

      child: Stack(

        children: [

          SafeArea(

            top: !widget.embeddedInShell,

            child: Column(

              children: [

                if (widget.embeddedInShell)

              Padding(

                padding: const EdgeInsets.fromLTRB(

                  InkSpacing.md,

                  InkSpacing.sm,

                  InkSpacing.md,

                  InkSpacing.xs,

                ),

                child: Row(

                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            'MOTION STUDIO',

                            style: InkTypography.sectionLabel,

                          ),

                          const SizedBox(height: InkSpacing.xs),

                          Text(

                            'Animate Your Ink',

                            style: InkTypography.largeTitle,

                          ),

                        ],

                      ),

                    ),

                    // Token balance pill

                    Container(

                      padding: const EdgeInsets.symmetric(

                        horizontal: 12,

                        vertical: 6,

                      ),

                      decoration: BoxDecoration(

                        color: InkColors.accentGold.withValues(alpha: 0.12),

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(

                          color: InkColors.accentGold.withValues(alpha: 0.35),

                          width: 1,

                        ),

                      ),

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Icon(

                            CupertinoIcons.sparkles,

                            size: 13,

                            color: InkColors.accentGold,

                          ),

                          const SizedBox(width: 4),

                          Text(
                            '10 tokens',
                            style: InkTypography.caption1.copyWith(
                              color: InkColors.accentGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

            Expanded(child: _buildPreviewArea()),

            if (widget.embeddedInShell)

              StudioStylePicker(

                options: StudioStylePicker.allStudioOptions,

                selectedTemplateId: selectedStyleId,

                selectedLabel: _selectedStyleLabel,

                onSelected: _onStyleSelected,

              ),

            _buildBottomControls(),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildPreviewArea() {

    return Padding(

      padding: const EdgeInsets.fromLTRB(InkSpacing.md, InkSpacing.xs, InkSpacing.md, InkSpacing.xs),

      child: _AnimatedStudioCanvasFrame(

        photoLoaded: _isReviewing,

        child: ShutterFlashOverlay(

          key: _flashKey,

          child: Stack(

            fit: StackFit.expand,

            children: [

              _buildPreviewContent(),

              if (!_isReviewing && !_initializing && _initError == null)

                const TattooReticleOverlay(),

              if (_initializing)

                const _CanvasLoadingState(),

              if (!_isReviewing &&

                  !_initializing &&

                  _initError == null &&

                  widget.embeddedInShell)

                _CanvasInputBar(

                  onCameraTap: _onShutterPressed,

                  onUploadTap: _pickFromGallery,

                ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildPreviewContent() {

    if (_initError != null) {

      return _CanvasPlaceholder(

        icon: CupertinoIcons.exclamationmark_triangle,

        title: 'Camera unavailable',

        subtitle: _initError!,

      );

    }



    if (_isReviewing) {

      return CapturedImageView(
        path: _capturedPath,
        bytes: _capturedBytes,
        onRetake: widget.embeddedInShell ? _onRetake : null,
      );

    }



    if (kIsWeb) {

      return const _CanvasPlaceholder(

        icon: CupertinoIcons.camera_circle,

        title: 'Studio canvas',

        subtitle: 'Step 1: Add your tattoo photo',

      );

    }



    final controller = _cameraController;

    if (controller != null && controller.value.isInitialized) {

      return CameraPreview(controller);

    }



    return const _CanvasPlaceholder(

      icon: CupertinoIcons.camera_circle,

      title: 'Canvas',

      subtitle: 'Camera feed or uploaded image',

    );

  }



  Widget _buildBottomControls() {

    if (_isReviewing && widget.embeddedInShell) {
      final selectedStyleId =
          ref.read(appStateProvider).selectedStyleTemplateId;
      final styleReady =
          selectedStyleId != null && _selectedStyleLabel != null;

      return StudioControls(
        bottomInset: MediaQuery.paddingOf(context).bottom,
        discoverySummary: widget.discoverySummary,
        isRenderingMotion: false,
        generateEnabled: styleReady,
        onGenerateDesignConcept: _onGenerateDesignConcept,
        onSave: _onSaveBlueprint,
        onShare: _onShareBlueprint,
      );
    }

    if (_isReviewing) {

      return Padding(

        padding: const EdgeInsets.fromLTRB(

          InkSpacing.lg,

          InkSpacing.sm,

          InkSpacing.lg,

          InkSpacing.lg,

        ),

        child: Row(

          children: [

            Expanded(

              child: CupertinoButton(

                onPressed: _onRetake,

                child: const Text('Retake'),

              ),

            ),

            const SizedBox(width: InkSpacing.md),

            Expanded(

              child: CupertinoButton.filled(

                onPressed: _onUsePhoto,

                child: const Text('Use Photo'),

              ),

            ),

          ],

        ),

      );

    }



    if (widget.embeddedInShell) {
      return StudioControls(
        bottomInset: MediaQuery.paddingOf(context).bottom,
        discoverySummary: widget.discoverySummary,
        isRenderingMotion: false,
        generateEnabled: false,
        onGenerateDesignConcept: _onGenerateDesignConcept,
        onSave: _onSaveBlueprint,
        onShare: _onShareBlueprint,
      );
    }



    return Padding(

      padding: const EdgeInsets.fromLTRB(

        InkSpacing.lg,

        0,

        InkSpacing.lg,

        InkSpacing.lg,

      ),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceEvenly,

        children: [

          _CaptureControl(

            icon: CupertinoIcons.photo,

            label: 'Photos',

            onTap: _pickFromGallery,

          ),

          _ShutterButton(

            enabled: !_initializing &&

                _initError == null &&

                !_isCapturing &&

                (kIsWeb || _cameraController != null),

            onTap: _onShutterPressed,

          ),

          _CaptureControl(

            icon: CupertinoIcons.camera_rotate,

            label: 'Retry',

            onTap: _initializeCamera,

          ),

        ],

      ),

    );

  }

}



class _AnimatedStudioCanvasFrame extends StatefulWidget {

  const _AnimatedStudioCanvasFrame({

    required this.photoLoaded,

    required this.child,

  });



  final bool photoLoaded;

  final Widget child;



  @override

  State<_AnimatedStudioCanvasFrame> createState() =>

      _AnimatedStudioCanvasFrameState();

}



class _AnimatedStudioCanvasFrameState extends State<_AnimatedStudioCanvasFrame>

    with SingleTickerProviderStateMixin {

  static const Color _midnight = Color(0xFF05070E);

  static const double _radius = 32;



  late AnimationController _borderController;



  @override

  void initState() {

    super.initState();

    _borderController = AnimationController(

      vsync: this,

      duration: const Duration(milliseconds: 2400),

    )..repeat(reverse: true);

  }



  @override

  void didUpdateWidget(covariant _AnimatedStudioCanvasFrame oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (widget.photoLoaded && !oldWidget.photoLoaded) {

      _borderController

        ..duration = const Duration(milliseconds: 750)

        ..forward(from: 0);

    } else if (!widget.photoLoaded && oldWidget.photoLoaded) {

      _borderController

        ..duration = const Duration(milliseconds: 2400)

        ..repeat(reverse: true);

    }

  }



  @override

  void dispose() {

    _borderController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return AnimatedBuilder(

      animation: _borderController,

      builder: (context, child) {

        final pulseAlpha = widget.photoLoaded

            ? 0.55 + _borderController.value * 0.45

            : 0.28 + _borderController.value * 0.32;



        return CustomPaint(

          painter: _CanvasBorderPainter(

            photoLoaded: widget.photoLoaded,

            pulseAlpha: pulseAlpha,

            radius: _radius,

          ),

          child: Container(

            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(_radius),

              color: _midnight,

              boxShadow: [

                BoxShadow(

                  color: InkColors.accentTeal.withValues(alpha: 0.14),

                  blurRadius: 36,

                  spreadRadius: -6,

                ),

                BoxShadow(

                  color: InkColors.accentGold.withValues(alpha: 0.06),

                  blurRadius: 48,

                  spreadRadius: -12,

                  offset: const Offset(0, 12),

                ),

              ],

            ),

            child: ClipRRect(

              borderRadius: BorderRadius.circular(_radius),

              child: Stack(

                fit: StackFit.expand,

                children: [

                  const DecoratedBox(

                    decoration: BoxDecoration(

                      gradient: RadialGradient(

                        center: Alignment(0, -0.15),

                        radius: 1.15,

                        colors: [

                          Color(0xFF101828),

                          Color(0xFF05070E),

                          Color(0xFF020308),

                        ],

                        stops: [0.0, 0.55, 1.0],

                      ),

                    ),

                  ),

                  Positioned.fill(

                    child: DecoratedBox(

                      decoration: BoxDecoration(

                        gradient: RadialGradient(

                          center: Alignment.center,

                          radius: 0.92,

                          colors: [

                            InkColors.accentTeal.withValues(alpha: 0.06),

                            CupertinoColors.transparent,

                          ],

                        ),

                      ),

                    ),

                  ),

                  widget.child,

                ],

              ),

            ),

          ),

        );

      },

    );

  }

}



class _CanvasBorderPainter extends CustomPainter {

  const _CanvasBorderPainter({

    required this.photoLoaded,

    required this.pulseAlpha,

    required this.radius,

  });



  final bool photoLoaded;

  final double pulseAlpha;

  final double radius;



  @override

  void paint(Canvas canvas, Size size) {

    final rect = RRect.fromRectAndRadius(

      Offset.zero & size,

      Radius.circular(radius),

    );

    final paint = Paint()

      ..color = InkColors.accentTeal.withValues(alpha: pulseAlpha.clamp(0.25, 1.0))

      ..style = PaintingStyle.stroke

      ..strokeWidth = photoLoaded ? 2 : 1.5;



    if (photoLoaded) {

      canvas.drawRRect(rect.deflate(1), paint);

      return;

    }



    final path = Path()..addRRect(rect.deflate(1));

    for (final metric in path.computeMetrics()) {

      const dashWidth = 8.0;

      const dashSpace = 6.0;

      var distance = 0.0;

      while (distance < metric.length) {

        final end = (distance + dashWidth).clamp(0.0, metric.length);

        canvas.drawPath(metric.extractPath(distance, end), paint);

        distance += dashWidth + dashSpace;

      }

    }

  }



  @override

  bool shouldRepaint(covariant _CanvasBorderPainter oldDelegate) {

    return oldDelegate.photoLoaded != photoLoaded ||

        oldDelegate.pulseAlpha != pulseAlpha;

  }

}



class _CanvasPlaceholder extends StatelessWidget {

  const _CanvasPlaceholder({

    required this.icon,

    required this.title,

    required this.subtitle,

  });



  final IconData icon;

  final String title;

  final String subtitle;



  @override

  Widget build(BuildContext context) {

    return Center(

      child: Padding(

        padding: const EdgeInsets.all(InkSpacing.xl),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Container(

              width: 72,

              height: 72,

              decoration: BoxDecoration(

                shape: BoxShape.circle,

                color: InkColors.accentGold.withValues(alpha: 0.12),

                boxShadow: [

                  BoxShadow(

                    color: InkColors.accentGold.withValues(alpha: 0.2),

                    blurRadius: 24,

                  ),

                ],

              ),

              child: Icon(

                icon,

                size: 34,

                color: InkColors.accentGold,

              ),

            ),

            const SizedBox(height: InkSpacing.md),

            Text(title, style: InkTypography.headline),

            const SizedBox(height: InkSpacing.xs),

            Text(

              subtitle,

              style: InkTypography.footnote.copyWith(

                color: InkColors.textSecondary,

              ),

              textAlign: TextAlign.center,

            ),

          ],

        ),

      ),

    );

  }

}



class _CanvasLoadingState extends StatelessWidget {

  const _CanvasLoadingState();



  @override

  Widget build(BuildContext context) {

    return ColoredBox(

      color: const Color(0xFF05070E).withValues(alpha: 0.72),

      child: const Center(child: InkActivityIndicator()),

    );

  }

}



class _CanvasInputBar extends StatelessWidget {

  const _CanvasInputBar({

    required this.onCameraTap,

    required this.onUploadTap,

  });



  final VoidCallback onCameraTap;

  final VoidCallback onUploadTap;



  @override

  Widget build(BuildContext context) {

    return Align(

      alignment: Alignment.bottomCenter,

      child: Padding(

        padding: const EdgeInsets.all(InkSpacing.md),

        child: Container(

          decoration: BoxDecoration(

            color: InkColors.backgroundPrimary.withValues(alpha: 0.72),

            borderRadius: BorderRadius.circular(16),

          ),

          child: Row(

            children: [

              Expanded(

                child: InkTactileButton(

                  onPressed: onCameraTap,

                  padding: const EdgeInsets.symmetric(vertical: InkSpacing.sm),

                  child: Row(

                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      Icon(

                        CupertinoIcons.camera_fill,

                        size: 18,

                        color: InkColors.accentGoldBright,

                      ),

                      const SizedBox(width: InkSpacing.xs),

                      Text(

                        'Camera',

                        style: InkTypography.footnote.copyWith(

                          color: InkColors.textPrimary,

                          fontWeight: FontWeight.w600,

                        ),

                      ),

                    ],

                  ),

                ),

              ),

              Container(

                width: 1,

                height: 28,

                color: InkColors.textPrimary.withValues(alpha: 0.1),

              ),

              Expanded(

                child: InkTactileButton(

                  onPressed: onUploadTap,

                  padding: const EdgeInsets.symmetric(vertical: InkSpacing.sm),

                  child: Row(

                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      Icon(

                        CupertinoIcons.photo_fill,

                        size: 18,

                        color: InkColors.accentTeal,

                      ),

                      const SizedBox(width: InkSpacing.xs),

                      Text(

                        'Upload',

                        style: InkTypography.footnote.copyWith(

                          color: InkColors.textPrimary,

                          fontWeight: FontWeight.w600,

                        ),

                      ),

                    ],

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



class _ShutterButton extends StatelessWidget {

  const _ShutterButton({

    required this.onTap,

    required this.enabled,

  });



  final VoidCallback onTap;

  final bool enabled;



  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: enabled ? onTap : null,

      child: Opacity(

        opacity: enabled ? 1 : 0.4,

        child: Container(

          width: 72,

          height: 72,

          decoration: BoxDecoration(

            shape: BoxShape.circle,

            border: Border.all(color: InkColors.textPrimary, width: 4),

          ),

          padding: const EdgeInsets.all(4),

          child: Container(

            decoration: const BoxDecoration(

              color: InkColors.textPrimary,

              shape: BoxShape.circle,

            ),

          ),

        ),

      ),

    );

  }

}



class _CaptureControl extends StatelessWidget {

  const _CaptureControl({

    required this.icon,

    required this.label,

    required this.onTap,

  });



  final IconData icon;

  final String label;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return CupertinoButton(

      padding: const EdgeInsets.symmetric(horizontal: InkSpacing.sm),

      onPressed: onTap,

      child: Column(

        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(icon, color: InkColors.textPrimary),

          const SizedBox(height: InkSpacing.xs),

          Text(label, style: InkTypography.caption1),

        ],

      ),

    );

  }

}


