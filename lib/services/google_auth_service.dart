import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  // Initialize Google Sign-In (call this once at app startup)
  static Future<void> initialize({
    String? clientId,
    String? serverClientId,
  }) async {
    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  // Method for Google Sign-In - works on mobile and web
  static Future<User?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;

      // Different flow for web vs mobile
      if (kIsWeb) {
        // On web, we need to listen to authentication events
        // The user should click the Google Sign-In button rendered by renderButton()
        // For programmatic sign-in on web, we use a workaround
        
        // Try to sign in silently first
        googleUser = await _googleSignIn.attemptLightweightAuthentication();
        
        if (googleUser == null) {
          // If silent sign-in fails, we need the user to interact with the button
          // This is a limitation of web - you need to use the renderButton() widget
          throw UnimplementedError(
            'On web, please use the Google Sign-In button widget. '
            'Call GoogleAuthService.getGoogleSignInButton() to get the button.'
          );
        }
      } else {
        // Mobile platforms (Android/iOS)
        googleUser = await _googleSignIn.authenticate(
          scopeHint: ['email'],
        );
      }

      // Get authorization for the required scopes
      final GoogleSignInClientAuthorization? authorization = 
          await googleUser.authorizationClient.authorizationForScopes(['email']);

      if (authorization == null) {
        print("Authorization failed");
        return null;
      }

      // Get the ID token from the authentication object
      final String? idToken = googleUser.authentication.idToken;
      final String accessToken = authorization.accessToken;

      if (idToken == null) {
        print("Failed to get ID token");
        return null;
      }

      // Create a credential using the Google authentication data
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on GoogleSignInException catch (e) {
      print("Google Sign-In Exception: ${e.code.name} - ${e.description}");
      return null;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      rethrow;
    }
  }

  // For web: Sign in via authentication events
  // This should be used when the user clicks the rendered Google Sign-In button
  static Future<User?> handleWebSignIn(GoogleSignInAccount googleUser) async {
    try {
      // Get authorization for the required scopes
      final GoogleSignInClientAuthorization? authorization = 
          await googleUser.authorizationClient.authorizationForScopes(['email']);

      if (authorization == null) {
        print("Authorization failed");
        return null;
      }

      // Get the ID token from the authentication object
      final String? idToken = googleUser.authentication.idToken;
      final String accessToken = authorization.accessToken;

      if (idToken == null) {
        print("Failed to get ID token");
        return null;
      }

      // Create a credential using the Google authentication data
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Error during web sign-in: $e");
      return null;
    }
  }

  // Check if authenticate is supported (false on web)
  static bool supportsAuthenticate() {
    return _googleSignIn.supportsAuthenticate();
  }

  // Sign out method
  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Disconnect (revoke access)
  static Future<void> disconnect() async {
    await _auth.signOut();
    await _googleSignIn.disconnect();
  }
}