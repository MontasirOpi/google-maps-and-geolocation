import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng _currentPosition = LatLng(0, 0);
  Marker? _currentMarker;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _startLocationUpdates();
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _currentMarker = Marker(
        markerId: MarkerId('current_location'),
        position: _currentPosition,
      );
    });

    _animateToPosition(_currentPosition);
  }

  void _startLocationUpdates() {
    Timer.periodic(Duration(seconds: 10), (timer) async {
      Position position = await Geolocator.getCurrentPosition();
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition;
        _currentMarker = Marker(
          markerId: MarkerId('current_location'),
          position: newPosition,
        );
      });

      _animateToPosition(newPosition);
    });
  }

  Future<void> _animateToPosition(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map Animation')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 15,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _currentMarker != null ? {_currentMarker!} : {},
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}