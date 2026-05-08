part of 'authentication_bloc.dart';

@immutable
sealed class AuthenticationEvent {}

class AuthenticationInitializeEvent extends AuthenticationEvent {
  final AuthenticationRepository authenticationRepository;

  AuthenticationInitializeEvent({required this.authenticationRepository});
}

class AuthenticationErrorEvent extends AuthenticationEvent {
  final String error;

  AuthenticationErrorEvent({required this.error});
}

class AuthenticationSignInEvent extends AuthenticationEvent {}

class AuthenticationSignOutEvent extends AuthenticationEvent {}

class AuthenticationSignedOutEvent extends AuthenticationEvent {}

class AuthenticationSignedInEvent extends AuthenticationEvent {}

class AuthenticationEmailVerificationRequest extends AuthenticationEvent {}

class AuthenticationEmailVerificationCancelRequest
    extends AuthenticationEvent {}

class AuthenticationEmailVerificationScreenEvent extends AuthenticationEvent {}
