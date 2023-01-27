import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignInWithAppleWrapper {
  final List<AppleIDAuthorizationScopes> scopes;

  SignInWithAppleWrapper({required this.scopes});

  Future<AuthorizationCredentialAppleID>? getAppleIDCredential() async {
    return SignInWithApple.getAppleIDCredential(scopes: scopes);
  }
}
