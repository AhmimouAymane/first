import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final Function(dynamic user)? onSignedIn;
  final Function(String error)? onError;

  const GoogleSignInButton({
    super.key,
    this.onSignedIn,
    this.onError,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Listen to authentication events on web
    if (kIsWeb) {
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _handleWebSignIn(event.user);
        }
      });
    }
  }

  Future<void> _handleWebSignIn(GoogleSignInAccount user) async {
    setState(() => _isLoading = true);
    
    try {
      final firebaseUser = await GoogleAuthService.handleWebSignIn(user);
      if (firebaseUser != null && widget.onSignedIn != null) {
        widget.onSignedIn!(firebaseUser);
      }
    } catch (e) {
      if (widget.onError != null) {
        widget.onError!('Sign-in failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleMobileSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await GoogleAuthService.signInWithGoogle();
      if (user != null && widget.onSignedIn != null) {
        widget.onSignedIn!(user);
      }
    } catch (e) {
      if (widget.onError != null) {
        widget.onError!('Sign-in failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // On web, use Firebase Auth popup
    if (kIsWeb) {
      return _buildWebButton();
    }

    // On mobile, use google_sign_in package
    return _buildMobileButton();
  }

  Widget _buildWebButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        // For web, we'll use Firebase Auth's Google provider directly
        setState(() => _isLoading = true);
        try {
          final provider = GoogleAuthProvider();
          provider.addScope('email');
          
          final userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
          
          if (userCredential.user != null && widget.onSignedIn != null) {
            widget.onSignedIn!(userCredential.user);
          }
        } catch (e) {
          if (widget.onError != null) {
            widget.onError!('Sign-in failed: $e');
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      },
      icon: Image.asset(
        'assets/google_logo.png',
        height: 24,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
      ),
      label: const Text('Sign in with Google'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 2,
      ),
    );
  }

  Widget _buildMobileButton() {
    return ElevatedButton.icon(
      onPressed: _handleMobileSignIn,
      icon: Image.asset(
        'assets/google_logo.png',
        height: 24,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
      ),
      label: const Text('Sign in with Google'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 2,
      ),
    );
  }
}