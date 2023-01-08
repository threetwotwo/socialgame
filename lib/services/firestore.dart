import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/player.dart';

class FirestoreAPI {
  static final shared = FirebaseFirestore.instance;

  ///Collection Refs
  static CollectionReference commandsColRef() => shared.collection('commands');

  static CollectionReference digSessionColRef() =>
      shared.collection('dig_sessions');

  static CollectionReference userColRef() => shared.collection('users');

  static CollectionReference feedColRef() => shared.collection('feed');

  static CollectionReference friendsColRef(String uid) =>
      userRef(uid).collection('friends');

  static CollectionReference friendRequestsColRef(String uid) =>
      userRef(uid).collection('friend_requests');

  static CollectionReference sessionColRef() => shared.collection('sessions');

  ///Document Refs
  static DocumentReference shopRef() => shared.collection('admin').doc('shop');

  static DocumentReference userRef(String uid) => userColRef().doc(uid);

  static DocumentReference userInventoryRef(String uid) =>
      shared.collection('user_inventory').doc(uid);

  static DocumentReference userStatsRef(String uid) =>
      shared.collection('user_stats').doc(uid);

  static DocumentReference friendRef(String uid, String friendId) =>
      friendsColRef(uid).doc(friendId);

  static DocumentReference friendRequestRef(String uid, String friendId) =>
      friendRequestsColRef(uid).doc(friendId);

  ///Streams
  static final digSessionStreamProvider =
      StreamProvider.autoDispose.family<Map<String, dynamic>?, String>(
    (ref, uid) => ref.watch(
      Provider(
        (ref) => sessionColRef()
            .where('uids', arrayContains: uid)
            .limit(1)
            .snapshots()
            .map((s) => s.docs.isEmpty
                ? null
                : s.docs.first.data() as Map<String, dynamic>),
      ),
    ),
  );

  static final feedStreamProvider =
      StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
    final stream = ref.watch(Provider((ref) =>
        feedColRef().orderBy('created_at', descending: true).snapshots()));
    return stream.map((snap) =>
        snap.docs.map((e) => e.data() as Map<String, dynamic>).toList());
  });

  static Stream<Map<String, dynamic>> userStatsStream(String uid) =>
      userStatsRef(uid)
          .snapshots()
          .map((snap) => snap.data() as Map<String, dynamic>);

  ///Functions

  static Future<Player> getUser(String uid) => userRef(uid)
      .get()
      .then((value) => Player.fromJson(value.data() as Map<String, dynamic>));

  static Future<Map<String, dynamic>> getUserStats(String uid) =>
      userStatsRef(uid)
          .get()
          .then((value) => (value.data() as Map<String, dynamic>));

  static Future<List<Player>> getUsers() => userColRef().get().then(
        (value) => value.docs.map((e) {
          return Player.fromJson(e.data() as Map<String, dynamic>);
        }).toList(),
      );

  static Future<List<Map<String, dynamic>>> getCommands() {
    return commandsColRef().get().then((snap) =>
        snap.docs.map((e) => e.data() as Map<String, dynamic>).toList());
  }

  static Future addPlayerCommand(Player user1, Player user2, String command) {
    final batch = shared.batch();

    final activityDocRef = feedColRef().doc();
    // final userDocRef = userRef(user1.uid);
    //add coins to user
    // batch.set(userDocRef, {'coins': FieldValue.increment(coins)},
    //     SetOptions(merge: true));
    //add activity to feed
    batch.set(activityDocRef, {
      'created_at': Timestamp.now(),
      'title': '${user1.displayName} $command ${user2.displayName}',
      'user_1': user1.uid,
      'user_2': user2.uid,
    });

    //change stats
    return batch.commit();
  }

  static Future<Map<String, dynamic>> getUserInventory(String uid) {
    return userInventoryRef(uid)
        .get()
        .then((snap) => snap.data() as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getShop() {
    return shopRef().get().then((snap) => snap.data() as Map<String, dynamic>);
  }

  ///1. Check if user can afford item
  ///2. Add item to user inventory
  ///3. Deduct coins
  static Future buyShopItem(String uid, Map<String, dynamic> item) {
    final data = item..addAll({'quantity': FieldValue.increment(1)});
    print('FirestoreAPI.buyShopItem ${data['name'].runtimeType}');
    final int cost = item['cost'] ?? 0;
    return userInventoryRef(uid)
        .set(
          {
            (data['name'].toString()): data,
          },
          SetOptions(merge: true),
        )
        .then((_) => userStatsRef(uid).set(
            {'coins': FieldValue.increment(-cost)}, SetOptions(merge: true)))
        .catchError(
          (e) => print('FirestoreAPI.buyShopItem $e'),
        );
  }

  static Future addCoins(
      {required Player user1, Player? user2, required int coins}) {
    final batch = shared.batch();

    final activityDocRef = feedColRef().doc();
    final user1StatsDocRef = userStatsRef(user1.uid);
    //add coins to user
    batch.set(
      user1StatsDocRef,
      {'coins': FieldValue.increment(coins)},
      SetOptions(merge: true),
    );
    if (user2 != null) {
      batch.set(
        userStatsRef(user2.uid),
        {'coins': FieldValue.increment(coins)},
        SetOptions(merge: true),
      );
    }

    final activityData = user2 == null
        ? {
            'created_at': Timestamp.now(),
            'title': '${user1.displayName} got $coins coin(s)',
          }
        : {
            'created_at': Timestamp.now(),
            'title':
                '${user1.displayName} & ${user2.displayName} got ${coins * 2} coin(s) 🪙',
          };

    //add activity to feed
    batch.set(activityDocRef, activityData);

    return batch.commit();
  }

  static Future addFriendRequest(Player friend) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) throw Exception('No current user');

    final uid = currentUser.uid;
    final friendId = friend.uid;

    final map = friend.toMap()..addAll({'created_at': Timestamp.now()});

    try {
      return friendRequestRef(uid, friendId).set(map);
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreAPI.addFriendRequest Error $e');
      }
    }

    return Future(() => null);
  }

  static Future addFriend(Player friend) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) throw Exception('No current user');
    final uid = currentUser.uid;
    final friendId = friend.uid;

    return shared.runTransaction((transaction) async {
      try {
        ///get current user
        final currentPlayer = await transaction.get(userRef(uid)).then(
            (value) => Player.fromJson(value.data() as Map<String, dynamic>));
        print('FirestoreAPI.addFriend ${currentPlayer.toMap()}');

        ///write to user's friends list
        final ref1 = friendRef(uid, friendId);
        final ref2 = friendRef(friendId, uid);
        print('FirestoreAPI.addFriend ref1 : ${ref1.path}');
        print('FirestoreAPI.addFriend ref2 : ${ref2.path}');
        transaction.set(ref1, friend.toMap());
        return transaction.set(ref2, currentPlayer.toMap());
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    });
  }

  static Future<Map<String, dynamic>> getDigSession(String uid) {
    final query = sessionColRef().where('uids', arrayContains: uid).limit(1);
    return query
        .get()
        .then((snap) => snap.docs.first.data() as Map<String, dynamic>);
  }

