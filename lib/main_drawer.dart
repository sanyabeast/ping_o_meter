import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.purple,
            ),
            child: Text(
              'Drawer Header',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.message),
            title: Text('Messages'),
          ),
          const ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
          ),
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
          ListTile(
            leading: const Icon(Icons.change_history),
            title: const Text('Change history'),
            onTap: () {
              // change app state...
              Navigator.pop(context); // close the drawer
            },
          ),
          Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 16, left: 16, right: 16),
              child: TextField(
                obscureText: true,
                onSubmitted: (String value) async {
                  await showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Thanks!'),
                        content: Text(
                            'You typed "$value", which has length ${value.characters.length}.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              )),
          Chip(
            avatar: CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: const Text('AB'),
            ),
            label: const Text('Aaron Burr'),
          )
        ],
      ),
    );
  }
}
