import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/voice_assistant_screen.dart';
import '../services/google_auth_service.dart';
import '../screens/test_cnn_page.dart';

class MyMenu2 extends StatefulWidget {
  const MyMenu2({super.key});

  @override
  State<MyMenu2> createState() => _MyMenu2State();
}

class _MyMenu2State extends State<MyMenu2> {
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Déconnexion',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(
              color: Color(0xFF9E9E9E),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Close the drawer first
      if (mounted) Navigator.pop(context);

      try {
        // Sign out from Google (if signed in with Google)
        await GoogleAuthService.signOut();
        
        // This will also trigger authStateChanges which navigates to login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Déconnexion réussie'),
              backgroundColor: const Color(0xFF5CFBAC),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
              backgroundColor: const Color(0xFFFF5252),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
          // Header with user info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF121212),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF5CFBAC).withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final displayName = user?.displayName ?? 'Utilisateur';
                final email = user?.email ?? 'email@example.com';
                final photoUrl = user?.photoURL;

                return Column(
                  children: [
                    // Profile Picture or Initials
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF5CFBAC),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5CFBAC).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: photoUrl != null
                          ? CircleAvatar(
                              radius: 37,
                              backgroundImage: NetworkImage(photoUrl),
                              backgroundColor: const Color(0xFF1E1E1E),
                            )
                          : CircleAvatar(
                              radius: 37,
                              backgroundColor: const Color(0xFF5CFBAC),
                              child: Text(
                                _getInitials(displayName),
                                style: const TextStyle(
                                  color: Color(0xFF121212),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),

          // Scrollable menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                
                // Main navigation
                _buildListTile(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Accueil',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                // AI Models Section
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.smart_toy_outlined,
                      color: Color(0xFF5CFBAC),
                    ),
                    title: const Text(
                      'AI Models',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    iconColor: const Color(0xFF5CFBAC),
                    collapsedIconColor: const Color(0xFF9E9E9E),
                    childrenPadding: const EdgeInsets.only(left: 20),
                    children: [
                      _buildSubListTile(
                        context,
                        icon: Icons.image_outlined,
                        title: 'ANN Model',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      _buildSubListTile(
                        context,
                        icon: Icons.image,
                        title: 'CNN Model',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CNNTestPage(),
                            ),
                          );
                        },
                      ),
                      _buildSubListTile(
                        context,
                        icon: Icons.show_chart,
                        title: 'Stock Price Prediction',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      _buildSubListTile(
                        context,
                        icon: Icons.search,
                        title: 'RAG Model',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),

                _buildListTile(
                  context,
                  icon: Icons.mic_outlined,
                  title: 'Assistant vocal',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoiceAssistantScreen(),
                      ),
                    );
                  },
                ),

                _buildListTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                _buildListTile(
                  context,
                  icon: Icons.contact_mail_outlined,
                  title: 'Contactez-nous',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: const Color(0xFF2E2E2E),
                    thickness: 1,
                  ),
                ),
                const SizedBox(height: 8),

                _buildListTile(
                  context,
                  icon: Icons.logout,
                  title: 'Déconnexion',
                  isLogout: true,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),

          // Footer section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFF2E2E2E),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5CFBAC),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? const Color(0xFFFF5252) : const Color(0xFF5CFBAC),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? const Color(0xFFFF5252) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        hoverColor: const Color(0xFF5CFBAC).withOpacity(0.1),
      ),
    );
  }

  Widget _buildSubListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          size: 18,
          color: const Color(0xFF9E9E9E),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9E9E9E),
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        hoverColor: const Color(0xFF5CFBAC).withOpacity(0.1),
      ),
    );
  }
}