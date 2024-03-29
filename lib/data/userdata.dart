// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

import '../main.dart';
import 'util.dart';

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

Future<void> sendMessage(String message, String to, {String? type, Map? replyTo}) async {
  CollectionReference messages = FirebaseFirestore.instance.collection('messages');
  Map<String, dynamic> data = {
    'message': encryptText(message.trimRight()),
    'users': "{{${FirebaseAuth.instance.currentUser?.email}}, {$to}}",
    'sender': FirebaseAuth.instance.currentUser?.email,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'replyto': replyTo,
  };
  if (type != null) {
    data['type'] = type;
  }
  await messages.add(data);
  updateTypingStatus("");
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

  for (int i = 0; i < messages.length; i++) {
    messages[i]['message'] = decryptText(messages[i]['message']);
  }
  messages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

  return messages;
}

bool nicknameExists(String email) {
  return (prefs?.getString("nicknameof$email") ?? "").isNotEmpty;
}

Future<String> getDisplayName(String email, {bool allowNickname = true}) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where("email", isEqualTo: email).get();
  List allData = querySnapshot.docs.map((doc) => doc.data()).toList();
  if (allData.isEmpty) {
    return "";
  }
  String displayName = allData[0]['username'];
  String nickname = prefs?.getString("nicknameof${allData[0]['email']}") ?? "";
  if (!allowNickname || nickname.isEmpty) {
    return displayName;
  }
  return nickname;
}

Future<List> getUsersNamed(String name) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where(
        'username',
        isEqualTo: name,
      )
      .get();
  List data = querySnapshot.docs.map((doc) => doc.data()).toList();

  return data;
}

Future<void> sendFriendRequest(String to) async {
  if (to == FirebaseAuth.instance.currentUser?.email || FirebaseAuth.instance.currentUser?.email == null) {
    return;
  }
  List friends = await getFriends(
    FirebaseAuth.instance.currentUser?.email ?? "",
  );
  List requests = await getSentFriendRequests();
  for (final request in requests) {
    friends.add(request["receiver"]);
  }
  friends = friends.toSet().toList();
  if (friends.contains(to)) {
    return;
  }
  CollectionReference friendRequests = FirebaseFirestore.instance.collection('friendrequests');
  await friendRequests.add({
    'sender': FirebaseAuth.instance.currentUser?.email,
    'receiver': to,
  });
}

Future<List> getFriendRequests() async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('friendrequests')
      .where(
        "receiver",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();
  return querySnapshot.docs.map((doc) => doc.data()).toList();
}

