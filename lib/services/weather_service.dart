import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey =
      '40f078c39f8765a476fdb7d97083cd95'; // Reemplaza con tu API Key

  Future<double?> getTemperature(String city) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(
          'Weather data: $data'); // Añadir declaración de impresión para ver los datos
      return data['main']['temp'];
    } else {
      print('Error fetching weather data: ${response.statusCode}');
      return null;
    }
  }
}
