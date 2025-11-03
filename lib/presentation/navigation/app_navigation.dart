import 'package:go_router/go_router.dart';
import 'package:junie_ai_test/presentation/feature/github_repository/view/github_repo_screen.dart';

part 'route_name.dart';
part 'route_path.dart';

class AppNavigation {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: _RoutePath.home,
      routes: [
        GoRoute(
          path: _RoutePath.home,
          name: _RouteName.home,
          builder: (context, state) => GithubRepoScreen(),
        ),
        GoRoute(
          path: _RoutePath.repositories,
          name: _RouteName.repositories,
          builder: (context, state) => GithubRepoScreen(),
        ),
      ],
    );
  }
}
