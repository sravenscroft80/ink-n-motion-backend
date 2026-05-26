/// Premium cycling copy shown during simulated render pipelines.
abstract final class GenerationStatusMessages {
  static const List<String> pipelineSteps = [
    'Analyzing ink boundaries...',
    'Extracting tattoo dimensions...',
    'Injecting generative motion...',
    'Polishing frame rates...',
  ];

  static const Duration cycleInterval = Duration(milliseconds: 1500);
}
