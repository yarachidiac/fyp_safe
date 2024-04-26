import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);
  static const route = '/notification-screen';

  @override
  Widget build(BuildContext context) {
    final message =
        ModalRoute.of(context)!.settings.arguments as RemoteMessage?;
    if (message != null && message.notification != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('New Page'),
        ),
        body: Center(
          child: Column(
            children: [
              Text(message.notification!.title ?? 'No Title'),
              Text(message.notification!.body ?? 'No Body'),

              // Display the image from the notification message
              // Display the image from the notification message
              if (message.notification!.android != null)
                Image.network(
                  message.notification!.android!.imageUrl ?? '',
                  // Provide a placeholder image or loading indicator
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return CircularProgressIndicator();
                  },
                  // Adjust width and height as needed
                  width: 200,
                  height: 200,
                ),
              Text('Username : ${message.data}'),
            ],
          ),
        ),
      );
    } else {
      // Handle the case when message or message.notification is null
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('Invalid Notification'),
        ),
      );
    }
  }
}
