import 'dart:math';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class GeoUtils {
  /// Calcule la distance entre deux points en km (formule Haversine)
  static double calculateDistance(GeoFirePoint origin, GeoFirePoint destination) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    double lat1Rad = origin.latitude * (pi / 180);
    double lat2Rad = destination.latitude * (pi / 180);
    double deltaLatRad = (destination.latitude - origin.latitude) * (pi / 180);
    double deltaLngRad = (destination.longitude - origin.longitude) * (pi / 180);
    
    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Génère un geohash pour l'indexation géospatiale
  static String generateGeohash(double latitude, double longitude, {int precision = 12}) {
    const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    
    String geohash = '';
    int bits = 0;
    int bit = 0;
    bool even = true;
    
    while (geohash.length < precision) {
      if (even) {
        // Longitude
        double mid = (lngMin + lngMax) / 2;
        if (longitude >= mid) {
          bit = (bit << 1) + 1;
          lngMin = mid;
        } else {
          bit = bit << 1;
          lngMax = mid;
        }
      } else {
        // Latitude  
        double mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          bit = (bit << 1) + 1;
          latMin = mid;
        } else {
          bit = bit << 1;
          latMax = mid;
        }
      }
      
      even = !even;
      if (++bits == 5) {
        geohash += base32[bit];
        bits = 0;
        bit = 0;
      }
    }
    
    return geohash;
  }
  
  /// Valide si les coordonnées sont dans une zone acceptable (Canada)
  static bool isValidCanadianCoordinates(double lat, double lng) {
    // Limites approximatives du Canada
    return lat >= 41.0 && lat <= 84.0 && lng >= -141.0 && lng <= -52.0;
  }
}