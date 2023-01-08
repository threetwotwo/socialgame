import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/widgets/AppDialog.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';

class ShopPage extends StatelessWidget {
  static const routeName = '/shop';

  const ShopPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(
        title: 'Shop',
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: FirestoreAPI.getShop(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};

          return ListView.builder(
              itemCount: data.keys.length,
              itemBuilder: (_, i) {
                var items = data.values.toList();
                //sort the items
                items.sort((a, b) => a['id'].compareTo(b['id']));
                return ShopItemListTile(
                  map: items[i],
                );
              });
        },
      ),
    );
  }
}

class ShopItemListTile extends StatelessWidget {
  // final String title;
  // final String emoji;
  // final String description;
  final Map<String, dynamic> map;
  final VoidCallback? onPressed;
  const ShopItemListTile({Key? key, required this.map, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = map['name'] ?? 'Name';
    final emoji = map['emoji'] ?? '';
    final description = map['description'] ?? '';
    final cost = map['cost'] ?? 0;

    return ListTile(
      onTap: () {
        AppDialog.show(context, 'Buy for coins?');
        onPressed;
        FirestoreAPI.buyShopItem(
            FirebaseAuth.instance.currentUser?.uid ?? '', map);
      },
      minLeadingWidth: 0,
      isThreeLine: true,
      leading: Text(
        emoji,
        style: TextStyle(fontSize: 28),
      ),
      title: Text(name),
      subtitle: Text(description),
      trailing: Text('$cost 🪙'),
    );
  }
}
