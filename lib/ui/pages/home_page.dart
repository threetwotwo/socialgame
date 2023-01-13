import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socialgame/ui/pages/home_feed.dart';
import 'package:socialgame/ui/pages/messages_page.dart';
import 'package:socialgame/ui/pages/profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/shop',
                  arguments: {'uid': FirebaseAuth.instance.currentUser?.uid});
            },
            icon: const Icon(Icons.storefront),
          ),
          centerTitle: true,
          title: const Text('OWO'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.transparent,
            tabs: [
              Tab(text: 'Explore'),
              Tab(text: 'Profile'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/search');
              },
              icon: const Icon(Icons.people_outline_outlined),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(MessagesPage.routeName);
              },
              icon: const Icon(Icons.markunread_mailbox_outlined),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            const HomeFeed(),
            ProfilePage(
              uid: FirebaseAuth.instance.currentUser?.uid,
            ),
          ],
        ),
      ),
    );
  }
}
