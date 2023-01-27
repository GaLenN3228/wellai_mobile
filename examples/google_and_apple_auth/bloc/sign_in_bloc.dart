import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wellai_flutter/managers/error_handler/error_handler.dart';
import 'package:wellai_flutter/network/models/dto_models/wellai_models/request/dto_login_request.dart';
import 'package:wellai_flutter/network/models/dto_models/wellai_models/request/dto_signup_request.dart';
import 'package:wellai_flutter/network/models/dto_models/wellai_models/response/dto_tokens_reaponse.dart';
import 'package:wellai_flutter/network/repository/global_repository.dart';
import 'package:wellai_flutter/screens/sign_up_screen/wrappers/sign_in_with_apple_wrapper.dart';
import 'package:wellai_flutter/screens/sign_up_screen/wrappers/sign_in_with_google_wrapper.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

///TODO check if need loading states
///
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final GlobalRepository _globalRepository;

  final GoogleSignInWrapper _googleSignIn;
  final SignInWithAppleWrapper _signInWithApple;

  SignInBloc(this._globalRepository, this._googleSignIn, this._signInWithApple) : super(InitialSignInState()) {
    on<SignInWithEmailEvent>(_onSignInWithEmailEvent);
    on<SignInWithAppleEvent>(_onSignInWithAppleEvent);
    on<SignInWithGoogleEvent>(_onSignInWithGoogleEvent);
    on<SignUpWithEmailEvent>(_onSignUpWithEmailEvent);
  }

  ///Event for login with email
  void _onSignInWithEmailEvent(SignInWithEmailEvent event, Emitter<SignInState> emit) async {
    try {
      emit(LoadingSignInState(true));
      final token =
          await _globalRepository.loginWithEmail(DTOLoginRequest(email: event.mail, password: event.password));
      emit(LoadingSignInState(false));
      emit(SuccessSignInState(token));
    } catch (e, stackTrace) {
      emit(LoadingSignInState(false));
      emit(ErrorSignInState(e, stackTrace));
      if (kDebugMode) rethrow;
    }
  }

  ///Api not ready yet
  ///Event to authorize with Apple account
  void _onSignInWithAppleEvent(SignInWithAppleEvent event, Emitter<SignInState> emit) async {
    try {
      final credential = await _signInWithApple.getAppleIDCredential();
      if (credential != null) {
        final token = await _globalRepository.loginWithApple(
          credential.identityToken,
          isLogin: event.isLogin,
        );
        emit(SuccessSignInState(token));
      }
      log(credential.toString());
    } on SignInWithAppleAuthorizationException {
      emit(LoadingSignInState(false));
    } catch (e, stackTrace) {
      emit(ErrorSignInState(e, stackTrace));
    }
  }

  ///Event to authorize with Google account
  void _onSignInWithGoogleEvent(SignInWithGoogleEvent event, Emitter<SignInState> emit) async {
    try {
      final googleAccount = await _googleSignIn.getGoogleIdToken();
      if (googleAccount != null) {
        final token = await _globalRepository.loginWithGoogle(googleAccount, isLogin: event.isLogin);
        await _googleSignIn.logoutWithGoogle();
        emit(SuccessSignInState(token));
      }
    } catch (e, stackTrace) {
      emit(ErrorSignInState(e, stackTrace));
      await _googleSignIn.logoutWithGoogle();
    }
  }

  ///Event to sign up with email
  void _onSignUpWithEmailEvent(SignUpWithEmailEvent event, Emitter<SignInState> emit) async {
    try {
      emit(LoadingSignInState(true));
      final token = await _globalRepository
          .signUpWithEmail(DTOSignUpWithEmailRequest(email: event.mail, password: event.password, invite: ""));
      emit(LoadingSignInState(false));
      emit(SuccessSignInState(token, email: event.mail));
    } catch (e, stackTrace) {
      emit(LoadingSignInState(false));
      emit(ErrorSignInState(e, stackTrace));
    }
  }
}
