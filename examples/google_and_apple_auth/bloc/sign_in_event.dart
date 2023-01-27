part of 'sign_in_bloc.dart';

@immutable
abstract class SignInEvent {}

class SignInWithEmailEvent extends SignInEvent {
  final String mail;
  final String password;

  SignInWithEmailEvent(this.mail, this.password);
}

class SignInWithAppleEvent extends SignInEvent {
  final bool isLogin;
  SignInWithAppleEvent(this.isLogin);
}

class SignInWithGoogleEvent extends SignInEvent {
  final bool isLogin;

  SignInWithGoogleEvent(this.isLogin);
}

class SignUpWithEmailEvent extends SignInEvent {
  final String mail;
  final String password;

  SignUpWithEmailEvent(this.mail, this.password);
}
