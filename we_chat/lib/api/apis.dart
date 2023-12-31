import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/models/message.dart';

class APIs{
  static FirebaseAuth auth = FirebaseAuth.instance;

  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  static FirebaseStorage storage = FirebaseStorage.instance;

  static late ChatUser me;

  static User get user => auth.currentUser!;

  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token: $t');
      }
    });

  }

  static Future<bool> userExits() async {
    return (await firestore
      .collection('users')
      .doc(user.uid)
      .get())
    .exists;
  }

  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {

      if(user.exists){
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        APIs.updateActiveStatus(true);
      } else {
        createUser().then((value) => getSelfInfo());
      }

    });
  }

  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
      id: user.uid, 
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey, Im using we chat!",
      image: user.photoURL.toString(),
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
      );

    return await firestore
      .collection('users')
      .doc(user.uid)
      .set(chatUser.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(){
    return firestore
      .collection('users')
      .where('id', isNotEqualTo: user.uid)
      .snapshots();
  }

 static Future<void> updateUserInfo() async {
    return (await firestore
      .collection('users')
      .doc(user.uid)
      .update({
        'name': me.name, 
        'about': me.about,
      }));
  } 

  static Future<void> updateProfilePicture(File file) async {
    final ext = file.path.split('.').last;
    log('Extension: $ext');
    final ref = storage.ref().child('profile_Pictures/${user.uid}.$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext')).then((p0){
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });
    me.image = await ref.getDownloadURL();
    await firestore
      .collection('users')
      .doc(user.uid)
      .update({
        'image': me.image, 
      });
  }


  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  //************** Chat Screen Related APIs **************

  // chats (collection) --> conversation_id (doc) --> messages (collection) --> message (doc)

  // useful for getting conversation id
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // for getting all messages of a specific conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser user) {
    return firestore
      .collection('chats/${getConversationID(user.id)}/messages/')
      .orderBy('sent', descending: true)
      .snapshots();
  }


  static Future<void> sendMessage(ChatUser chatUser, String msg, Type type) async {

      final time = DateTime.now().millisecondsSinceEpoch.toString();

      final Message message = Message(msg: msg, toId: chatUser.id, read: '', type: type, fromID: user.uid, sent: time);

      final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/');
      await ref.doc(time).set(message.toJson());
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromID)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
    ChatUser user) {
      return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;
    log('Extension: $ext');
    final ref = storage.ref().child(
      'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0){
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });
    final ImageUrl = await ref.getDownloadURL();
    await APIs.sendMessage(chatUser, ImageUrl, Type.image);
  }

  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }
}

