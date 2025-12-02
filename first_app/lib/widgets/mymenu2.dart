import 'package:flutter/material.dart';
import '../screens/voice_assistant_screen.dart';

class MyMenu2 extends StatefulWidget {
  const MyMenu2({super.key});

  @override
  State<MyMenu2> createState() => _MyMenu2State();
}

class _MyMenu2State extends State<MyMenu2> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Enhanced header with gradient
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/aymane.jpg'),
                    radius: 40,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Test User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'user@example.com',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Main navigation
                _buildListTile(
                  context,
                  icon: Icons.home,
                  title: 'Accueil',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to home
                  },
                ),
                const Divider(height: 1),

                // AI Models Section
                ExpansionTile(
                  leading: const Icon(Icons.smart_toy),
                  title: const Text('AI Models'),
                  childrenPadding: const EdgeInsets.only(left: 32.0),
                  children: [
                    _buildSubListTile(
                      context,
                      icon: Icons.image_outlined,
                      title: 'ANN Model',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to ANN model
                      },
                    ),
                    _buildSubListTile(
                      context,
                      icon: Icons.image,
                      title: 'CNN Model',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to CNN model
                      },
                    ),
                    _buildSubListTile(
                      context,
                      icon: Icons.show_chart,
                      title: 'Stock Price Prediction',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to stock prediction
                      },
                    ),
                    _buildSubListTile(
                      context,
                      icon: Icons.search,
                      title: 'RAG Model',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to RAG model
                      },
                    ),
                  ],
                ),
                const Divider(height: 1),

                _buildListTile(
                  context,
                  icon: Icons.mic,
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
                const Divider(height: 1),

                _buildListTile(
                  context,
                  icon: Icons.settings,
                  title: 'Paramètres',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to settings
                  },
                ),
                const Divider(height: 1),

                _buildListTile(
                  context,
                  icon: Icons.contact_mail,
                  title: 'Contactez-nous',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to contact
                  },
                ),
              ],
            ),
          ),

          // Footer section
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
    );
  }

  Widget _buildSubListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      dense: true,
    );
  }
}
