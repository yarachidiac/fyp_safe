import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'SignInPage.dart';
import 'main.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late MqttServerClient client;
  late CameraController _controller;
  List<Uint8List> _capturedImages = [];
  static const int maxImages = 10;
  int _imageCount = 0;
  bool _showCameraPreview = false;
  bool _showCaptureButton = true;
  String _captureMessage = '';
  String? _errorMessage;
  int _currentStep = 0;
  var pongCount = 0;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String? _deviceToken;
  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    client = MqttServerClient('test.mosquitto.org', '1883');
    client.logging(on: false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    client = MqttServerClient('test.mosquitto.org', '1883');
    client.logging(on: false);

    try {
      await client.connect();
      print('Connected');
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stepper(
              currentStep: _showCameraPreview ? 1 : _currentStep,
              onStepContinue: () async {
                if (_currentStep == 0) {
                  // First step: validate fields and proceed
                  if (_validateFields()) {
                    setState(() {
                      _currentStep++;
                    });
                    _initCamera();
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else if (_currentStep == 1) {
                  if (!_showCaptureButton && _imageCount == maxImages) {
                    //await sendmQtt();
                    await _publishImages();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Finish capturing first"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              steps: [
                Step(
                  title: Text('Enter Username, Email, and Password'),
                  isActive: !_showCameraPreview,
                  content: Container(
                    height: screenHeight *
                        0.4, // Set the height to 40% of the screen height
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(labelText: 'Username'),
                        ),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email'),
                        ),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(labelText: 'Password'),
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: Text('Capture Images'),
                  isActive: _showCameraPreview,
                  content: Container(
                    height: screenHeight *
                        0.4, // Set the height to 40% of the screen height
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (_showCameraPreview)
                            Column(
                              children: [
                                Container(
                                  height: screenHeight *
                                      0.4 *
                                      0.75, // 75% of the content container's height
                                  child: CameraPreview(_controller),
                                ),
                                Visibility(
                                  visible: _showCaptureButton,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (_imageCount < maxImages) {
                                        await _captureAndPublishImages();
                                      }
                                    },
                                    child: Text('Capture Image'),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _captureMessage,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              height:
                  20), // Add some space between the Stepper and the Sign In button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignInPage()),
              );
            },
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }

  bool _validateFields() {
    // Reset error message
    _errorMessage = null;

    // Check if username, email, and password fields are not empty
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _errorMessage = 'Please fill in all fields.';
      return false;
    }

    // Check if email format is valid
    if (!_isValidEmail(_emailController.text)) {
      _errorMessage = 'Invalid email format.';
      return false;
    }

    // Check if password is strong enough
    if (!_isStrongPassword(_passwordController.text)) {
      _errorMessage = 'Password is too weak.';
      return false;
    }

    return true;
  }

  bool _isStrongPassword(String password) {
    // Minimum length for the password
    final minLength = 6; // Example: Minimum length of 6 characters

    return password.length >= minLength;
  }

  bool _isValidEmail(String email) {
    // Regular expression for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    CameraDescription? frontCamera;
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }
    if (frontCamera != null) {
      _controller = CameraController(frontCamera, ResolutionPreset.medium);
      await _controller.initialize();
      setState(() {
        _showCameraPreview = true;
      });
    } else {
      print('No front camera found');
    }
  }

  Future<void> _captureAndPublishImages() async {
    setState(() {
      _showCaptureButton = false; // Hide the capture button
      _captureMessage = 'Hold on, change the angle of your face...';
    });
    for (int i = 0; i < maxImages; i++) {
      try {
        XFile imageFile = await _controller.takePicture();
        final Uint8List imageBytes = await File(imageFile.path).readAsBytes();
        _capturedImages.add(imageBytes);
        setState(() {
          _imageCount++; // Update _imageCount and rebuild the UI
        });
      } catch (e) {
        print('Error capturing image: $e');
      }
    }
    setState(() {
      _captureMessage = 'You can continue now';
    });
  }

  Future<int> sendmQtt() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;
      print('User registered: ${user!.uid}');
    } catch (e) {
      print('Error registering user: $e');
      // Handle error here
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          setState(() {
            _errorMessage =
                'The email address is already in use by another account.';
          });
        } else {
          setState(() {
            _errorMessage =
                'An unexpected error occurred. Please try again later.';
          });
        }
      }
    }

    // Save user details in Firestore
    await FirebaseFirestore.instance.collection('userDetails').doc().set(
        {
          'username': _usernameController.text,
          'email': _emailController.text,
          'role': 1,
        },
        SetOptions(
            merge:
                true)); // Use SetOptions.merge to create the document if it doesn't exist
    print('User details saved in Firestore');

    print('usernameeeeeeeeeeeeeeee, $_usernameController.text');
    Map<String, dynamic> payloadData = {
      'username': _usernameController.text,
      'images': _capturedImages
          .map((image) => base64Encode(image))
          .toList(), // Convert image bytes to base64 strings
    };

    // Convert the JSON object to a string
    String payloadString = json.encode(payloadData);

    client.logging(on: true);
    client.setProtocolV311();
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
    client.pongCallback = pong;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    print('EXAMPLE::Mosquitto client connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      print(
          'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
    }

    const pubTopic = 'topicSafe/train';

    final builder = MqttClientPayloadBuilder();

    builder.addString(_captureMessage);

    // client.publishMessage('your_topic', MqttQos.exactlyOnce, builder.payload!);

    client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);

    print('EXAMPLE::Sleeping....');
    await MqttUtilities.asyncSleep(60);

    print('EXAMPLE::Disconnecting');
    client.disconnect();

    print('EXAMPLE::Exiting normally');
    return 0;
  }

  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    } else {
      print(
          'EXAMPLE::OnDisconnected callback is unsolicited or none, this is incorrect - exiting');
    }
    if (pongCount == 3) {
      print('EXAMPLE:: Pong count is correct');
    } else {
      print('EXAMPLE:: Pong count is incorrect, expected 3. actual $pongCount');
    }
  }

  void onConnected() {
    print(
        'EXAMPLE::OnConnected client callback - Client connection was successful');
  }

  void pong() {
    print('EXAMPLE::Ping response client callback invoked');
    pongCount++;
  }

  Future<void> _publish(String topic, Uint8List payload) async {
    print("Publishing to topic: $topic");
    print('ffddddddfdf $payload');
    await _connect();
    final payloadBuffer = Uint8Buffer();
    payloadBuffer.addAll(payload);
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        await client.publishMessage(topic, MqttQos.exactlyOnce, payloadBuffer);
        print('Payload published successfully');
      } catch (e) {
        print('Error publishing payload: $e');
      }
    } else {
      print('Error: MQTT client is not connected');
    }
  }

  Future<void> _publishImages() async {
    await client.connect();
    // print('immmmmmmmmmmmmmmmmmmmm, $images');
    // Save user details in Firebase Authentication
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;
      print('User registered: ${user!.uid}');
    } catch (e) {
      print('Error registering user: $e');
      // Handle error here
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          setState(() {
            _errorMessage =
                'The email address is already in use by another account.';
          });
        } else {
          setState(() {
            _errorMessage =
                'An unexpected error occurred. Please try again later.';
          });
        }
      }
    }

    // Save user details in Firestore
    _deviceToken = await _firebaseMessaging.getToken();

    await FirebaseFirestore.instance.collection('userDetails').doc().set(
        {
          'username': _usernameController.text,
          'email': _emailController.text,
          'role': 1,
          'token': _deviceToken,
        },
        SetOptions(
            merge:
                true)); // Use SetOptions.merge to create the document if it doesn't exist
    print('User details saved in Firestore');

    // Show dialog to inform user about successful sign-up
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: Text('Sign Up Successful'),
    //       content: Text('You have successfully signed up.'),
    //       actions: [
    //         TextButton(
    //           onPressed: () {
    //             Navigator.of(context).pop(); // Close the dialog
    //             _navigateToHomePage(context); // Navigate to the home page
    //           },
    //           child: Text('OK'),
    //         ),
    //       ],
    //     );
    //   },
    // );

    // // Publish images
    // images.forEach((imageBytes) {
    //   _publish(topic, imageBytes);
    // });.
    // Create a JSON object with username and image bytes

    // List to hold base64 images
    //  List<String> base64Images = [];
    //
    //  for (var imageBytes in _capturedImages) {
    //    final imageBase64 = base64Encode(imageBytes);
    //    base64Images.add(imageBase64);
    //  }
    // Split _capturedImages into two batches
    List<Uint8List> firstBatch = _capturedImages.sublist(0, 5);
    List<Uint8List> secondBatch = _capturedImages.sublist(5);
    // Publish the first batch
    await _connect();
    await _publishBatch(firstBatch);
    // Publish the second batch
    await _publishBatch(secondBatch);
  }

  Future<void> _publishBatch(List<Uint8List> images) async {
    List<String> base64Images =
        images.map((imageBytes) => base64Encode(imageBytes)).toList();

// Create a map with username and images
    Map<String, dynamic> payloadMap = {
      'username': _usernameController.text,
      'images': base64Images,
    };

    print('payloadMap, $payloadMap');
    print(
        '_capturedImages, ${_capturedImages.map((imageBytes) => base64Encode(imageBytes)).toList()}');
    // Convert the map to a JSON string
    String payloadJson = jsonEncode(payloadMap);
    print('payloadJSon, $payloadJson');
    //await _publish(topic, Uint8List.fromList(payloadString.codeUnits));
    // print("Publishing to topic: $topic");
    // final payloadBuffer = Uint8Buffer();
    // payloadBuffer.addAll(payload);
    final builder = MqttClientPayloadBuilder();

    builder.addString(payloadJson);
    //builder.addString(_usernameController.text);
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        await client.publishMessage(
            "topicSafe/train", MqttQos.exactlyOnce, builder.payload!);

        // _capturedImages.forEach((imageBytes) {
        //   final payloadBuffer = Uint8Buffer();
        //   payloadBuffer.addAll(imageBytes);
        //   client.publishMessage("topicSafe/train", MqttQos.atMostOnce, payloadBuffer);
        // });
        print('Payload published successfully');
      } catch (e) {
        print('Error publishing payload: $e');
      }
    } else {
      print('Error: MQTT client is not connected');
    }
  }

  // void _navigateToHomePage(BuildContext context) {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (context) => MyHomePage()),
  //   );
  // }
}
