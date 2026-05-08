import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/authentication/bloc/authentication_bloc.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Authentication Error"),
          ),
          body: Center(
            child: Text(state is AuthenticationErrorState
                ? state.error
                : "Unknown Error"),
          ),
        );
      },
    );
  }
}
