import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/player.dart';

class FirestoreAPI {
  static final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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

  static CollectionReference messageColRef() => shared.collection('messages');

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
  static final bakeSessionStreamProvider =
      StreamProvider.autoDispose.family<Map<String, dynamic>?, String>(
    (ref, uid) => ref.watch(
      Provider(
        (ref) => sessionColRef()
            .where('uids', arrayContains: uid)
            .where('type', isEqualTo: 'bake')
            .limit(1)
            .snapshots()
            .map((s) => s.docs.isEmpty
                ? null
                : s.docs.first.data() as Map<String, dynamic>),
      ),
    ),
  );

  static final digSessionStreamProvider =
      StreamProvider.autoDispose.family<Map<String, dynamic>?, String>(
    (ref, uid) => ref.watch(
      Provider(
        (ref) => sessionColRef()
            .where('uids', arrayContains: uid)
            .where('type', isEqualTo: 'dig')
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
  ///
  ///
  static applyBuff(String uid, {required Map<String, dynamic> buff}) {
    return userRef(uid).update(
      {
        'buffs': {
          buff['type']: buff..addAll({'created_at': Timestamp.now()})
        },
      },
    );
  }

  static removeBuff(String uid, {required Map<String, dynamic> buff}) {
    return userRef(uid).update(
      {
        'buffs': {buff['type']: null},
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getFriendsMap() =>
      friendsColRef(FirebaseAuth.instance.currentUser?.uid ?? '')
          .get()
          .then((value) {
        print('FirestoreAPI.getFriends ${value.docs.first.data()}');
        return value.docs.map((e) {
          return (e.data() as Map<String, dynamic>);
        }).toList();
      });

  static Future<List<Player>> getFriends() =>
      friendsColRef(FirebaseAuth.instance.currentUser?.uid ?? '')
          .get()
          .then((value) {
        print('FirestoreAPI.getFriends ${value.docs.first.data()}');
        return value.docs.map((e) {
          return Player.fromJson(e.data() as Map<String, dynamic>);
        }).toList();
      });

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

  static Future<bool> isFriend(String friendId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final ref = shared
        .collection('friendships')
        .where('uids', arrayContains: currentUid)
        .where('uids', arrayContains: friendId)
        .limit(1);

    return ref.get().then((value) => value.docs.isNotEmpty);
  }

  static Stream<List<Map<String, dynamic>>> getMessagesForRecipient(
      String recipientId) {
    return messageColRef()
        .where('sender.uid', isEqualTo: recipientId)
        .orderBy('created_at', descending: true)
        .orderBy('seen', descending: true)
        .snapshots()
        .map(
          (value) =>
              value.docs.map((e) => e.data() as Map<String, dynamic>).toList(),
        );
  }

  static Future sendMessage(Player sender, Player recipient, String message) {
    return messageColRef().doc().set({
      'created_at': Timestamp.now(),
      'sender': sender.toMap(),
      'recipient': recipient.toMap(),
      'message': message,
      'seen': false,
    });
  }

  static Future addPlayerCommand(
      Player user1, Player user2, String command) async {
    final batch = shared.batch();

    ///Check if command is valid
    final commandQuery = commandsColRef()
        .where('query', arrayContains: command.trim().toLowerCase())
        .limit(1);

    final commandDoc = await commandQuery.get().then((value) =>
        value.docs.isEmpty
            ? throw Exception('Enter a valid command')
            : value.docs.first.data() as Map<String, dynamic>);

    print('FirestoreAPI.addPlayerCommand $commandDoc');

    final activityDocRef = feedColRef().doc();

    final user1StatsDocRef = userStatsRef(user1.uid);
    final user2StatsDocRef = userStatsRef(user2.uid);

    batch.set(
        user1StatsDocRef,
        {'faith': FieldValue.increment(commandDoc['user_1_faith'] ?? 0)},
        SetOptions(merge: true));
    batch.set(
        user2StatsDocRef,
        {'faith': FieldValue.increment(commandDoc['user_2_faith'] ?? 0)},
        SetOptions(merge: true));

    //add activity to feed
    batch.set(activityDocRef, {
      'created_at': Timestamp.now(),
      'title':
          '${user1.displayName} ${commandDoc['verb'] ?? command} ${user2.displayName}',
      'user_1': user1.uid,
      'user_2': user2.uid,
    });

    //change stats
    return batch.commit();
  }

  static Stream<Map<String, dynamic>> userInventoryStream(String uid) {
    return userInventoryRef(uid)
        .snapshots()
        .map((snap) => snap.data() as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getShop() {
    print('FirestoreAPI.getShop');
    return shopRef().get().then((snap) => snap.data() as Map<String, dynamic>);
  }

  static Future<void> useItem(Map<String, dynamic> item) async {
    final int quantity = item['quantity'] ?? 0;

    final key = item['name'];

    final ref = userInventoryRef(uid);

    final data = item..addAll({'quantity': quantity - 1});

    ///get buff data from shop
    final shopMap = await shopRef()
        .get()
        .then((snap) => snap.data() as Map<String, dynamic>);

    final shopItem = shopMap[key];

    final shopItemBuff = shopItem?['buff'] ?? {};

    print('FirestoreAPI.useItem buff $shopItemBuff');

    //apply any buffs
    if (shopItemBuff is Map<String, dynamic>) {
      await applyBuff(uid, buff: shopItemBuff);
    }

    if (quantity <= 1) {
      ref.update({key: FieldValue.delete()});
    } else {
      ref.update({key: data});
    }
  }

  ///1. Check if user can afford item
  ///2. Add item to user inventory
  ///3. Deduct coins
  static Future buyShopItem(String uid, Map<String, dynamic> item) {
    final data = item..addAll({'quantity': FieldValue.increment(1)});
    print('FirestoreAPI.buyShopItem ${data['name'].runtimeType}');
    final int cost = item['cost'] ?? 0;
    //update inventory and coins
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

  static Stream<Map<String, dynamic>> friendRequestStream(
      String uid1, String uid2) {
    // final currentUser = FirebaseAuth.instance.currentUser;
    //
    // if (currentUser == null) throw Exception('No current user');
    // final uid = currentUser.uid;

    final ref1 = friendRequestRef(uid1, uid2);

    return ref1
        .snapshots()
        .map((event) => event.data() as Map<String, dynamic>);
  }

  static Future removeFriendRequest(Player friend) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) throw Exception('No current user');

    final uid = currentUser.uid;
    final friendId = friend.uid;

    try {
      return friendRequestRef(friendId, uid).delete();
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreAPI.addFriendRequest Error $e');
      }
    }

    return Future(() => null);
  }

  static Future addFriendRequest(Player friend) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) throw Exception('No current user');

    final uid = currentUser.uid;
    final friendId = friend.uid;

    final map = friend.toMap()..addAll({'created_at': Timestamp.now()});

    try {
      print('FirestoreAPI.addFriendRequest ${uid} $friendId');
      return friendRequestRef(friendId, uid).set(map);
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreAPI.addFriendRequest Error $e');
      }
    }

    return Future(() => null);
  }

  static Stream<Map<String, dynamic>> friendStream(String friendId) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) throw Exception('No current user');
    final uid = currentUser.uid;

    final ref1 = friendRef(uid, friendId);

    return ref1
        .snapshots()
        .map((event) => event.data() as Map<String, dynamic>);
  }

  static Future removeFriend(String friendId) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) throw Exception('No current user');
    final uid = currentUser.uid;

