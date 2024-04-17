import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;
  final DatabaseReference _database =
  FirebaseDatabase.instance.reference();

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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sydney'),
          backgroundColor: Colors.green[700],
        ),
        body: _center == null
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
        ),
      ),
    );
  }
}
