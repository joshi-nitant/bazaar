import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapSample extends StatefulWidget {
  static final String routeName = "/google_maps";

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  var location = Location();
  LatLng _pickedLocation;
  LatLng initialLocation;

  void _selectLocation(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  _getCurrentLocation() async {
    print("inside current location");
    LatLng _currentLocation;
    var userLocation = await location.getLocation();

    _currentLocation = LatLng(
      userLocation.latitude,
      userLocation.longitude,
    );
    print("current location over");
    return _currentLocation;
  }

  Future<LatLng> _getLocation() async {
    print("inside get location");
    var location = await _getCurrentLocation();
    print(location.latitude);
    return location;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text('Baazar Map'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _pickedLocation == null
                ? () {
                    Navigator.of(context).pop(initialLocation);
                  }
                : () {
                    Navigator.of(context).pop(_pickedLocation);
                  },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _getLocation(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            if (snapshot.data == null) {
              return Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                snapshot.data.latitude,
                snapshot.data.longitude,
              ),
              zoom: 16,
            ),
            onTap: _selectLocation,
            markers: _pickedLocation == null
                ? null
                : {
                    Marker(
                      markerId: MarkerId('m1'),
                      position: _pickedLocation,
                    ),
                  },
          );
        },
      ),
    );
  }
}
