import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/services/firestore.dart';

class HomeFeed extends ConsumerWidget {
  const HomeFeed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final result = ref.watch(FirestoreAPI.feedStreamProvider);

    return result.when(
      data: (items) {
        return ListView.separated(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            return ListTile(
              onTap: () =>
                  Navigator.of(context).pushNamed('/event', arguments: item),
              title: Text(item['title']),
              // subtitle: Text(item['created_at'].toDate().toString()),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 0),
        );
      },
      error: (e, __) => Text(e.toString()),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