//TODO: complete for spouse too
  static Future completeDigSession(Player user, Map<String, dynamic> session) {
    final batch = shared.batch();
    //add coins to user
    final int coins = session['coins'] ?? 0;
    final sessionRef = sessionColRef().doc(session['id'] ?? '');
    // batch.update(userRef(user.uid), {'coins': FieldValue.increment(coins)});
    //delete session
    batch.delete(sessionRef);

    addCoins(user1: user, coins: coins);
    return batch.commit();
  }

  //create dig session
  static Future createDigSession(Player user, List<String> uids) async {
    final ref = sessionColRef().doc();
    final startTime = Timestamp.now();

    final digRate = await getAdminDigRate();
    //get end time
    const defaultEndTime = 90;
    final int duration = digRate?['duration'] ?? defaultEndTime;
    final endTime = Timestamp.fromMillisecondsSinceEpoch(
        startTime.millisecondsSinceEpoch + 1000 * duration);

    //GET COINS
    final minCoins = digRate?['min_coins'] ?? 0;
    final maxCoins = digRate?['max_coins'] ?? 0;
    final coins = Random().nextInt(maxCoins) + minCoins;

    //get coin rate
    final data = {
      'id': ref.id,
      'type': 'dig',
      'created_at': startTime,
      'end_time': endTime,
      'user': user.toMap(),
      'uids': uids,
      'coins': coins,
      'rate': digRate,
    };

    return ref.set(data, SetOptions(merge: true));
  }

  static Future divorce(Player user1, Player user2) {
    final batch = shared.batch();
    //update user1 doc
    final user1Ref = userRef(user1.uid);
    batch.update(user1Ref, {
      'married_to': FieldValue.delete(),
      'married_at': FieldValue.delete(),
    });
    //update user2 doc
    final user2Ref = userRef(user2.uid);
    batch.update(user2Ref, {
      'married_to': FieldValue.delete(),
      'married_at': FieldValue.delete(),
    });
    //make announcement
    final activityDocRef = feedColRef().doc();

    batch.set(activityDocRef, {
      'created_at': Timestamp.now(),
      'title': '${user1.displayName} divorced 💔 ${user2.displayName}',
      'user_1': user1.uid,
      'user_2': user2.uid,
    });

    return batch.commit();
  }

  static Future marry(Player user1, Player user2) {
    final batch = shared.batch();
    final date = Timestamp.now();
    //update user1 doc
    final user1Ref = userRef(user1.uid);
    batch.update(user1Ref, {
      'married_to': user2.uid,
      'married_at': date,
    });
    //update user2 doc
    final user2Ref = userRef(user2.uid);
    batch.update(user2Ref, {
      'married_to': user1.uid,
      'married_at': date,
    });
    //make announcement
    final activityDocRef = feedColRef().doc();

    batch.set(activityDocRef, {
      'created_at': Timestamp.now(),
      'title': '${user1.displayName} married 💍 ${user2.displayName}',
      'user_1': user1.uid,
      'user_2': user2.uid,
    });

    return batch.commit();
  }

  static Future<Map<String, dynamic>?> getAdminDigRate() {
    return shared.collection('admin').doc('dig').get().then((value) {
      print('FirestoreAPI.getAdminDigRate ${value.data()}');
      return value.data();
    });
  }

  static Future<int> getCoinRate() {
    return shared.collection('admin').doc('coin').get().then((value) {
      print('FirestoreAPI.getCoinRate ${value.data()}');
      return value.data()?['max'] ?? 1;
    });
  }
}
