import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/screens/create_hub_screen.dart';
import 'package:ink_n_motion/screens/gallery_screen.dart';
import 'package:ink_n_motion/screens/home_screen.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/shell/ink_shell_top_bar.dart';

/// Root shell with a fixed top brand bar and bottom [CupertinoTabBar].
class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  late final CupertinoTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController();
    _tabController.addListener(_syncShellTabProvider);
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncShellTabProvider);
    _tabController.dispose();
    super.dispose();
  }

  void _syncShellTabProvider() {
    ref.read(shellTabIndexProvider.notifier).state = _tabController.index;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(shellTabIndexProvider, (previous, next) {
      if (_tabController.index != next) {
        _tabController.index = next;
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InkShellTopBar(),
          Expanded(
            child: CupertinoTabScaffold(
              controller: _tabController,
              tabBar: CupertinoTabBar(
                backgroundColor: InkColors.backgroundPrimary.withValues(alpha: 0.94),
                activeColor: InkColors.accentGold,
                inactiveColor: InkColors.textTertiary,
                border: Border(
                  top: BorderSide(
                    color: InkColors.accentGold.withValues(alpha: 0.35),
                  ),
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.square_grid_2x2),
                    label: 'Discover',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.wand_stars),
                    label: 'Create',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.photo_on_rectangle),
                    label: 'Gallery',
                  ),
                ],
              ),
              tabBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return const HomeScreen();
                  case 1:
                    return const CreateHubScreen();
                  case 2:
                    return const GalleryScreen();
                  default:
                    return const HomeScreen();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
