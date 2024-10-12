import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:havadurumu/models/weather_model.dart';

class WeatherService {
  Future<String> _getLocation() async {
    // Kullanıcının konumu açık mı kontrol ettik
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Future.error("Konum servisiniz kapalı");
    }

    // Kullanıcı konum izni vermiş mi kontrol ettik
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Konum izni vermemişse tekrar izin istedik
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Yine vermemişse hata döndürdük
        Future.error("Konum izni vermelisiniz");
      }
    }

    // Kullanıcının pozisyonunu aldık
    final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

    // Kullanıcı pozisyonundan yerleşim noktasını bulduk
    final List<Placemark> placemark =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    // Şehrimizi yerleşim noktasından kaydettik
    final String? city = placemark[0].administrativeArea;

    if (city == null) Future.error("Bir sorun oluştu");

    return city!;
  }

  Future<List<WeatherModel>> getWeatherData() async {
    final String city = await _getLocation();

    final String url =
        "http://api.weatherapi.com/v1/current.json?key=d7adcd6e042b483a8c6170832240910&q=$city&aqi=no=";
    const Map<String, dynamic> headers = {
      "authorization": "apikey d7adcd6e042b483a8c6170832240910",
      "content-type": "application/json"
    };

    final dio = Dio();

    final response = await dio.get(url, options: Options(headers: headers));

    if (response.statusCode != 200) {
      return Future.error("Bir sorun oluştu");
    }

    final List list = response.data['result'];

    final List<WeatherModel> weatherList =
        list.map((e) => WeatherModel.fromJson(e)).toList();

    return weatherList;
  }
}