Future<List> getSentFriendRequests() async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('friendrequests')
      .where(
        "sender",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
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
      .where(
        "user",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();
  List friends = querySnapshot2.docs.map((doc) => doc.data()).toList();

  if (friends.isEmpty) {
    CollectionReference friends = FirebaseFirestore.instance.collection('friends');
    await friends.add({
      'user': FirebaseAuth.instance.currentUser?.email,
      'friends': [request['sender']],
    });
  } else {
    friends[0]['friends'].add(request['sender']);
    QuerySnapshot querySnapshot3 = await FirebaseFirestore.instance
        .collection('friends')
        .where(
          "user",
          isEqualTo: FirebaseAuth.instance.currentUser?.email,
        )
        .get();
    querySnapshot3.docs[0].reference.update(friends[0]);
  }

  QuerySnapshot querySnapshot_ = await FirebaseFirestore.instance
      .collection('friendrequests')
      .where("sender", isEqualTo: request['receiver'])
      .where("receiver", isEqualTo: request['sender'])
      .get();
  for (var doc in querySnapshot_.docs) {
    doc.reference.delete();
  }

  QuerySnapshot querySnapshot2_ = await FirebaseFirestore.instance.collection('friends').where("user", isEqualTo: request['sender']).get();
  List friends_ = querySnapshot2_.docs.map((doc) => doc.data()).toList();

  if (friends_.isEmpty) {
    CollectionReference friends_ = FirebaseFirestore.instance.collection('friends');
    await friends_.add({
      'user': request['sender'],
      'friends': [request['receiver']],
    });
  } else {
    friends_[0]['friends'].add(request['receiver']);
    QuerySnapshot querySnapshot3 = await FirebaseFirestore.instance
        .collection('friends')
        .where(
          "user",
          isEqualTo: request['sender'],
        )
        .get();
    querySnapshot3.docs[0].reference.update(friends_[0]);
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
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('friends').where("user", isEqualTo: email).get();
  List friends = querySnapshot.docs.map((doc) => doc.data()).toList();
  if (friends.isEmpty) {
    return [];
  } else {
    return friends[0]['friends'];
  }
}

Future<void> setMessageRead(String user, String message, int timestamp) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('messages')
      .where("timestamp", isEqualTo: timestamp)
      .where("message", isEqualTo: encryptText(message))
      .get();
  for (var doc in querySnapshot.docs) {
    if (doc.data().toString().contains(user)) {
      doc.reference.update({'read': true});
    }
  }
}

Future<int> getUnreadMessages() async {
  final conversations = await getConversations();
  int unread = 0;
  for (final conversation in conversations) {
    List messages = await getMessages(conversation);
    messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    if (messages.isNotEmpty) {
      if (messages.last['sender'] != FirebaseAuth.instance.currentUser?.email && !(messages.last['read'] ?? false)) {
        unread++;
      }
    }
  }
  return unread;
}

Future<void> updateStatus() async {
  String status = prefs?.getString('status') ?? 'online';
  if (status == "invisible") {
    return;
  }
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where(
        "email",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();
  for (var doc in querySnapshot.docs) {
    if (FirebaseAuth.instance.currentUser?.email != null && doc.data().toString().contains(FirebaseAuth.instance.currentUser?.email ?? "")) {
      doc.reference.update({
        'status': {
          "state": status,
          "last_changed": DateTime.now().millisecondsSinceEpoch,
        }
      });
    }
  }
}

Future<String> getStatus(String email) async {
  try {
    Map? status = await FirebaseFirestore.instance
        .collection('users')
        .where(
          "email",
          isEqualTo: email,
        )
        .get()
        .then((value) => value.docs[0].data()['status']);

    if (status == null || DateTime.now().millisecondsSinceEpoch - status['last_changed'] > 10000) {
      return "offline";
    }
    return status['state'] ?? "offline";
  } catch (e) {
    return "offline";
  }
}

Future<void> updatePicture(ImageSource source, {String folder = "profiles"}) async {
  XFile? image = await ImagePicker().pickImage(source: source, preferredCameraDevice: CameraDevice.front);
  if (image == null) {
    return;
  }
  final storageRef = FirebaseStorage.instance.ref();
  final imageRef = storageRef.child(
    "$folder/${FirebaseAuth.instance.currentUser?.email}",
  );
  await imageRef.putFile(File(image.path));
  if (folder == "profiles") {
    profileDownloadURLs.remove(FirebaseAuth.instance.currentUser?.email);
  } else if (folder == "banners") {
    bannerDownloadURLs.remove(FirebaseAuth.instance.currentUser?.email);
  }
}

Map profileDownloadURLs = {};
Map bannerDownloadURLs = {};

Future<String> getPicture(String email, {String folder = "profiles"}) async {
  if (folder == "profiles" && profileDownloadURLs.containsKey(email)) {
    return profileDownloadURLs[email];
  }
  if (folder == "banners" && bannerDownloadURLs.containsKey(email)) {
    return bannerDownloadURLs[email];
  }
  final storageRef = FirebaseStorage.instance.ref();
  final imageRef = storageRef.child("$folder/$email");
  try {
    String downloadURL = await imageRef.getDownloadURL();
    if (folder == "profiles") {
      profileDownloadURLs[email] = downloadURL;
    } else if (folder == "banners") {
      bannerDownloadURLs[email] = downloadURL;
    }
    return downloadURL;
  } catch (e) {
    if (folder == "profiles") {
      profileDownloadURLs[email] = "";
    } else if (folder == "banners") {
      bannerDownloadURLs[email] = "";
    }
    return "";
  }
}

Future<void> changeUsername(String email, String name) async {
  if (name.isEmpty) {
    return;
  }
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where("email", isEqualTo: email).get();
  for (var doc in querySnapshot.docs) {
    if (FirebaseAuth.instance.currentUser?.email != null && doc.data().toString().contains(FirebaseAuth.instance.currentUser?.email ?? "")) {
      doc.reference.update({
        'username': name,
      });
    }
  }
}

Future<void> deleteAccount(User? user) async {
  if (user == null) {
    return;
  }
  String email = user.email ?? "";
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where(
        "email",
        isEqualTo: email,
      )
      .get();
  for (var doc in querySnapshot.docs) {
    if (doc.data().toString().contains(email)) {
      doc.reference.delete();
    }
  }

  final storageRef = FirebaseStorage.instance.ref();
  try {
    final imageRef = storageRef.child("profiles/$email");
    await imageRef.delete();
    // ignore: empty_catches
  } catch (e) {}
  try {
    final bannerRef = storageRef.child("banners/$email");
    await bannerRef.delete();
    // ignore: empty_catches
  } catch (e) {}
  user.delete();
}

Future<bool> updateSignedinDevices() async {
  if (FirebaseAuth.instance.currentUser == null) {
    return false;
  }
  String platform = "Unknown";
  try {
    platform = Platform.isAndroid ? "Android" : "iOS";
  } catch (e) {
    platform = "Unknown";
  }
  String phoneName = "Unknown";
  String phoneID = "Unknown";
  try {
    if (Platform.isAndroid) {
      phoneName = await DeviceInfoPlugin().androidInfo.then((value) => value.model ?? "Unknown");
      phoneID = await DeviceInfoPlugin().androidInfo.then((value) => value.id ?? "Unknown");
    } else if (Platform.isIOS) {
      phoneName = await DeviceInfoPlugin().iosInfo.then((value) => value.model ?? "Unknown");
      phoneID = await DeviceInfoPlugin().iosInfo.then((value) => value.identifierForVendor ?? "Unknown");
    }
  } catch (e) {
    phoneName = "Unknown";
  }
  Map details = {
    "platform": platform,
    "phonename": phoneName,
    "phoneID": phoneID,
    "lastlogin": DateTime.now().millisecondsSinceEpoch,
  };

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where(
        "email",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();
  dynamic deviceData = querySnapshot.docs.map((doc) => doc.data()).toList()[0];
  List currentDevices = deviceData["signedindevices"] ?? [];

  try {
    String response = (await http.get(Uri.parse("http://ip-api.com/json"))).body;
    dynamic data = json.decode(response);
    details["location"] = "${data['city']}, ${data['regionName']}, ${data['country']}";
  } catch (e) {
    details["location"] = "Unknown location";
  }
  bool forceLogout = false;
  for (int i = 0; i < currentDevices.length; i++) {
    if (currentDevices[i]["phoneID"] == phoneID && currentDevices[i]["phonename"] == phoneName) {
      if (currentDevices[i]["forcelogout"] ?? false) {
        forceLogout = true;
      }
      currentDevices.remove(currentDevices[i]);
    }
  }
  currentDevices.add(details);
  for (var doc in querySnapshot.docs) {
    if (FirebaseAuth.instance.currentUser?.email != null && doc.data().toString().contains(FirebaseAuth.instance.currentUser?.email ?? "")) {
      doc.reference.update({
        'signedindevices': currentDevices,
      });
    }
  }
  return forceLogout;
}

Map signedinDevices = {};
int lastDeviceRequest = 0;

Future<Map> getSignedinDevices() async {
  if (FirebaseAuth.instance.currentUser == null || DateTime.now().millisecondsSinceEpoch - lastDeviceRequest < 1000) {
    return signedinDevices;
  }
  String platform = "Unknown";
  try {
    platform = Platform.isAndroid ? "Android" : "iOS";
  } catch (e) {
    platform = "Unknown";
  }
  String phoneName = "Unknown";
  String phoneID = "Unknown";
  try {
    if (Platform.isAndroid) {
      phoneName = await DeviceInfoPlugin().androidInfo.then((value) => value.model ?? "Unknown");
      phoneID = await DeviceInfoPlugin().androidInfo.then((value) => value.id ?? "Unknown");
    } else if (Platform.isIOS) {
      phoneName = await DeviceInfoPlugin().iosInfo.then((value) => value.model ?? "Unknown");
      phoneID = await DeviceInfoPlugin().iosInfo.then((value) => value.identifierForVendor ?? "Unknown");
    }
  } catch (e) {
    phoneName = "Unknown";
  }

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where(
        "email",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();
  dynamic deviceData = querySnapshot.docs.map((doc) => doc.data()).toList()[0];
  List currentDevices = deviceData["signedindevices"] ?? [];
  for (int i = 0; i < currentDevices.length; i++) {
    if (currentDevices[i]["phoneID"] == phoneID && currentDevices[i]["phonename"] == phoneName) {
      currentDevices.remove(currentDevices[i]);
    }
  }
  signedinDevices = {
    "currentDevice": {
      "platform": platform,
      "phonename": phoneName,
      "phoneID": phoneID,
    },
    "otherDevices": currentDevices,
  };
  return signedinDevices;
}

Future<void> deleteCurrentDevice() async {
  if (FirebaseAuth.instance.currentUser == null) {
    return;
  }
  String phoneName = "Unknown";
  String phoneID = "Unknown";
  try {
    if (Platform.isAndroid) {
      phoneName = await DeviceInfoPlugin().androidInfo.then((value) => value.model ?? "Unknown");
      phoneID = await DeviceInfoPlugin().androidInfo.then((value) => value.id ?? "Unknown");
    } else if (Platform.isIOS) {
      phoneName = await DeviceInfoPlugin().iosInfo.then((value) => value.model ?? "Unknown");
      phoneID = await DeviceInfoPlugin().iosInfo.then((value) => value.identifierForVendor ?? "Unknown");
    }
  } catch (e) {
    phoneName = "Unknown";
  }

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where(
        "email",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();
  dynamic deviceData = querySnapshot.docs.map((doc) => doc.data()).toList()[0];
  List currentDevices = deviceData["signedindevices"] ?? [];
  for (int i = 0; i < currentDevices.length; i++) {
    if (currentDevices[i]["phoneID"] == phoneID && currentDevices[i]["phonename"] == phoneName) {
      currentDevices.remove(currentDevices[i]);
    }
  }
  for (var doc in querySnapshot.docs) {
    if (FirebaseAuth.instance.currentUser?.email != null && doc.data().toString().contains(FirebaseAuth.instance.currentUser?.email ?? "")) {
      doc.reference.update({
        'signedindevices': currentDevices,
      });
    }
  }
}

Future<void> logoutAllDevices() async {
  if (FirebaseAuth.instance.currentUser == null) {
    return;
  }
  String phoneName = "Unknown";
  String phoneID = "Unknown";
  try {
    if (Platform.isAndroid) {
      phoneName = await DeviceInfoPlugin().androidInfo.then((value) => value.model ?? "Unknown");
      phoneID = await DeviceInfoPlugin().androidInfo.then((value) => value.id ?? "Unknown");
    } else if (Platform.isIOS) {
      phoneName = await DeviceInfoPlugin().iosInfo.then((value) => value.model ?? "Unknown");
      phoneID = await DeviceInfoPlugin().iosInfo.then((value) => value.identifierForVendor ?? "Unknown");
    }
  } catch (e) {
    phoneName = "Unknown";
  }
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where(
        "email",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();
  dynamic deviceData = querySnapshot.docs.map((doc) => doc.data()).toList()[0];
  List currentDevices = deviceData["signedindevices"] ?? [];
  for (int i = 0; i < currentDevices.length; i++) {
    if (currentDevices[i]["phoneID"] != phoneID || currentDevices[i]["phonename"] != phoneName) {
      currentDevices[i]["forcelogout"] = true;
    }
  }
  for (var doc in querySnapshot.docs) {
    if (FirebaseAuth.instance.currentUser?.email != null && doc.data().toString().contains(FirebaseAuth.instance.currentUser?.email ?? "")) {
      doc.reference.update({
        'signedindevices': currentDevices,
      });
    }
  }
}

Future<void> removeFriend(String email) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('friends')
      .where(
        "user",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();
  for (var doc in querySnapshot.docs) {
    if (FirebaseAuth.instance.currentUser?.email != null && doc.data().toString().contains(FirebaseAuth.instance.currentUser?.email ?? "")) {
      doc.reference.update({
        'friends': FieldValue.arrayRemove([email]),
      });
    }
  }
}

Future<void> setCustomStatus(String status) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where(
        "email",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();
  for (var doc in querySnapshot.docs) {
    if (FirebaseAuth.instance.currentUser?.email != null && doc.data().toString().contains(FirebaseAuth.instance.currentUser?.email ?? "")) {
      doc.reference.update({
        'customstatus': status,
      });
    }
  }
}

Future<String> getCustomStatus(String email) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where("email", isEqualTo: email).get();
  List allData = querySnapshot.docs.map((doc) => doc.data()).toList();
  if (allData.isEmpty) {
    return "";
  }
  return allData[0]["customstatus"] ?? "";
}

Future<List> getMutualFriends(String email) async {
  String myEmail = FirebaseAuth.instance.currentUser?.email ?? "";
  if (email == myEmail || myEmail.isEmpty) {
    return [];
  }
  List myFriends = await getFriends(myEmail);
  List theirFriends = await getFriends(email);
  List mutualFriends = [];
  for (int i = 0; i < myFriends.length; i++) {
    if (theirFriends.contains(myFriends[i])) {
      mutualFriends.add(myFriends[i]);
    }
  }
  return mutualFriends;
}

Future<void> sendImages(List<XFile> images, String to) async {
  final storageRef = FirebaseStorage.instance.ref();
  for (final image in images) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    String path = "images/${encryptText('${FirebaseAuth.instance.currentUser?.email}$now')}";
    final imageRef = storageRef.child(
      path,
    );
    await imageRef.putFile(File(image.path));
    sendMessage(path, to, type: "image");
  }
}

Map sentMedia = {};

Future<String> getSentMedia(String path) async {
  if (sentMedia.containsKey(path)) {
    return sentMedia[path];
  }
  sentMedia[path] = "";
  final storageRef = FirebaseStorage.instance.ref();
  final imageRef = storageRef.child(path);
  try {
    String url = await imageRef.getDownloadURL();
    sentMedia[path] = url;
    if (!downloadedMedia.containsKey(path) && path.contains("videos/")) {
      downloadedMedia[path] = VideoPlayerController.network(url);
    }
    return url;
  } catch (e) {
    sentMedia[path] = "";
    return "";
  }
}

List cachedImages = [];
void precacheImages(BuildContext context) {
  List images = sentMedia.values.toList() + downloadedMedia.values.toList();
  for (final image in images) {
    if (!cachedImages.contains(image)) {
      try {
        precacheImage(NetworkImage(image), context);
        cachedImages.add(image);
        // ignore: empty_catches
      } catch (e) {}
    }
  }
}

Future<void> sendVideos(List<XFile> videos, String to) async {
  final storageRef = FirebaseStorage.instance.ref();
  for (final video in videos) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    String path = "videos/${encryptText('${FirebaseAuth.instance.currentUser?.email}$now')}";
    final videoRef = storageRef.child(path);
    await videoRef.putFile(File(video.path));
    sendMessage(path, to, type: "video");
  }
}

Future<void> sendAudios(List<File> audios, String to) async {
  // if (isRecording) {
  //   return;
  // }
  final storageRef = FirebaseStorage.instance.ref();
  for (final audio in audios) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    String path = "audios/${encryptText('${FirebaseAuth.instance.currentUser?.email}$now')}";
    final audioRef = storageRef.child(path);
    await audioRef.putFile(audio);
    sendMessage(path, to, type: "audio");
  }
}

Future<void> sendFiles(List<File> files, String to) async {
  final storageRef = FirebaseStorage.instance.ref();
  for (final file in files) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    String path = "files/${encryptText('${FirebaseAuth.instance.currentUser?.email}${now}filename=${p.basename(file.path)}')}";
    final fileRef = storageRef.child(path);
    await fileRef.putFile(file);
    sendMessage(path, to, type: "file");
  }
}

Future<void> updateTypingStatus(String to) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where(
        "email",
        isEqualTo: FirebaseAuth.instance.currentUser?.email,
      )
      .get();

  for (var doc in querySnapshot.docs) {
    if (FirebaseAuth.instance.currentUser?.email != null && doc.data().toString().contains(FirebaseAuth.instance.currentUser?.email ?? "")) {
      doc.reference.update({
        'typing': {
          'to': to,
          'time': DateTime.now().millisecondsSinceEpoch,
        },
      });
    }
  }
}

