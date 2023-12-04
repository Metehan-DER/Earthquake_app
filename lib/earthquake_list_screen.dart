import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart'; // İzinleri kullanabilmek için eklenen paket

class EarthquakeListScreen extends StatefulWidget {
  @override
  _EarthquakeListScreenState createState() => _EarthquakeListScreenState();
}

class _EarthquakeListScreenState extends State<EarthquakeListScreen> {
  List<dynamic> earthquakes = [];

  @override
  void initState() {
    super.initState();
    checkPermissions(); // İzinleri kontrol etme işlemi initState içinde çağrılıyor
  }

  Future<void> checkPermissions() async {
    // Kullanıcının konum izni durumunu kontrol et
    PermissionStatus locationPermissionStatus = await Permission.location.status;
    if (!locationPermissionStatus.isGranted) {
      // Eğer konum izni verilmemişse, izin iste
      await Permission.location.request();
    }

    // Verileri çekme işlemi
    fetchData();
  }

  Future<void> fetchData() async {
    DateTime now = DateTime.now();
    DateTime twentyFourHoursAgo = now.subtract(Duration(days: 1));

    var apiUrl =
        'https://deprem.afad.gov.tr/apiv2/event/filter?start=${twentyFourHoursAgo.toIso8601String()}&end=${now.toIso8601String()}&orderby=time';
        // 'https://deprem.afad.gov.tr/apiv2/event/filter?start=${twentyFourHoursAgo.toIso8601String()}&end=${now.toIso8601String()}&limit=20&orderby=time';
        // alttaki son 20 depremi gösteriyor
    var response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      setState(() {
        var decodedData = json.decode(response.body);
        earthquakes = decodedData as List<dynamic>;

        earthquakes.forEach((earthquake) {
          earthquake['magnitude'] = double.parse(earthquake['magnitude']);
        });

        earthquakes.sort((a, b) {
          DateTime dateA = DateTime.parse(a['date']);
          DateTime dateB = DateTime.parse(b['date']);
          return dateB.compareTo(dateA);
        });
      });
    } else {
      print('Veri çekme işlemi başarısız oldu: ${response.statusCode}');
    }
  }

  String convertToTurkishDateTime(String dateStr) {
    DateTime date = DateTime.parse(dateStr).toLocal();
    var formatter = DateFormat('dd.MM.yyyy HH:mm');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Son 24 Saatteki Depremler'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: earthquakes.isNotEmpty
                ? Chip(
              label: Text(
                'Toplam Deprem Sayısı: ${earthquakes.length}',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            )
                : SizedBox.shrink(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: earthquakes.length,
        itemBuilder: (context, index) {
          var earthquake = earthquakes[index];
          return ListTile(
            title: Text(
              'Büyüklük: ${earthquake['magnitude']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 8),
                Text('Tarih: ${earthquake['date']}'),
                Text('Konum: ${earthquake['location']}'),
                Text('Enlem: ${earthquake['latitude']}'),
                Text('Boylam: ${earthquake['longitude']}'),
                Text('Derinlik: ${earthquake['depth']}'),
                Text('Ülke: ${earthquake['country']}'),
                Text('İl: ${earthquake['province']}'),
                Text('İlçe: ${earthquake['district']}'),
                Text('Mahalle: ${earthquake['neighborhood']}'),
                Container(
                  color: Colors.red,
                  height: 4,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
