import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/pages/home/home_page.dart';
import 'package:santa_clara/pages/signIn/sign_in_page.dart';
import 'package:santa_clara/pages/verifyEmail/verify_email_page.dart';
import 'package:santa_clara/utilities/stream_to_listenable.dart';
import 'package:santa_clara/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../pages/error/error_page.dart';
import '../pages/images/image_detail_page.dart';
import 'my_routes.dart';

List<GoRoute> shellRoutes = List.generate(IndexedRoutes.routes.length, (index) {
  return GoRoute(
    name: IndexedRoutes.routes[index].name,
    path: IndexedRoutes.routes[index].path,
    builder: (context, state) {
      return IndexedRoutes.routes[index].child ?? Container();
    },
  );
});

extension on GoRouterState {
  String get inf =>
      'name: $name fullPath: $fullPath matched: $matchedLocation \n'
      '         path: $path topRoute: ${topRoute?.path} ${uri.path}';
}

GoRouter router(AuthenticationBloc authenticationBloc) {
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: "Root");
  final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: "Shell");

  return GoRouter(
      //observers: [MyNavObserver()],
      navigatorKey: rootNavigatorKey,
      initialLocation: "/images",
      refreshListenable: StreamToListenable([authenticationBloc.stream]),
      redirect: (context, state) {
        AuthenticationState authenticationState =
            BlocProvider.of<AuthenticationBloc>(context).state;
        if (authenticationState is AuthenticationErrorState) {
          return MyRoutes.error.path;
        }
        if (authenticationState is AuthenticationVerifyEmailState ||
            authenticationState is AuthenticationEmailVerificationScreenState) {
          return MyRoutes.verifyEmail.path;
        }
        if (authenticationState is! AuthenticationSignedInState) {
          return MyRoutes.signIn.path;
        }
        if (state.fullPath?.startsWith("/signIn") ?? false) {
          return "/images";
        }
        return null;
      },
      routes: [
        GoRoute(
          name: MyRoutes.home.name,
          path: MyRoutes.home.path,
          builder: (context, state) => const HomePage(),
          routes: [
            ShellRoute(
              // observers: [MyNavObserver()],
              navigatorKey: shellNavigatorKey,
              routes: [
                GoRoute(
                    name: IndexedRoutes.routes[0].name,
                    path: IndexedRoutes.routes[0].path,
                    builder: (context, state) {
                      return IndexedRoutes.routes[0].child ?? Container();
                    },
                    routes: [
                      GoRoute(
                        parentNavigatorKey: rootNavigatorKey,
                        name: "imageDetail",
                        path: "imageDetail",
                        builder: (context, state) {
                          String imageUrl =
                              state.uri.queryParameters["imageUrl"] ?? "";

                          return ImageDetailPage(imageUrl: imageUrl);
                        },
                      )
                    ]),
                GoRoute(
                  name: IndexedRoutes.routes[1].name,
                  path: IndexedRoutes.routes[1].path,
                  builder: (context, state) {
                    return IndexedRoutes.routes[1].child ?? Container();
                  },
                ),
                GoRoute(
                  name: IndexedRoutes.routes[2].name,
                  path: IndexedRoutes.routes[2].path,
                  builder: (context, state) {
                    return IndexedRoutes.routes[2].child ?? Container();
                  },
                ),
                GoRoute(
                  name: IndexedRoutes.routes[3].name,
                  path: IndexedRoutes.routes[3].path,
                  builder: (context, state) {
                    return IndexedRoutes.routes[3].child ?? Container();
                  },
                )
              ],
              builder: (context, state, child) {
                return ScaffoldWithNavBar(
                  child: child,
                );
              },
            )
          ],
        ),
        GoRoute(
          name: MyRoutes.verifyEmail.name,
          path: MyRoutes.verifyEmail.path,
          builder: (context, state) => const VerifyEmailPage(),
        ),
        GoRoute(
          name: MyRoutes.signIn.name,
          path: MyRoutes.signIn.path,
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          name: MyRoutes.error.name,
          path: MyRoutes.error.path,
          builder: (context, state) => const ErrorPage(),
        ),
      ]);
}
