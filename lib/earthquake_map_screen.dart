import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class EarthquakeMapScreen extends StatefulWidget {
  @override
  _EarthquakeMapScreenState createState() => _EarthquakeMapScreenState();
}

class _EarthquakeMapScreenState extends State<EarthquakeMapScreen> {
  Position? _currentPosition;
  List<dynamic> _earthquakes = [];
  String? _currentLocationName;
  late Timer _timer;
  DateTime? lastQuakeTime;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _timer = Timer.periodic(
        Duration(seconds: 5),
        (Timer t) => _getEarthquakes(
            _currentPosition!.latitude, _currentPosition!.longitude));
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  Future<void> requestPermissions() async {
    // Konum iznini kontrol et ve yoksa izin iste
    var permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _getEarthquakes(position.latitude, position.longitude);
        _getLocationName(position.latitude, position.longitude);
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getEarthquakes(double latitude, double longitude) async {
    DateTime now = DateTime.now();
    DateTime twentyFourHoursAgo = now.subtract(Duration(days: 1));

    var apiUrl =
        'https://deprem.afad.gov.tr/apiv2/event/filter?minlat=${latitude - 1}&maxlat=${latitude + 1}&minlon=${longitude - 1}&maxlon=${longitude + 1}&start=${twentyFourHoursAgo.toIso8601String()}&end=${now.toIso8601String()}';

    var response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      print(response.body);
      setState(() {
        var decodedData = json.decode(response.body);
        List<dynamic> newEarthquakes = decodedData as List<dynamic>;

        if (lastQuakeTime != null) {
          // Yalnızca yeni depremleri al
          newEarthquakes = newEarthquakes.where((quake) {
            DateTime quakeTime = DateTime.parse(quake['date']);
            return quakeTime.isAfter(lastQuakeTime!);
          }).toList();
        }

        if (newEarthquakes.isNotEmpty) {
          _earthquakes.addAll(newEarthquakes);
          lastQuakeTime = DateTime.parse(_earthquakes.first['date']);
          _showEarthquakeAlertDialog(_earthquakes.first); // Yeni deprem varsa alert dialog göster
        }

        _earthquakes.forEach((earthquake) {
          earthquake['magnitude'] = double.parse(earthquake['magnitude']);
        });

        _earthquakes.sort((a, b) {
          DateTime dateA = DateTime.parse(a['date']);
          DateTime dateB = DateTime.parse(b['date']);
          return dateB.compareTo(dateA);
        });
      });
    } else {
      print('Veri çekme işlemi başarısız oldu: ${response.statusCode}');
    }
  }


  Future<void> _getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      setState(() {
        _currentLocationName =
            "${place.subAdministrativeArea}, ${place.administrativeArea}";
      });
    } catch (e) {
      print(e);
    }
  }

  void _showEarthquakeAlertDialog(Map<String, dynamic> earthquakeData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Yeni Deprem'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Yakınınızda yeni bir deprem oldu!'),
              SizedBox(height: 10),
              Text('Büyüklük: ${earthquakeData['magnitude']}'),
              Text('Tarih: ${earthquakeData['date']}'),
              Text('Boylam: ${earthquakeData['longitude']}'),
              Text('Derinlik: ${earthquakeData['depth']}'),
              Text('İl: ${earthquakeData['province']}'),
              Text('İlçe: ${earthquakeData['district']}'),
              Text('Mahalle: ${earthquakeData['neighborhood']}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' $_currentLocationName'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: _earthquakes.isNotEmpty
                ? Chip(
                    label: Text(
                      'Toplam Deprem Sayısı: ${_earthquakes.length}',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
      body: Center(
        child: _currentPosition != null
            ? _earthquakes.isNotEmpty
                ? ListView.builder(
                    itemCount: _earthquakes.length,
                    itemBuilder: (context, index) {
                      var earthquake = _earthquakes[index];
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text('Büyüklük: ${earthquake['magnitude']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Tarih: ${earthquake['date']}'),
                              Text('Konum: ${earthquake['location']}'),
                              Text('Enlem: ${earthquake['latitude']}'),
                              Text('Boylam: ${earthquake['longitude']}'),
                              Text('Derinlik: ${earthquake['depth']}'),
                              Text('Ülke: ${earthquake['country']}'),
                              Text('İl: ${earthquake['province']}'),
                              Text('İlçe: ${earthquake['district']}'),
                              Text('Mahalle: ${earthquake['neighborhood']}'),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Text('Yakınınızda deprem bulunmuyor.')
            : CircularProgressIndicator(),
      ),
    );
  }
}
