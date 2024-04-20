import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'FirebaseMessagingDemo.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'LoginSignupPage.dart'; // Import your login/signup page
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: AuthenticationWrapper(),
    );
  }
}
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Check the authentication state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (snapshot.hasData) {
            // If the user is authenticated, show the home page
            return const MyHomePage();
          } else {
            // If the user is not authenticated, show the login/signup page
            return const LoginSignupPage();
          }
        }
      },
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    FirebaseMessagingDemo(),
    // Add other pages here
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAFE'),
        backgroundColor: Colors.green[700],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          // Add other bottom navigation items here
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();

  LatLng? _center;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _listenToLatLng();
  }

  void _listenToLatLng() {
    _database.child('/').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final lat = data['LAT'] as double?;
        final lng = data['LNG'] as double?;
        if (lat != null && lng != null) {
          setState(() {
            _center = LatLng(lat, lng);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _center == null
        ? Center(child: CircularProgressIndicator())
        : GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center!,
        zoom: 50.0,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('Sydney'),
          position: _center!,
          infoWindow: const InfoWindow(
            title: "Sydney",
            snippet: "Capital of New South Wales",
          ),
        ),
      },
    );
  }
}
