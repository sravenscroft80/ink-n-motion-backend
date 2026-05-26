import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/screens/discover/style_detail_screen.dart';

/// Named route paths for Discover pillar deep-links.
abstract final class InkRoutes {
  static const String inkChronicles = '/discover/ink-chronicles';
  static const String artistSpotlight = '/discover/artist-spotlight';
  static const String styleArchive = '/discover/style-archive';
  static const String aiCoach = '/discover/ai-coach';

  static const String styleDetailPrefix = '/discover/style-archive/detail/';

  static String styleDetail(String styleId) => '$styleDetailPrefix$styleId';

  static String? parseStyleDetailId(String? routeName) {
    if (routeName == null || !routeName.startsWith(styleDetailPrefix)) {
      return null;
    }
    final styleId = routeName.substring(styleDetailPrefix.length);
    return styleId.isEmpty ? null : styleId;
  }
}

/// Central navigation helpers for [CupertinoApp] and [Navigator].
abstract final class InkNavigation {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final styleId = InkRoutes.parseStyleDetailId(settings.name);
    if (styleId != null) {
      return CupertinoPageRoute<void>(
        settings: settings,
        builder: (_) => StyleDetailScreen(styleId: styleId),
      );
    }
    return null;
  }

  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName,
  ) {
    return Navigator.of(context).pushNamed<T>(routeName);
  }

  static Future<T?> pushStyleDetail<T extends Object?>(
    BuildContext context,
    String styleId,
  ) {
    return pushNamed<T>(context, InkRoutes.styleDetail(styleId));
  }
}
