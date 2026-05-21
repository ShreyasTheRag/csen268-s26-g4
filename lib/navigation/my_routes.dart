import 'package:santa_clara/pages/articles/articles_page.dart';
import 'package:santa_clara/pages/campsite/campsite_info.dart';
import 'package:santa_clara/pages/campsite/campsite_locator.dart';
import 'package:santa_clara/pages/planTripPage/plan_trip_page.dart';
import 'package:santa_clara/pages/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:santa_clara/pages/yourVehicle/your_vehicle_page.dart';

import '../pages/images/images_page.dart';

class MyRoutes {
  static MyRoute home = MyRoute(name: 'home', path: '/');
  static MyRoute signIn = MyRoute(name: 'signIn', path: '/signIn');
  static MyRoute error = MyRoute(name: 'error', path: '/error');
  static MyRoute verifyEmail =
      MyRoute(name: 'verifyEmail', path: '/verifyEmail');
  static MyRoute images = MyRoute(name: 'images', path: 'images');
  static MyRoute articles = MyRoute(name: 'articles', path: 'articles');
  static MyRoute chat = MyRoute(name: 'chat', path: 'chat');
  static MyRoute profileFriends =
      MyRoute(name: 'profileFriends', path: 'friends');
  static MyRoute profile = MyRoute(name: 'profile', path: 'profile');
  static MyRoute planTrip = MyRoute(name: 'Plan a Trip', path: 'planTrip');
  static MyRoute takePicture = MyRoute(name: 'takePicture', path: 'takePicture');
  static MyRoute campsiteSelector = MyRoute(name: 'Campsite Selector', path: 'campsiteSelector');
  static MyRoute campsiteInfo = MyRoute(name: 'Campsite Info', path: 'CampsiteInfoPage');
}

class IndexedRoutes {
  static List<MyRoute> routes = [
    MyRoute(
      name: MyRoutes.images.name,
      path: MyRoutes.images.path,
      label: 'Images',
      icon: Icons.image,
      child: const ImagesPage(),
    ),
    MyRoute(
        name: MyRoutes.articles.name,
        path: MyRoutes.articles.path,
        label: 'Articles',
        icon: Icons.text_snippet,
        child: const ArticlesPage()),
    MyRoute(
        name: MyRoutes.chat.name,
        path: MyRoutes.chat.path,
        label: 'Chat',
        icon: Icons.chat,
        child: const YourVehiclePage()),
    MyRoute(
        name: MyRoutes.profile.name,
        path: MyRoutes.profile.path,
        label: 'Profile',
        icon: Icons.person,
        child: const ProfilePage()), 
    MyRoute(
        name: MyRoutes.planTrip.name,
        path: MyRoutes.planTrip.path,
        label: 'Plan a Trip',
        icon: Icons.navigation,
        child: const PlanTripPage()),
    MyRoute(
        name: MyRoutes.campsiteSelector.name,
        path: MyRoutes.campsiteSelector.path,
        label: 'Campsite Selector',
        icon: Icons.travel_explore,
        child: const CampsiteLocatorPage()),
    MyRoute(
        name: MyRoutes.campsiteInfo.name,
        path: MyRoutes.campsiteInfo.path,
        label: 'Campsite Info',
        icon: Icons.forest,
        child: const CampsiteInfoPage()),
  ];

  int getIndex(String path) {
    return routes.indexWhere((route) {
      return path.contains(route.path);
    });
  }

  String getName(int index) {
    return routes[index].name;
  }
}

class MyRoute {
  final String name;
  final String path;
  String? label;
  IconData? icon;
  Widget? child;

  MyRoute(
      {required this.name,
      required this.path,
      this.icon,
      this.child,
      this.label});
}

class MyNavObserver extends NavigatorObserver {
  MyNavObserver() {
    log.onRecord.listen((e) => debugPrint('$e'));
  }

  final log = Logger('MyNavObserver');

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      log.info('didPush: ${route.str}, previousRoute= ${previousRoute?.str}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      log.info('didPop: ${route.str}, previousRoute= ${previousRoute?.str}');

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      log.info('didRemove: ${route.str}, previousRoute= ${previousRoute?.str}');

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      log.info('didReplace: new= ${newRoute?.str}, old= ${oldRoute?.str}');

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) =>
      log.info('didStartUserGesture: ${route.str}, '
          'previousRoute= ${previousRoute?.str}');

  @override
  void didStopUserGesture() => log.info('didStopUserGesture');
}

extension on Route<dynamic> {
  String get str => 'route(${settings.name}: ${settings.arguments})';
}
