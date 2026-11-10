import 'package:go_router/go_router.dart';

import '../../screens/shell_demo_screens.dart';
import 'app_routes.dart';

/// A playground to compare [ShellRoute] with [StatefulShellRoute].
///
/// The same two-tab demo is built twice, with the same frame and the same
/// pages. Only the route type differs, so every difference you see comes
/// from it.
///
/// ```text
/// ShellRoute           /shell-demo/a           /shell-demo/b
/// StatefulShellRoute   /stateful-shell-demo/a  /stateful-shell-demo/b
/// child page of a tab  .../a/detail            .../b/detail
/// ```
///
/// Try it: raise the counter of tab A, open its child page, open tab B,
/// then come back to tab A.
/// - ShellRoute: tab A starts again from zero, without its child page.
/// - StatefulShellRoute: tab A is exactly as you left it.
List<RouteBase> shellDemoRoutes() {
  return [_shellRouteDemo(), _statefulShellRouteDemo()];
}

/// The last part of each tab's path: `/shell-demo/a`, `/shell-demo/b`.
const List<String> _tabs = ['a', 'b'];

/// ShellRoute: ONE Navigator shared by all the tabs.
///
/// A ShellRoute only draws a frame around the page of the current URL. It
/// knows nothing about tabs: switching tab is a plain `go` to another URL,
/// which replaces the old tab's pages with the new tab's page. The old
/// pages are thrown away, with their State.
ShellRoute _shellRouteDemo() {
  const String base = AppRoutes.shellDemo;
  return ShellRoute(
    builder: (context, state, child) => ShellDemoFrame(
      title: 'ShellRoute',
      location: state.uri.toString(),
      // There is no tab index to ask for: work it out from the URL,
      // `/shell-demo/b/detail` → 'b' → 1.
      currentIndex: _tabs.indexOf(state.uri.pathSegments[1]),
      onTabSelected: (index) => context.go('$base/${_tabs[index]}'),
      child: child,
    ),
    routes: [for (final String tab in _tabs) _tabRoute(base, tab)],
  );
}

/// StatefulShellRoute: one Navigator PER TAB (one per branch).
///
/// `goBranch` only changes which Navigator is shown. The other tabs stay
/// alive, hidden in an IndexedStack, with their pages and their State.
StatefulShellRoute _statefulShellRouteDemo() {
  const String base = AppRoutes.statefulShellDemo;
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => ShellDemoFrame(
      title: 'StatefulShellRoute',
      location: state.uri.toString(),
      currentIndex: navigationShell.currentIndex,
      onTabSelected: navigationShell.goBranch,
      child: navigationShell,
    ),
    branches: [
      for (final String tab in _tabs)
        StatefulShellBranch(routes: [_tabRoute(base, tab)]),
    ],
  );
}

/// `$base/$tab` and its child page `$base/$tab/detail`, the same in both
/// demos.
GoRoute _tabRoute(String base, String tab) {
  final String location = '$base/$tab';
  final String label = 'Tab ${tab.toUpperCase()}';

  return GoRoute(
    path: location,
    // No slide animation when switching tab in the ShellRoute demo, where
    // the new tab's page replaces the old one in the same Navigator.
    pageBuilder: (context, state) => NoTransitionPage<void>(
      key: state.pageKey,
      child: ShellDemoTabPage(label: label, location: location),
    ),
    routes: [
      GoRoute(
        path: 'detail',
        builder: (context, state) => ShellDemoChildPage(tabLabel: label),
      ),
    ],
  );
}