Future<bool> getTypingStatus(String email) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where("email", isEqualTo: email).get();
  List allData = querySnapshot.docs.map((doc) => doc.data()).toList();
  if (allData.isEmpty) {
    return false;
  }
  Map typing = allData[0]["typing"] ?? {};
  if (typing.isEmpty) {
    return false;
  }
  if (typing["to"] == FirebaseAuth.instance.currentUser?.email && DateTime.now().millisecondsSinceEpoch - typing["time"] < 5000) {
    return true;
  }
  return false;
}

Future<void> addReaction(Map? message, String emoji) async {
  //print(message);
  if (message == null || message.isEmpty) {
    return;
  }
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('messages')
      //.where("message", isEqualTo: encryptText(message["message"]))
      .where("sender", isEqualTo: message["sender"])
      .where("users", isEqualTo: message["users"])
      .where("timestamp", isEqualTo: message["timestamp"])
      .get();
  for (var doc in querySnapshot.docs) {
    //if (doc.data().toString().contains(message["message"])) {
    List r = querySnapshot.docs.map((doc) => doc.data()).toList();
    List reactions = r[0]["reactions"] ?? [];
    bool sameReaction = false;
    for (final reaction in reactions) {
      if (reaction["email"] == FirebaseAuth.instance.currentUser?.email && reaction["emoji"] == emoji) {
        sameReaction = true;
        break;
      }
    }
    reactions.removeWhere((element) => element["email"] == FirebaseAuth.instance.currentUser?.email);
    if (!sameReaction) {
      reactions.add({
        "email": FirebaseAuth.instance.currentUser?.email,
        "emoji": emoji,
      });
    }

    doc.reference.update({
      'reactions': reactions.isNotEmpty ? reactions : FieldValue.delete(),
    });
    //}
  }
}

