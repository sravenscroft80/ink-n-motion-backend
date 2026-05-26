/// Structured bad-output reasons for the refund tagging selector.
class RefundReasonOption {
  const RefundReasonOption({required this.id, required this.label});

  final String id;
  final String label;

  static const distortedLinework = RefundReasonOption(
    id: 'distorted_linework',
    label: 'Distorted Linework / Blurry Art',
  );

  static const incorrectPlacement = RefundReasonOption(
    id: 'incorrect_placement',
    label: 'Incorrect Placement / Anatomy Distortion',
  );

  static const animationGlitch = RefundReasonOption(
    id: 'animation_glitch',
    label: 'Animation Glitch / Choppy Frames',
  );

  static const incorrectColor = RefundReasonOption(
    id: 'incorrect_color',
    label: 'Incorrect Color Extraction',
  );

  static const List<RefundReasonOption> all = [
    distortedLinework,
    incorrectPlacement,
    animationGlitch,
    incorrectColor,
  ];
}
