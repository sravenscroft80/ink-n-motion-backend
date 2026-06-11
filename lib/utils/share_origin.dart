import 'package:flutter/widgets.dart';

/// Anchor rect for the iPad share-sheet popover.
/// share_plus throws on iPad when [ShareParams.sharePositionOrigin] is absent.
Rect shareOriginFromContext(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final size = MediaQueryData.fromView(View.of(context)).size;
  return Rect.fromLTWH(0, 0, size.width, size.height / 2);
}
