import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';





Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

   @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin  {
late AnimationController _blinkController; // Add this line
  late Timer _blinkTimer; // New timer variable
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 late GoogleMapController mapController;
  LatLng _center = const LatLng(40.712776, -74.005974); // Default to NYC coordinates
  final Set<Marker> _markers = {};

    String? _selectedImageUrl;
  String? _selectedTitle;

  late AnimationController _controller; // Add this line
  late Animation<Offset> _offsetAnimation; // And this line

   late AnimationController _animationController; // This is new
  late Animation<double> _animation; // This is new

  void _onMarkerTap(String imageUrl, String title) {
      _controller.reset(); // Reset the animation
  _controller.forward(); // Start the animation
    setState(() {
      _selectedImageUrl = imageUrl;
      _selectedTitle = title;
    });
  }

 Widget _buildSelectedMarkerInfo() {
    if (_selectedImageUrl == null || _selectedTitle == null) {
      return const SizedBox.shrink();  // Return an empty widget if no marker has been selected
    }



    return Dismissible(
    direction: DismissDirection.down,
    onDismissed: (direction) {
      setState(() {
        _selectedImageUrl = null;
        _selectedTitle = null;
      });
    },
    key: Key(_selectedTitle!),
    child: SlideTransition(
      position: _offsetAnimation,
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              _selectedTitle!,
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 84, 28, 189),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                 fontFamily: 'Nunito',
              ),
            ),
            Image.network(
              _selectedImageUrl!,
              height: 250,
              width: 300,
            ),
          ],
        ),
      ),
    ),
  );
}

  void _onMapCreated(GoogleMapController controller) async{
    mapController = controller;
    String style = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
  mapController.setMapStyle(style);
    await _fetchMarkers();
  }

Future<void> _fetchMarkers() async {
  final snapshot = await _firestore.collection('Art').get();

final BitmapDescriptor markerImage = await _createMarkerImageFromAsset(context);

  snapshot.docs.forEach((doc) {
    final MarkerId markerId = MarkerId(doc.id);
    final GeoPoint pos = doc['position'];
    final String title = doc['Title'];
    final String imageUrl = doc['imageUrl'];

 precacheImage(NetworkImage(imageUrl), context);

    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(pos.latitude, pos.longitude),
      infoWindow: InfoWindow(title: title),
      icon: markerImage,
    onTap: () {
      _onMarkerTap(imageUrl, title);
    },
    );

    

    setState(() {
      _markers.add(marker);
    });
  }
);
}

Future<BitmapDescriptor> _createMarkerImageFromAsset(BuildContext context) async {
  final ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);
  final BitmapDescriptor bitmapDescriptor = await BitmapDescriptor.fromAssetImage(imageConfiguration, 'assets/marker.png');
  return bitmapDescriptor;
}




   @override
  void initState() {
    super.initState();
     _animationController = AnimationController(
    duration: const Duration(seconds: 2), // Adjust the duration as needed
    vsync: this,
  );

  _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

  _animationController.forward(); // Starts the animation

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _getUserLocation();

      @override
  void dispose() {
    _blinkController.dispose();
    _blinkTimer.cancel(); // Make sure to cancel the timer when disposing of the widget
    super.dispose();
  }

_blinkController = AnimationController(
  duration: const Duration(milliseconds: 400), // A blink will take 400 milliseconds
  vsync: this,
)..repeat(reverse: true); // This makes the animation repeat indefinitely
 
 _blinkTimer = Timer.periodic(Duration(seconds: 4), (Timer t) {
      _blinkController.forward().then(
        (_) => _blinkController.reverse(),
      );
    });

 
  }

    @override
  void dispose() {
     _animationController.dispose();
    _controller.dispose();
_blinkController.dispose();
    super.dispose();
  }
  


_getUserLocation() async {
  // Check if location permission is granted
  if (await Permission.location.request().isGranted) {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
    });
    mapController.moveCamera(
      CameraUpdate.newLatLng(_center),
    );
  }
}


  @override
Widget build(BuildContext context) {
  final _blinkAnimation = Tween<double>(begin: 50, end: 0).animate(_blinkController);

  return MaterialApp(
    home: FadeTransition( 
      opacity: _animation,
      child: Stack(
      children: <Widget>[
        GoogleMap(
            onTap: (LatLng location) {
              
         

    setState(() {
      _selectedImageUrl = null;
      _selectedTitle = null;
    });
  },
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 10,
          ),
          markers: _markers,
          myLocationEnabled: true,
          mapType: MapType.normal,
        ),
        Positioned(
          top: 70,
          left: 20,
          right: 20,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
               color: const Color.fromARGB(255, 84, 28, 189),
               borderRadius: BorderRadius.circular(30.0)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
               AnimatedBuilder(
  animation: _blinkController, // This animation will trigger a rebuild every time its value changes
  builder: (BuildContext context, Widget? child) {
    return Container(
      width: 30,  // Animated width
      height: _blinkAnimation.value,  // Animated height
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50)), // This makes the corners round
        color: Colors.white,
      ),
    );
  },
),
                const SizedBox(width: 50), // Adding some space between the circles
          AnimatedBuilder(
  animation: _blinkController, // This animation will trigger a rebuild every time its value changes
  builder: (BuildContext context, Widget? child) {
    return Container(
      width: 30,  // Animated width
      height: _blinkAnimation.value,  // Animated height
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50)), // This makes the corners round
        color: Colors.white,
      ),
    );
  },
), // This closing parenthesis was missing.
              ]
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _buildSelectedMarkerInfo(),
        ),
      ],
    ), // The closing bracket for Stack was missing.
  ));
}
}