Future<void> deleteMessage(Map message) async {
  if (message.isEmpty) {
    return;
  }
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('messages')
      .where("sender", isEqualTo: message["sender"])
      .where("users", isEqualTo: message["users"])
      .where("timestamp", isEqualTo: message["timestamp"])
      .get();
  for (var doc in querySnapshot.docs) {
    doc.reference.delete();
  }

  // if (message["type"] == "image" || message["type"] == "video" || message["type"] == "audio" || message["type"] == "file") {
  //   FirebaseStorage.instance.refFromURL(sentMedia[message["message"]]).delete();
  // }
}

Map forwardTimestamps = {};

Future<Map> forwardMessage(Map message, String to) async {
  if (forwardTimestamps[to] != null && DateTime.now().millisecondsSinceEpoch - forwardTimestamps[to] < 1000) {
    return {};
  }
  forwardTimestamps[to] = DateTime.now().millisecondsSinceEpoch;
  message["users"] = "{{${FirebaseAuth.instance.currentUser?.email}}, {$to}}";
  message["timestamp"] = DateTime.now().millisecondsSinceEpoch;
  message["sender"] = FirebaseAuth.instance.currentUser?.email;
  message["reactions"] = [];
  message["read"] = false;
  message["edited"] = false;
  message["forwarded"] = true;
  message["message"] = encryptText(message["message"]);
  CollectionReference messages = FirebaseFirestore.instance.collection('messages');
  await messages.add(message);
  return message;
}

Future<void> editMessage(Map message, String newMessage) async {
  if (message.isEmpty) {
    return;
  }
  if (newMessage.isEmpty) {
    deleteMessage(message);
    return;
  }
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('messages')
      .where("sender", isEqualTo: message["sender"])
      .where("users", isEqualTo: message["users"])
      .where("timestamp", isEqualTo: message["timestamp"])
      .get();
  for (var doc in querySnapshot.docs) {
    doc.reference.update({
      'message': encryptText(newMessage),
      'edited': true,
    });
  }
}

Future<void> uploadTheme(Map theme) async {
  CollectionReference themes = FirebaseFirestore.instance.collection('themes');
  themes.add(theme);
}

Future<List> getThemes() async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('themes').get();
  List allData = querySnapshot.docs.map((doc) => doc.data()).toSet().toList();
  return allData;
}
