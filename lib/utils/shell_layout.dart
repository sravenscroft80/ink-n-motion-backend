import 'package:flutter/cupertino.dart';

/// Layout constants for the persistent shell chrome.
abstract final class InkShellLayout {
  /// Height of the brand bar row below the system status inset.
  static const double topBarContentHeight = 52;

  /// [CupertinoTabScaffold] index for the Studio / capture tab.
  static const int studioTabIndex = 1;

  static double totalTopInset(BuildContext context) {
    return MediaQuery.paddingOf(context).top + topBarContentHeight;
  }
}
