import 'package:iett_where_is_my_bus/services/iett.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      await Geolocator.requestPermission();

      final location = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(location.latitude, location.longitude);
      });
    } catch (e) {
      if (e is PermissionDeniedException) {
        print('Permission denied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return const LoadingScreen();
    } else {
      return MapScreen(currentLocation: _currentLocation);
    }
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required LatLng? currentLocation,
  }) : _currentLocation = currentLocation;

  final LatLng? _currentLocation;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  TextEditingController busCodeController = TextEditingController();
  TextEditingController directionController = TextEditingController();
  Future<List<List<dynamic>>>? lineStopsFuture;
  Future<List<List<dynamic>>>? busLocationsFuture;

  void openBusSelectionBox() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: busCodeController,
                      decoration: const InputDecoration(
                          labelText: "Otobüs Kodu", hintText: "Örn: 50D")),
                  TextField(
                      controller: directionController,
                      decoration: const InputDecoration(
                          labelText: "Yön", hintText: "Örn: G yada D"))
                ],
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        lineStopsFuture = getLineStops(
                            busCodeController.text, directionController.text);

                        busLocationsFuture = getBusLocations(
                            busCodeController.text, directionController.text);
                      });
                    },
                    child: const Text("Seç"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget._currentLocation!,
          initialZoom: 12.6,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          ),
          FutureBuilder<List<List<dynamic>>>(
            future: lineStopsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MarkerLayer(markers: []);
              } else if (snapshot.hasError) {
                return const MarkerLayer(markers: []);
              } else {
                var lineStops = snapshot.data;

                List<Marker> markers = [];

                if (lineStops != null) {
                  for (var location in lineStops) {
                    markers.add(
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(
                          double.parse(location[1]),
                          double.parse(location[2]),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.red),
                      ),
                    );
                  }
                }

                return MarkerLayer(markers: markers);
              }
            },
          ),
          FutureBuilder<List<List<dynamic>>>(
            future: busLocationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MarkerLayer(
                    markers: []); // Empty layer while loading
              } else if (snapshot.hasError) {
                return const MarkerLayer(markers: []); // Empty layer on error
              } else {
                var busLocations = snapshot.data;

                List<Marker> markers = [];

                if (busLocations != null) {
                  for (var location in busLocations) {
                    markers.add(
                      Marker(
                        width: 120.0,
                        height: 120.0,
                        point: LatLng(
                          double.parse(location[1]),
                          double.parse(location[2]),
                        ),
                        child: const Icon(Icons.directions_bus,
                            color: Colors.blue),
                      ),
                    );
                  }
                }

                return MarkerLayer(markers: markers);
              }
            },
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blue,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.directions_bus),
            label: 'Select Bus Line',
            onTap: openBusSelectionBox,
          ),
          SpeedDialChild(
            child: const Icon(Icons.refresh),
            label: 'Refresh Bus Locations',
            onTap: () {
              setState(() {
                busLocationsFuture = getBusLocations(
                    busCodeController.text, directionController.text);
              });
            },
          ),
        ],
      ),
    );
  }
}
