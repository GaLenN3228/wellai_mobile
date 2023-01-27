part of 'sign_in_bloc.dart';

@immutable
abstract class SignInState {}

class InitialSignInState extends SignInState {}

class LoadingSignInState extends SignInState {
  final bool isLoading;

  LoadingSignInState(this.isLoading);
}

class ErrorSignInState extends BaseBlocError implements SignInState {
  ErrorSignInState(Object e, StackTrace stackTrace) : super(e, stackTrace);
}

class SuccessSignInState extends SignInState {
  final DTOTokensResponse tokens;
  final String email;

  SuccessSignInState(this.tokens, {this.email = ''});
}
