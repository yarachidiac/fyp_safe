import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseMessagingDemo extends StatefulWidget {
  FirebaseMessagingDemo({Key? key}) : super(key: key);

  @override
  _FirebaseMessagingDemoState createState() => _FirebaseMessagingDemoState();
}

class _FirebaseMessagingDemoState extends State<FirebaseMessagingDemo> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String? _deviceToken;
  // List<Message> _messagesList = [];

  @override
  void initState() {
    super.initState();
    // _configureFirebaseListeners();
    _getToken();
  }

  _getToken() async {
    _deviceToken = await _firebaseMessaging.getToken();
    print("Device Token: $_deviceToken");

    if (_deviceToken != null) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection('userDetails')
            .where('Role', isEqualTo: 1)
            .get();

        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          await _firestore
              .collection('userDetails')
              .doc(doc.id)
              .update({'deviceToken': _deviceToken});
        }
        print('Device Token inserted into Firestore successfully.');
      } catch (e) {
        print('Error inserting Device Token into Firestore: $e');
      }
    }
  }

  // _configureFirebaseListeners() {
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print('onMessage: $message');
  //     _setMessage(message.data);
  //   });
  //
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     print('onMessageOpenedApp: $message');
  //     _setMessage(message.data);
  //   });
  // }
  //
  // _setMessage(Map<String, dynamic> message) {
  //   final notification = message['notification'];
  //   final data = message['data'];
  //   final String title = notification['title'] ?? '';
  //   final String body = notification['body'] ?? '';
  //   String mMessage = data['message'] ?? '';
  //   print("Title: $title, body: $body, message: $mMessage");
  //   setState(() {
  //     Message msg = Message(title, body, mMessage);
  //     _messagesList.add(msg);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Messaging Demo'),
      ),
      body: ListView.builder(
        // itemCount: _messagesList.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              // title: Text(_messagesList[index].title),
              // subtitle: Text(_messagesList[index].body),
              // You can customize how messages are displayed here
            ),
          );
        },
      ),
    );
  }
}
//
// class Message {
//   final String title;
//   final String body;
//   final String message;
//
//   Message(this.title, this.body, this.message);
// }
