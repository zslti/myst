import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<List> getAllMessages() async {
  CollectionReference messages = FirebaseFirestore.instance.collection(
    'messages',
  );
  QuerySnapshot querySnapshot = await messages.get();
  List allData = querySnapshot.docs.map((doc) => doc.data()).toList();
  allData.removeWhere(
    (element) => !element['users'].contains(
      "{${FirebaseAuth.instance.currentUser?.email}}",
    ),
  );

  return allData;
}

Future<void> sendMessage(String message, String to) async {
  CollectionReference messages = FirebaseFirestore.instance.collection(
    'messages',
  );
  await messages.add({
    'message': message,
    'users': "{{${FirebaseAuth.instance.currentUser?.email}}, {$to}}",
    'sender': FirebaseAuth.instance.currentUser?.email,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
}

Future<List> getConversations() async {
  List allData = await getAllMessages();
  allData.sort(
    (a, b) => b['timestamp'].compareTo(a['timestamp']),
  );
  List conversations = [];
  for (var i = 0; i < allData.length; i++) {
    conversations.add(
      allData[i]['users']
          .replaceAll("{${FirebaseAuth.instance.currentUser?.email}}", "")
          .replaceAll(" ", "")
          .replaceAll(",", "")
          .replaceAll("{", "")
          .replaceAll("}", ""),
    );
  }

  conversations = conversations.toSet().toList();
  return conversations;
}

Future<List> getMessages(String user) async {
  List allData = await getAllMessages();
  List messages = [];
  for (var i = 0; i < allData.length; i++) {
    if (allData[i]['users'].contains("{$user}")) {
      messages.add(allData[i]);
    }
  }

  messages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

  return messages;
}

Future<String> getDisplayName(String email) async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  QuerySnapshot querySnapshot = await users.get();
  List allData = querySnapshot.docs.map((doc) => doc.data()).toList();
  allData.removeWhere((element) => element['email'] != email);
  return allData[0]['username'];
}

Future<List> getUsersNamed(String name) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('username', isEqualTo: name)
      .get();
  List data = querySnapshot.docs.map((doc) => doc.data()).toList();

  return data;
}

Future<void> sendFriendRequest(String to) async {
  CollectionReference friendRequests =
      FirebaseFirestore.instance.collection('friendrequests');
  await friendRequests.add({
    'sender': FirebaseAuth.instance.currentUser?.email,
    'receiver': to,
  });
}

Future<List> getFriendRequests() async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('friendrequests')
      .where("receiver", isEqualTo: FirebaseAuth.instance.currentUser?.email)
      .get();
  return querySnapshot.docs.map((doc) => doc.data()).toList();
}

Future<List> getSentFriendRequests() async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('friendrequests')
      .where("sender", isEqualTo: FirebaseAuth.instance.currentUser?.email)
      .get();

  return querySnapshot.docs.map((doc) => doc.data()).toList();
}

Future<void> acceptFriendRequest(Map request) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('friendrequests')
      .where("sender", isEqualTo: request['sender'])
      .where("receiver", isEqualTo: request['receiver'])
      .get();
  for (var doc in querySnapshot.docs) {
    doc.reference.delete();
  }

  QuerySnapshot querySnapshot2 = await FirebaseFirestore.instance
      .collection('friends')
      .where("user", isEqualTo: FirebaseAuth.instance.currentUser?.email)
      .get();
  List friends = querySnapshot2.docs.map((doc) => doc.data()).toList();

  if (friends.isEmpty) {
    CollectionReference friends =
        FirebaseFirestore.instance.collection('friends');
    await friends.add({
      'user': FirebaseAuth.instance.currentUser?.email,
      'friends': [request['sender']],
    });
  } else {
    friends[0]['friends'].add(request['sender']);
    QuerySnapshot querySnapshot3 = await FirebaseFirestore.instance
        .collection('friends')
        .where("user", isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .get();
    querySnapshot3.docs[0].reference.update(friends[0]);
  }
}

Future<void> rejectFriendRequest(Map request) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('friendrequests')
      .where("sender", isEqualTo: request['sender'])
      .where("receiver", isEqualTo: request['receiver'])
      .get();
  for (var doc in querySnapshot.docs) {
    doc.reference.delete();
  }
}

Future<List> getFriends(String email) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('friends')
      .where("user", isEqualTo: email)
      .get();
  List friends = querySnapshot.docs.map((doc) => doc.data()).toList();
  if (friends.isEmpty) {
    return [];
  } else {
    return friends[0]['friends'];
  }
}
