import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/pages/home_feed.dart';
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
              Tab(text: 'Search'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/profile',
                    arguments: {'uid': FirebaseAuth.instance.currentUser?.uid});
              },
              icon: const Icon(Icons.people_outline_outlined),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            const HomeFeed(),
            FutureBuilder<List<Player>>(
                future: FirestoreAPI.getUsers(),
                builder: (context, snapshot) {
                  final players = snapshot.data ?? [];
                  print('HomePage.build $players');
                  return ListView.separated(
                    itemBuilder: (_, i) {
                      final player = players[i];
                      return ListTile(
                        onTap: () => Navigator.of(context).pushNamed(
                          ProfilePage.routeName,
                          arguments: {'uid': player.uid},
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Center(
                            child: Text(
                              player.displayName[0].toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        title: Text(
                          player.displayName,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemCount: players.length,
                  );
                }),
          ],
        ),
      ),
    );
  }
}
