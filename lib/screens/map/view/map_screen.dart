import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rentall/data/models/models.dart';
import 'package:rentall/screens/blocs.dart';
import 'package:rentall/widgets/error_snackbar.dart';
import 'package:rentall/widgets/loading_widget.dart';

import '../../screens.dart';

class MapScreen extends StatefulWidget {
  static const routeName = '/map';
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _controller = Completer<GoogleMapController>();
  var _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _controller.future.then((value) => value.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Map'),
        ),
        body: BlocConsumer<RentalsBloc, RentalsState>(
          listener: (context, state) {
            if (state.status == RentalsLoadStatus.failed) {
              ScaffoldMessenger.of(context).showSnackBar(
                ErrorSnackbar(message: 'Couldn\'t laod map'),
              );
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                FutureBuilder<List<BitmapDescriptor>>(
                    initialData: const [],
                    future: _getIcons(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const LoadingWidget();
                      }
                      return GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(27, 29),
                          zoom: 5,
                        ),
                        zoomControlsEnabled: false,
                        mapType: _mapType,
                        compassEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        markers: state.rentals
                                ?.where((r) => r.location != null)
                                .map(
                                  (r) => Marker(
                                    markerId: MarkerId(r.id!),
                                    position: LatLng(
                                      r.location!.latitude,
                                      r.location!.longitude,
                                    ),
                                    infoWindow: InfoWindow(
                                      title: r.title,
                                      snippet:
                                          '${r.price}EGP/${r.rentPeriod!.name}',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          DetailsScreen.routeName,
                                          arguments: r,
                                        );
                                      },
                                    ),
                                    icon: snap.data![r.propertyType!.index - 1],
                                  ),
                                )
                                .toSet() ??
                            {},
                      );
                    }),
                if (state.status == RentalsLoadStatus.loading)
                  const LoadingWidget()
              ],
            );
          },
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'type',
              backgroundColor: Colors.white,
              child: const Icon(Icons.map, color: Colors.blueGrey),
              onPressed: () {
                setState(() {
                  if (_mapType == MapType.normal) {
                    _mapType = MapType.hybrid;
                  } else {
                    _mapType = MapType.normal;
                  }
                });
              },
            ),
            const SizedBox(height: 8.0),
            FloatingActionButton(
              heroTag: 'current',
              child: const Icon(Icons.gps_fixed),
              onPressed: () async {
                await _getCurrentLocation();
              },
            ),
          ],
        ));
  }

  Future<List<BitmapDescriptor>> _getIcons() async {
    final markers = PropertyType.values
        .map((e) => e.markerRes)
        .where((e) => e != null)
        .toList();

    final icons = <BitmapDescriptor>[];

    for (int i = 0; i < markers.length; i++) {
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(
          size: Size(24.0, 24.0),
        ),
        markers[i]!,
      );
      icons.add(icon);
    }

    return icons;
  }

  void _checkPermission() async {
    await Geolocator.checkPermission();
  }

  Future<void> _getCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    final p = await Geolocator.getCurrentPosition();
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        bearing: 0,
        target: LatLng(p.latitude, p.longitude),
        zoom: 18.0,
      ),
    ));
  }
}
