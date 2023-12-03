import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart'; // Geocoding paketini içeri aktar

class EarthquakeMapScreen extends StatefulWidget {
  @override
  _EarthquakeMapScreenState createState() => _EarthquakeMapScreenState();
}

class _EarthquakeMapScreenState extends State<EarthquakeMapScreen> {
  Position? _currentPosition;
  List<dynamic> _earthquakes = [];
  String? _currentLocationName;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    // Her dakika _getEarthquakes fonksiyonunu çağırmak için zamanlayıcı başlat
    _timer = Timer.periodic(Duration(minutes: 1), (Timer t) => _getEarthquakes(_currentPosition!.latitude, _currentPosition!.longitude));
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel(); // Widget kaldırıldığında zamanlayıcıyı iptal et
  }

  // Kullanıcının mevcut konumunu almak için Geolocator'u kullan
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

  // API'den deprem verilerini almak için HTTP isteği gönder
  Future<void> _getEarthquakes(double latitude, double longitude) async {
    DateTime now = DateTime.now();
    DateTime twentyFourHoursAgo = now.subtract(Duration(days: 1));
    if (_earthquakes.isNotEmpty) {
      _showEarthquakeAlertDialog();
    }

    var apiUrl =
        'https://deprem.afad.gov.tr/apiv2/event/filter?minlat=${latitude - 1}&maxlat=${latitude + 1}&minlon=${longitude - 1}&maxlon=${longitude + 1}&start=${twentyFourHoursAgo.toIso8601String()}&end=${now.toIso8601String()}&limit=10&orderby=timedesc';

    var response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      print(response.body); // API'den dönen verileri konsola yazdır
      setState(() {
        var decodedData = json.decode(response.body);
        _earthquakes = decodedData as List<dynamic>; // Verileri güncelle

        // Deprem büyüklüklerini double türüne dönüştür
        _earthquakes.forEach((earthquake) {
          earthquake['magnitude'] = double.parse(earthquake['magnitude']);
        });

        // Tarihleri en yakın tarihten itibaren sırala
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

  // Mevcut konumun ismini almak için Geocoding paketini kullan
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

  // AlertDialog'u göstermek için fonksiyon
  void _showEarthquakeAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Yeni Deprem'),
          content: Text('Yakınınızda yeni bir deprem oldu!'),
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
        title: Text('Deprem Haritası , $_currentLocationName}'),
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
