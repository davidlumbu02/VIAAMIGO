// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/collections/users/model/timeslot_model.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/badges.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/devices.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/documents.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/driver_preference.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/payment_methodes.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/sender_preference.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/settings.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/travel_patterns.dart';
import 'package:viaamigo/shared/collections/users/subcollection/services%20and%20models/vehicules.dart';

/// Initialise toutes les sous-collections d'un utilisateur avec des données MVP
Future<void> initializeUserStructure(String userId) async {
  try {
    await Future.wait([
      // settings/app
      UserSettingsService().updateUserSettings(userId, UserSettingsService().getDefaultSettings()),

      // vehicles/placeholder
      VehiclesService().createEmptyVehicleDoc(userId),

// driver_preferences/{userId}
      DriverPreferencesService().updateDriverPreferences(
        userId,
        DriverPreferences(
          maxDetourKm: 10.0,
          preferredParcelSizes: ['small', 'medium', 'large'],
          avoidHighways: false,
          preferredPaymentMethods: ['wallet', 'card'],
          autoAcceptMatches: false,
          minimumPricePerKm: 0.25,
          availableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          availableTimeSlots: [
            TimeSlot(day: 'monday', start: '08:00', end: '12:00'),
            TimeSlot(day: 'monday', start: '14:00', end: '18:00'),
            TimeSlot(day: 'friday', start: '09:00', end: '17:00'),
          ],
          packageTypesAccepted: ['standard', 'fragile'],
          acceptsUrgentDeliveries: true,
          advancePickupAllowed: true,
          automaticMatchingEnabled: true,
        ),
      ),

      // sender_preferences/{userId}
      SenderPreferencesService().updateSenderPreferences(
        userId,
        SenderPreferences(
          preferredDriverRating: 4.5,
          preferredPickupTimes: [
            TimeSlot(day: 'tuesday', start: '10:00', end: '12:00'),
            TimeSlot(day: 'thursday', start: '14:00', end: '16:00'),
          ],
          preferredDeliverySpeed: 'standard',
          maxPricePerKm: 0.45,
          defaultInsuranceLevel: 'basic',
          preferredConfirmationMethod: 'pin',
          flexibleTimingAllowed: true, insuranceDefault: true, notifyOnNearbyDrivers: true,
        ),
      ),

      // travel_patterns/placeholder
      TravelPatternsService().addTravelPattern(
        userId,
        TravelPattern(
          id: 'placeholder',
          fromLocation: const GeoPoint(0, 0),
          toLocation: const GeoPoint(0, 0),
          fromAddress: '',
          toAddress: '',
          frequency: 'occasional',
          confidence: 0.0,
          detectedAutomatically: true,
          tripsCount: 0,
        ),
      ),

      // payment_methods/placeholder
      PaymentMethodsService().addPaymentMethod(
        userId,
        PaymentMethod(
          id: 'placeholder',
          type: 'card',
          last4: '0000',
          holderName: '',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),

      // documents/placeholder
      UserDocumentsService().addUserDocument(
        userId,
        UserDocument(
          id: 'placeholder',
          type: 'ID',
          url: '',
          uploadedAt: DateTime.now(),
        ),
      ),

      // devices/{random}
      UserDevicesService().registerDevice(
        userId,
        UserDevice(
          id: '',
          fcmToken: 'placeholder-token',
          platform: 'android',
          model: 'unknown',
          osVersion: '0.0.0',
          appVersion: '1.0.0',
          lastUsedAt: DateTime.now(),
          isCurrentDevice: false,
          deviceName: 'Device initialisé',
        ),
      ),

      // badges/{earned}
      UserBadgesService().awardBadge(
        userId,
        UserBadge(
          id: 'placeholder',
          badgeId: 'welcome',
          earnedAt: DateTime.now(),
        ),
      ),
    ]);
  } catch (e) {
    print('Erreur lors de l\'initialisation des sous-collections: $e');
    rethrow;
  }
}