    final batch = shared.batch();
    final ref1 = friendRef(uid, friendId);
    final ref2 = friendRef(friendId, uid);

    batch.delete(ref1);
    batch.delete(ref2);

    return batch.commit();
  }

  static Future addFriend(Player friend, bool accepted) {
    print('FirestoreAPI.addFriend');
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) throw Exception('No current user');
    final uid = currentUser.uid;
    final friendId = friend.uid;

    return shared.runTransaction((transaction) async {
      try {
        ///get current user
        final currentPlayerDoc = (await transaction.get(userRef(uid)));

        final currentPlayer =
            Player.fromJson((currentPlayerDoc).data() as Map<String, dynamic>);

        ///write to user's friends list
        final ref1 = friendRef(uid, friendId);
        final ref2 = friendRef(friendId, uid);
        final ref3 = friendRequestRef(uid, friendId);
        final ref4 = userRef(uid);
        final ref5 = userRef(friendId);
        print('FirestoreAPI.addFriend ref1 : ${ref1.path}');
        print('FirestoreAPI.addFriend ref2 : ${ref2.path}');
        print('FirestoreAPI.addFriend ref3 : ${ref3.path}');
        transaction.set(ref1, friend.toMap()..addAll({'accepted': accepted}));
        transaction.set(
            ref2, currentPlayer.toMap()..addAll({'accepted': accepted}));
        transaction.delete(ref3);
        //TODO: increment friend count
        transaction.update(ref4, {'friends': FieldValue.increment(1)});
        transaction.update(ref5, {'friends': FieldValue.increment(1)});
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

  static Future completeBakeSession(Player user, Map<String, dynamic> session) {
    final batch = shared.batch();
    //add coins to user
    final int cookies = session['cookies'] ?? 0;
    final sessionRef = sessionColRef().doc(session['id'] ?? '');
    // batch.update(userRef(user.uid), {'coins': FieldValue.increment(coins)});
    //delete session
    batch.delete(sessionRef);

    // addCoins(user1: user, coins: coins);
    final Map<String, dynamic> data = session['cookie'];

    userInventoryRef(uid).set(
      {
        'cookie': data..addAll({'quantity': FieldValue.increment(cookies)}),
      },
      SetOptions(merge: true),
    );
    return batch.commit();
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

  static Future createBakeSession(
      Player user, Map<String, dynamic> cookieData) async {
    final ref = sessionColRef().doc();
    final startTime = Timestamp.now();
    final bakeRate = await getAdminRate('bake');

    const defaultEndTime = 90;

    final int duration = bakeRate?['duration'] ?? defaultEndTime;
    final endTime = Timestamp.fromMillisecondsSinceEpoch(
        startTime.millisecondsSinceEpoch + 1000 * duration);

    final min = bakeRate?['min'] ?? 0;
    final max = bakeRate?['max'] ?? 0;

    //cast to int
    final int cookies = ((Random().nextInt(max) + min)).toInt();

    final data = {
      'id': ref.id,
      'type': 'bake',
      'created_at': startTime,
      'end_time': endTime,
      'user': user.toMap(),
      'uids': [uid],
      'cookies': cookies,
      'cookie': cookieData,
      'rate': bakeRate,
    };

    print('FirestoreAPI.createBakeSession ${ref.id} $data');
    return ref.set(data, SetOptions(merge: true));
  }

  //create dig session
  static Future createDigSession(Player user, List<String> uids) async {
    final ref = sessionColRef().doc();
    final startTime = Timestamp.now();

    final digRate = await getAdminDigRate();

    //apply any buffs/multiplier
    final buffMap = await getBuff(buffType: 'dig_boost');
    final double buffMultiplier = (buffMap['multiplier']).toDouble();
    //get end time
    const defaultEndTime = 90;
    final int duration = digRate?['duration'] ?? defaultEndTime;
    final endTime = Timestamp.fromMillisecondsSinceEpoch(
        startTime.millisecondsSinceEpoch + 1000 * duration);

    //GET COINS
    final minCoins = digRate?['min_coins'] ?? 0;
    final maxCoins = digRate?['max_coins'] ?? 0;
    final multiplier = digRate?['multiplier'] ?? 1;
    //cast to int
    final int coins =
        ((Random().nextInt(maxCoins) + minCoins) * buffMultiplier * multiplier)
            .toInt();

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

  static Future<Map<String, dynamic>> getBuff(
      {required String buffType}) async {
    final userDoc = await (userRef(uid)
        .get()
        .then((value) => value.data() as Map<String, dynamic>));
    final buffMap = userDoc['buffs'][buffType];
    print('FirestoreAPI.getBuff $buffMap');
    return buffMap;
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

  static Future<Map<String, dynamic>?> getAdminRate(String type) {
    return shared.collection('admin').doc(type).get().then((value) {
      print('FirestoreAPI.getAdminRate ${value.data()}');
      return value.data();
    });
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

  static Future<void> bakeCookie() async {
    //check if user has bottle
    final inventory = await userInventoryStream(uid).first;
    final hasBottle = inventory.containsKey('bottle');
    print('FirestoreAPI.bakeCookie hasBottle: $hasBottle, $inventory');
    //set timer

    if (!hasBottle) return;

    //get cookie data from shop
    final Map<String, dynamic> data = (await getShop())['cookie'];

    //create bake session
    await createBakeSession(await getUser(uid), data);
    //update inventory

    // return userInventoryRef(uid).set(
    //   {
    //     'cookie': data..addAll({'quantity': FieldValue.increment(1)}),
    //   },
    //   SetOptions(merge: true),
    // );
  }
}
