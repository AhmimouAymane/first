import 'package:flutter/material.dart';

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
          DrawerHeader(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/aymane.jpg'),
                  radius: 40,
                  
                ),
                const SizedBox(width: 16),
                Expanded(child: const Text('test user')),
              ],
            ),
          ),
          ExpansionTile(
            childrenPadding: const EdgeInsets.symmetric(horizontal: 20.0),
            title: Text('Image classification models'),
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text('ANN model'),
              ),
              ListTile(
                leading: Icon(Icons.image),
                title: Text('CNN model'),
              ),
            ],
          ),
          Divider(),
          const ListTile(
            leading: Icon(Icons.model_training),
            title: Text('Stock price prediction models'),
          ),
          Divider(),
          const ListTile(
            leading: Icon(Icons.assistant),
            title: Text('Vocal assistant'),
          ),
          Divider(),
          const ListTile(
            leading: Icon(Icons.home),
            title: Text('Accueil'),
          ),
          Divider(),
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text('Paramètres'),
          ),
          Divider(),
          const ListTile(
            leading: Icon(Icons.contact_mail),
            title: Text('Contactez-nous'),
          
          ),
           Divider(),
          const ListTile(
            leading: Icon(Icons.contact_mail),
            title: Text('Retrieval Augmented Generation Model'),
          
          ),
        ],
      ),
    );
  }
}