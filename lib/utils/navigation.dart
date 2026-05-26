import 'package:flutter/cupertino.dart';

Future<T?> pushCupertino<T extends Object?>(
  BuildContext context,
  Widget page,
) {
  return Navigator.of(context).push<T>(
    CupertinoPageRoute<T>(builder: (_) => page),
  );
}
