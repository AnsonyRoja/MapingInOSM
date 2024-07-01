import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Geolocation Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LocationData? _currentLocation;
  final Location _locationService = Location();
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final List<LatLng> _polylinePoints = [];
  Marker? marker;
  double _distance = 0.0;
  final PopupController _popupLayerController = PopupController();
  String durationByCar = "";
  String durationByBicycle = "";
  String durationByWalking = "";

  Future<void> _getLocation() async {
    try {
      final LocationData locationData = await _locationService.getLocation();
      setState(() {
        _currentLocation = locationData;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _getTravelDurations(LatLng destination) async {
    final String apiKey =
        '5b3ce3597851110001cf6248d26ac654da724fbbb28c468f91aa7321'; // Reemplaza con tu propia API key de OpenRouteService

    // Obtener la ubicación actual
    final LatLng origin =
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);

    // Consulta para obtener la ruta en automóvil
    final responseCar = await http.get(
      Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${origin.longitude},${origin.latitude}&end=${destination.longitude},${destination.latitude}'),
    );

    if (responseCar.statusCode == 200) {
      final dataCar = json.decode(responseCar.body);
      final double durationInSecCar =
          dataCar['features'][0]['properties']['segments'][0]['duration'];
      setState(() {
        durationByCar = (durationInSecCar / 60).toStringAsFixed(0);
      });
    } else {
      print('Failed to load route');
    }

    // Consulta para obtener la ruta en bicicleta
    final responseBicycle = await http.get(
      Uri.parse(
          'https://api.openrouteservice.org/v2/directions/cycling-regular?api_key=$apiKey&start=${origin.longitude},${origin.latitude}&end=${destination.longitude},${destination.latitude}'),
    );

    if (responseBicycle.statusCode == 200) {
      final dataBicycle = json.decode(responseBicycle.body);
      final double durationInSecBicycle =
          dataBicycle['features'][0]['properties']['segments'][0]['duration'];
      setState(() {
        durationByBicycle = (durationInSecBicycle / 60).toStringAsFixed(0);
      });
    } else {
      print('Failed to load route');
    }

    // Consulta para obtener la ruta a pie
    final responseWalking = await http.get(
      Uri.parse(
          'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$apiKey&start=${origin.longitude},${origin.latitude}&end=${destination.longitude},${destination.latitude}'),
    );

    if (responseWalking.statusCode == 200) {
      final dataWalking = json.decode(responseWalking.body);
      final double durationInSecWalking =
          dataWalking['features'][0]['properties']['segments'][0]['duration'];
      setState(() {
        durationByWalking = (durationInSecWalking / 60).toStringAsFixed(0);
      });
    } else {
      print('Failed to load route');
    }
  }

  Future<void> _getRoute(LatLng destination) async {
    final String apiKey =
        '5b3ce3597851110001cf6248d26ac654da724fbbb28c468f91aa7321';
    final LatLng origin =
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);

    final response = await http.get(
      Uri.parse(
          'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$apiKey&start=${origin.longitude},${origin.latitude}&end=${destination.longitude},${destination.latitude}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> coordinates =
          data['features'][0]['geometry']['coordinates'];
      final double distanceInMeters =
          data['features'][0]['properties']['segments'][0]['distance'];
      setState(() {
        _polylinePoints.clear();
        for (var coord in coordinates) {
          _polylinePoints.add(LatLng(coord[1], coord[0]));
        }
        _distance = distanceInMeters / 1000;
      });
    } else {
      print('Failed to load route');
    }
  }

  void _addMarkerAtPosition(LatLng position) {
    Marker? findMarker;
    setState(() {
      marker = Marker(
        width: 80.0,
        height: 80.0,
        point: position,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _getRoute(position);
              _getTravelDurations(position);

              _markers.forEach((value) {
                if (value.point == position) {
                  setState(() {
                    findMarker = value;
                  });
                }
              });
              if (findMarker != null) {
                _popupLayerController.togglePopup(findMarker!);
              }
            });
          },
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
      _markers.add(marker!);
      if (findMarker != null) {
        _popupLayerController.showPopupsOnlyFor([marker!]);
      }
    });
  }

  void _addMarker() {
    if (_currentLocation != null) {
      setState(() {
        _markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(
                _currentLocation!.latitude!, _currentLocation!.longitude!),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Mensaje'),
                          content: const Text('Estás en tu casa'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Aceptar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                    print('Entre aqui');
                  },
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
            alignment: Alignment.center,
            rotate: true,
          ),
        );
        _mapController.move(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          15.0,
        );
      });
    }
  }

  @override
  void initState() {
    _getLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenStreetMap Demo'),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                onTap: (tapPosition, point) {
                  _addMarkerAtPosition(point);
                  setState(() {});
                },
                initialCenter: LatLng(
                    _currentLocation!.latitude!, _currentLocation!.longitude!),
                initialZoom: 9.2,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylinePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(markers: _markers),
                PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    popupController: _popupLayerController,
                    markers: _markers,
                    popupDisplayOptions: PopupDisplayOptions(
                        builder: (BuildContext context, Marker marker) =>
                            Container(
                              width: 250,
                              child: Card(
                                elevation: 0,
                                color: Colors.green,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Punto agregado en las Coordenadas: ${marker.point.latitude}, ${marker.point.longitude}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Arials'),
                                  ),
                                ),
                              ),
                            )),
                  ),
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                          Uri.parse('https://openstreetmap.org/copyright')),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMarker,
        child: const Icon(Icons.my_location),
      ),
      bottomSheet: _polylinePoints.isNotEmpty
          ? Container(
              height: 140,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  Text(
                    'Distancia a recorrer: ${_distance.toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 16, fontFamily: 'Arial'),
                  ),
                  const SizedBox(height: 8),
                  if (durationByCar != "")
                    Text('Tiempo en auto: $durationByCar minutos'),
                  if (durationByBicycle != "")
                    Text('Tiempo en bicicleta: $durationByBicycle minutos'),
                  if (durationByWalking != "")
                    Text('Tiempo a pie: $durationByWalking minutos'),
                ],
              ),
            )
          : null,
    );
  }
}
