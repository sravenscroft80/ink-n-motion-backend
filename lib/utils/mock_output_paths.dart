import 'package:ink_n_motion/models/style_template.dart';

/// Builds local mock output paths for simulated render pipelines.
abstract final class MockOutputPaths {
  static String video({
    required String styleId,
    required StyleRenderingType renderingType,
  }) {
    final track = renderingType == StyleRenderingType.easy ? 'easy' : 'premium';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'mock://ink-n-motion/$track/$styleId/output_$stamp.mp4';
  }
}
