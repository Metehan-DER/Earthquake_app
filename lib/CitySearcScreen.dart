import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CityEarthquakeListScreen extends StatefulWidget {
  @override
  _CityEarthquakeListScreenState createState() =>
      _CityEarthquakeListScreenState();
}

class _CityEarthquakeListScreenState extends State<CityEarthquakeListScreen> {
  final List<String> cities = [
    'Adana',
    'Afyonkarahisar',
    'Ankara',
    'Antalya',
    'Bursa',
    'Denizli',
    'Diyarbakır',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'İstanbul',
    'İzmir',
    'Kayseri',
    'Konya',
    'Malatya',
    'Mersin',
    'Samsun',
    'Şanlıurfa',
    'Şırnak',
    'Trabzon',
    // Diğer şehirler buraya eklenebilir
  ];

  String selectedCity = 'İstanbul'; // Varsayılan olarak İstanbul seçildi
  List<dynamic> cityEarthquakes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Şehir Arama'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DropdownButton<String>(
              value: selectedCity,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCity = newValue!;
                });
              },
              items: cities.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                fetchCityEarthquakes(selectedCity);
              },
              child: Text('Depremleri ara'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: cityEarthquakes.length,
                itemBuilder: (context, index) {
                  var earthquake = cityEarthquakes[index];
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchCityEarthquakes(String selectedCity) async {
    try {
      // Şehir adına göre enlem ve boylam bilgilerini almak için bir API kullanabilirsiniz
      // Bu örnek için sabit enlem ve boylam değerleri kullanılmıştır
      Map<String, Map<String, double>> cityCoordinates = {
        'İstanbul': {'latitude': 41.0082, 'longitude': 28.9784},
        'Ankara': {'latitude': 39.9334, 'longitude': 32.8597},
        'İzmir': {'latitude': 38.4192, 'longitude': 27.1287},
        'Bursa': {'latitude': 40.1824, 'longitude': 29.0671},
        'Adana': {'latitude': 37.0, 'longitude': 35.3213},
        'Antalya': {'latitude': 36.8969, 'longitude': 30.7133},
        'Konya': {'latitude': 37.8713, 'longitude': 32.5034},
        'Gaziantep': {'latitude': 37.0662, 'longitude': 37.3833},
        'Şanlıurfa': {'latitude': 37.1591, 'longitude': 38.7969},
        'Mersin': {'latitude': 36.7955, 'longitude': 34.6178},
        'Diyarbakır': {'latitude': 37.9144, 'longitude': 40.2306},
        'Kayseri': {'latitude': 38.7312, 'longitude': 35.4787},
        'Eskişehir': {'latitude': 39.7667, 'longitude': 30.5256},
        'Denizli': {'latitude': 37.7799, 'longitude': 29.0872},
        'Samsun': {'latitude': 41.2867, 'longitude': 36.33},
        'Şırnak': {'latitude': 37.5164, 'longitude': 42.4615},
        'Malatya': {'latitude': 38.3552, 'longitude': 38.3095},
        'Trabzon': {'latitude': 41.0, 'longitude': 39.7333},
        'Erzurum': {'latitude': 39.9043, 'longitude': 41.2679},
        'Afyonkarahisar': {'latitude': 38.7507, 'longitude': 30.5567},
        // Diğer şehirlerin koordinatları buraya eklenebilir
      };

      double latitude = cityCoordinates[selectedCity]!['latitude']!;
      double longitude = cityCoordinates[selectedCity]!['longitude']!;

      DateTime now = DateTime.now();
      DateTime twentyFourHoursAgo = now.subtract(Duration(days: 1));

      var apiUrl =
          'https://deprem.afad.gov.tr/apiv2/event/filter?minlat=${latitude -
          0.5}&maxlat=${latitude + 0.5}&minlon=${longitude -
          0.5}&maxlon=${longitude + 0.5}&start=${twentyFourHoursAgo
          .toIso8601String()}&end=${now.toIso8601String()}';

      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          var decodedData = json.decode(response.body);
          cityEarthquakes = decodedData as List<dynamic>;
        });
      } else {
        print('Veri çekme işlemi başarısız oldu: ${response.statusCode}');
      }
    } catch (e) {
      print('Hata oluştu: $e');
    }
  }
}
