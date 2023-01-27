import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInWrapper {
  final List<String> scopes;

  GoogleSignInWrapper({required this.scopes});

  Future<String?> getGoogleIdToken() async {
    final googleAccount = await GoogleSignIn(scopes: scopes).signIn();
    final auth = await googleAccount?.authentication;
    return auth?.idToken;
  }

  Future<void> logoutWithGoogle() async {
    await GoogleSignIn().disconnect();
  }
}
