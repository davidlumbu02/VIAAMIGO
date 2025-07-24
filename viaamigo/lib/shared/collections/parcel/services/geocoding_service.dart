import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class GeocodingService {
  static const String _mapboxToken = 'pk.eyJ1IjoiZGF2aWRsdW1idTAyIiwiYSI6ImNtY2VkY29mazBhMm8ya29nc2t4MTNpc2QifQ.n8ufiPfOXuSQ6YmqiWC3Dw'; // 🔒 à sécuriser plus tard

  /// Suggestions d’adresse (autocomplete)
  static Future<List<GeocodingResult>> searchAddressSuggestions(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json?access_token=$_mapboxToken&limit=10&language=fr&country=ca'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'];

        return features.map((f) {
          final coords = f['geometry']['coordinates'];
          final context = f['context'] ?? [];

          // Extraction des champs contextuels (ville, province, etc.)
          String city = '';
          String province = '';
          String postalCode = '';
          String country = '';

          for (var c in context) {
            if (c['id'].toString().startsWith('place')) city = c['text'] ?? '';
            if (c['id'].toString().startsWith('region')) province = c['text'] ?? '';
            if (c['id'].toString().startsWith('postcode')) postalCode = c['text'] ?? '';
            if (c['id'].toString().startsWith('country')) country = c['text'] ?? '';
          }

          return GeocodingResult(
            latitude: coords[1],
            longitude: coords[0],
            formattedAddress: f['place_name'],
            city: city,
            province: province,
            postalCode: postalCode,
            country: country,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      print('Erreur Mapbox search: $e');
      return [];
    }
  }

  /// Géocodage direct (adresse → coordonnées)
  static Future<GeocodingResult?> getCoordinatesFromAddress(String address) async {
    final results = await searchAddressSuggestions(address);
    return results.isNotEmpty ? results.first : null;
  }

  /// Géocodage inverse (coordonnées → adresse)
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$_mapboxToken&language=fr&limit=1'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['features'][0]['place_name'];
      }

      return null;
    } catch (e) {
      print('Erreur géocodage inverse Mapbox: $e');
      return null;
    }
  }
}

class GeocodingResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String city;
  final String province;
  final String postalCode;
  final String country;

  GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.country,
  });

  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);
}

/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  /// Convertit une adresse en coordonnées géographiques
  static Future<GeocodingResult?> getCoordinatesFromAddress(String address) async {
    try {
      // Encoder l'adresse pour l'URL
      final encodedAddress = Uri.encodeComponent(address);
      
      // Construire l'URL de requête
      final url = Uri.parse(
        '$_baseUrl/search?q=$encodedAddress&format=json&limit=1&addressdetails=1&countrycodes=ca'
      );
      
      // Faire la requête HTTP
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ViaAmigo/1.0 (contact@viaamigo.com)', // Requis par Nominatim
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        
        if (results.isNotEmpty) {
          final result = results.first;
          final double lat = double.parse(result['lat']);
          final double lng = double.parse(result['lon']);
          
          return GeocodingResult(
            latitude: lat,
            longitude: lng,
            formattedAddress: result['display_name'] ?? address,
            city: result['address']?['city'] ?? result['address']?['town'] ?? '',
            province: result['address']?['state'] ?? '',
            postalCode: result['address']?['postcode'] ?? '',
            country: result['address']?['country'] ?? '',
          );
        }
      }
      
      return null;
    } catch (e) {
      print('Erreur géocodage: $e');
      return null;
    }
  }
  
  /// Convertit des coordonnées en adresse (géocodage inverse)
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ViaAmigo/1.0 (contact@viaamigo.com)',
        },
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['display_name'];
      }
      
      return null;
    } catch (e) {
      print('Erreur géocodage inverse: $e');
      return null;
    }
  }

  /// Renvoie plusieurs suggestions pour une adresse partielle
static Future<List<GeocodingResult>> searchAddressSuggestions(String query) async {
  try {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      '$_baseUrl/search?q=$encodedQuery&format=json&limit=5&addressdetails=1&countrycodes=ca'
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'ViaAmigo/1.0 (contact@viaamigo.com)',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> results = json.decode(response.body);

      return results.map((item) {
        final double lat = double.parse(item['lat']);
        final double lng = double.parse(item['lon']);

        return GeocodingResult(
          latitude: lat,
          longitude: lng,
          formattedAddress: item['display_name'] ?? query,
          city: item['address']?['city'] ?? item['address']?['town'] ?? '',
          province: item['address']?['state'] ?? '',
          postalCode: item['address']?['postcode'] ?? '',
          country: item['address']?['country'] ?? '',
        );
      }).toList();
    }

    return [];
  } catch (e) {
    print('Erreur recherche suggestions: $e');
    return [];
  }
}

}

class GeocodingResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String city;
  final String province;
  final String postalCode;
  final String country;
  
  GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.country,
  });
  
  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);
}*/