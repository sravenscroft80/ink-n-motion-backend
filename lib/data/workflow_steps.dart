/// Data model and content for the Discover workflow carousel.
class WorkflowStep {
  const WorkflowStep({
    required this.assetPath,
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  final String assetPath;
  final String stepNumber;
  final String title;
  final String description;
}

abstract final class DiscoverWorkflowSteps {
  static const List<WorkflowStep> steps = [
    WorkflowStep(
      assetPath: 'assets/images/workflow/workflow_step_00_prepare.png',
      stepNumber: '00',
      title: 'Prepare',
      description:
          'A wide-angle photo of a client relaxing in a modern studio chair, '
          'consulting with the artist about their tattoo vision.',
    ),
    WorkflowStep(
      assetPath: 'assets/images/workflow/workflow_step_01_capture.png',
      stepNumber: '01',
      title: 'Capture',
      description:
          'A close-up, high-contrast photo of a person snapping a picture of a '
          'fresh tattoo, using the in-app camera (Studio tab).',
    ),
    WorkflowStep(
      assetPath: 'assets/images/workflow/workflow_step_02_select.png',
      stepNumber: '02',
      title: 'Select',
      description:
          'A photo focusing on the tablet screen (Studio tab), showing a grid '
          'of the distinct motion styles (e.g., Fluid, Sparkle, Neon).',
    ),
    WorkflowStep(
      assetPath: 'assets/images/workflow/workflow_step_03_render.png',
      stepNumber: '03',
      title: 'Render',
      description:
          'A screen recording capture of the progress bar, titled '
          '"TRANSFORMING STATIC TO MOTION."',
    ),
    WorkflowStep(
      assetPath: 'assets/images/workflow/workflow_step_04_share.png',
      stepNumber: '04',
      title: 'Share',
      description:
          'A view of the client using their smartphone to post the finalized '
          'motion-art video directly to their social media feed.',
    ),
  ];
}
