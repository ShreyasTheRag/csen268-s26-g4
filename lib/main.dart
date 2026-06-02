import 'dart:convert'; // Added for jsonDecode
import 'package:santa_clara/blocs/trip_bloc.dart';
import 'package:santa_clara/theme/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for rootBundle and PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

import 'blocs/authentication/bloc/authentication_bloc.dart';
import 'firebase_options.dart';
import 'navigation/router.dart';
import 'repositories/authentication/authentication_repository.dart';
import 'theme/cubit/theme_cubit.dart';
import 'theme/util.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // load MAPS_API_KEY from secrets.json
  String apiKey = "";
  if (!kIsWeb) {
  // iOS/Android only
  try {
      final secretsContent = await rootBundle.loadString('secrets.json');
      final Map<String, dynamic> secrets = jsonDecode(secretsContent);
      apiKey = secrets['MAPS_API_KEY'] ?? "";

      if (apiKey.isNotEmpty) {
        const MethodChannel platform = MethodChannel('com.example.app/google_maps');
        try {
          await platform.invokeMethod('initializeMaps', {"apiKey": apiKey});
          debugPrint("Google Maps API Key successfully passed to iOS native.");
        } on PlatformException catch (e) {
          debugPrint("Failed to pass API key to native iOS: ${e.message}");
        }
      }
    } catch (e) {
      debugPrint("Failed to load secrets.json: $e");
    }
  }

  // 3. Continue with the rest of your app configurations
  usePathUrlStrategy();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);
  Bloc.observer = const AppBlocObserver();
  runApp(MyApp());
}

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (bloc is Cubit) print(change);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    print(transition);
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "Roboto", "Playfair Display");
    MaterialTheme theme = MaterialTheme(textTheme);
    
    return RepositoryProvider(
      create: (context) {
        return AuthenticationRepository();
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthenticationBloc()
              ..add(AuthenticationInitializeEvent(
                authenticationRepository: context.read<AuthenticationRepository>(),
              )),
          ),
          BlocProvider(
          create: (context) => TripBloc(), 
        ),
          BlocProvider(
            create: (context) => ThemeCubit(),
          ),
        ],
        child: BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {},
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'Treksetter',
                theme: theme.light(),
                darkTheme: theme.dark(),
                highContrastTheme: theme.lightHighContrast(),
                highContrastDarkTheme: theme.darkHighContrast(),
                themeMode: state.themeMode,
                routerConfig: router(context.read<AuthenticationBloc>()),
              );
            },
          ),
        ),
      ),
    );
  }
}