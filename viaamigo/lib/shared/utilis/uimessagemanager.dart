import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Types de messages supportés
enum MessageType {
  success,
  error,
  warning,
  info,
  confirmation,
  loading,
  custom
}

/// Positions d'affichage des messages
enum MessagePosition {
  top,
  bottom,
}

/// Configuration d'un message
class MessageConfig {
  final String title;
  final String message;
  final MessageType type;
  final MessagePosition position;
  final Duration duration;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final TextButton? mainButton;  // ✅ Corrigé: TextButton? au lieu de Widget?
  final bool isDismissible;
  final bool showProgressIndicator;
  final double? borderRadius;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const MessageConfig({
    required this.title,
    required this.message,
    required this.type,
    this.position = MessagePosition.bottom,
    this.duration = const Duration(seconds: 3),
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onTap,
    this.mainButton,
    this.isDismissible = true,
    this.showProgressIndicator = false,
    this.borderRadius,
    this.margin,
    this.padding,
  });
}

/// Centralized UI Message Manager
class UIMessageManager {
  // Singleton instance
  static final UIMessageManager _instance = UIMessageManager._internal();
  factory UIMessageManager() => _instance;
  UIMessageManager._internal();

  // Default configuration
  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _longDuration = Duration(seconds: 5);
  static const Duration _shortDuration = Duration(seconds: 2);
  static const MessagePosition _defaultPosition = MessagePosition.bottom;

  /// Shows a success message
  static void success(
    String message, {
    String? title,
    Duration? duration,
    MessagePosition? position,
    VoidCallback? onTap,
  }) {
    _showMessage(MessageConfig(
      title: title ?? "Success",
      message: message,
      type: MessageType.success,
      position: position ?? _defaultPosition,
      duration: duration ?? _defaultDuration,
      onTap: onTap,
    ));
  }

  /// Shows an error message
  static void error(
    String message, {
    String? title,
    Duration? duration,
    MessagePosition? position,
    VoidCallback? onTap,
  }) {
    _showMessage(MessageConfig(
      title: title ?? "Error",
      message: message,
      type: MessageType.error,
      position: position ?? _defaultPosition,
      duration: duration ?? _longDuration,
      onTap: onTap,
    ));
  }

  /// Shows a warning message
  static void warning(
    String message, {
    String? title,
    Duration? duration,
    MessagePosition? position,
    VoidCallback? onTap,
  }) {
    _showMessage(MessageConfig(
      title: title ?? "Warning",
      message: message,
      type: MessageType.warning,
      position: position ?? _defaultPosition,
      duration: duration ?? _defaultDuration,
      onTap: onTap,
    ));
  }

  /// Shows an info message
  static void info(
    String message, {
    String? title,
    Duration? duration,
    MessagePosition? position,
    VoidCallback? onTap,
  }) {
    _showMessage(MessageConfig(
      title: title ?? "Information",
      message: message,
      type: MessageType.info,
      position: position ?? _defaultPosition,
      duration: duration ?? _defaultDuration,
      onTap: onTap,
    ));
  }

  /// Shows a confirmation message
  static void confirmation(
    String message, {
    String? title,
    Duration? duration,
    MessagePosition? position,
    VoidCallback? onTap,
  }) {
    _showMessage(MessageConfig(
      title: title ?? "Confirmation",
      message: message,
      type: MessageType.confirmation,
      position: position ?? _defaultPosition,
      duration: duration ?? _defaultDuration,
      onTap: onTap,
    ));
  }

  // ============ SPECIALIZED METHODS ============

  /// Validation error message
  static void validationError(String message, {Duration? duration}) {
    error(
      message,
      title: "Missing fields",
      duration: duration ?? _defaultDuration,
    );
  }

  /// Network error message
  static void networkError([String? customMessage]) {
    error(
      customMessage ?? "Check your internet connection and try again.",
      title: "Connection problem",
      duration: _longDuration,
    );
  }

  /// Permission error message
  static void permissionError(String message) {
    error(
      message,
      title: "Insufficient permissions",
      duration: _longDuration,
    );
  }

  /// Address/geolocation error message
  static void addressError([String? customMessage]) {
    error(
      customMessage ?? "Unable to locate this address. Please check your input.",
      title: "Address not found",
      duration: _defaultDuration,
    );
  }

  /// Limit reached message
  static void limitReached(String message) {
    warning(
      message,
      title: "Limit reached",
      duration: _defaultDuration,
    );
  }

  /// Successful save message
  static void saveSuccess([String? customMessage]) {
    success(
      customMessage ?? "Data saved successfully",
      duration: _shortDuration,
    );
  }

  /// Photo upload message
  static void photoUploadSuccess(int count) {
    success(
      "$count photo${count > 1 ? 's' : ''} added",
      title: "Photos added",
      duration: _shortDuration,
    );
  }

  /// Data cleared message
  static void dataCleared(String dataType) {
    info(
      "$dataType data has been cleared",
      title: "Data removed",
      duration: _shortDuration,
    );
  }

  /// Date inconsistency message
  static void dateError(String message) {
    error(
      message,
      title: "Date error",
      duration: _defaultDuration,
    );
  }

  /// Successful update message
  static void updateSuccess(String item) {
    success(
      "$item saved successfully",
      title: "Update",
      duration: _shortDuration,
    );
  }

  /// Loading message
  static void loading(String message, {String? title}) {
    _showMessage(MessageConfig(
      title: title ?? "Loading",
      message: message,
      type: MessageType.loading,
      position: _defaultPosition,
      duration: const Duration(seconds: 10), // Longer for loading
      isDismissible: false,
      showProgressIndicator: true,
    ));
  }

  /// Close all messages
  static void dismissAll() {
    Get.closeAllSnackbars();
  }

  /// Completely custom message
  static void showCustom({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration? duration,
    MessagePosition? position,
    VoidCallback? onTap,
    TextButton? mainButton,  // ✅ Corrigé: TextButton? au lieu de Widget?
    bool isDismissible = true,
  }) {
    _showMessage(MessageConfig(
      title: title,
      message: message,
      type: MessageType.custom,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      duration: duration ?? _defaultDuration,
      position: position ?? _defaultPosition,
      onTap: onTap,
      mainButton: mainButton,
      isDismissible: isDismissible,
    ));
  }

  // ============ INTERNAL METHODS ============

  /// Main method to display messages
  static void _showMessage(MessageConfig config) {
    final colors = _getMessageColors(config.type);
    
    Get.snackbar(
      config.title,
      config.message,
      titleText: _buildTitle(config.title, colors.textColor, config.icon ?? _getMessageIcon(config.type)),
      messageText: _buildMessage(config.message, colors.textColor),
      snackPosition: config.position == MessagePosition.top 
          ? SnackPosition.TOP 
          : SnackPosition.BOTTOM,
      backgroundColor: config.backgroundColor ?? colors.backgroundColor,
      colorText: config.textColor ?? colors.textColor,
      duration: config.duration,
      isDismissible: config.isDismissible,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: const Duration(milliseconds: 500),
      borderRadius: config.borderRadius ?? 12,
      margin: config.margin ?? const EdgeInsets.all(16),
      padding: config.padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      mainButton: config.mainButton,  // ✅ Maintenant compatible
      onTap: config.onTap != null ? (_) => config.onTap!() : null,
      shouldIconPulse: config.type == MessageType.error || config.type == MessageType.warning,
      leftBarIndicatorColor: _getLeftBarColor(config.type),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Build title with icon
  static Widget _buildTitle(String title, Color textColor, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: textColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Build message
  static Widget _buildMessage(String message, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 28), // Alignment with title
      child: Text(
        message,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Get colors based on message type
  static MessageColors _getMessageColors(MessageType type) {
    switch (type) {
      case MessageType.success:
        return MessageColors(
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
        );
      case MessageType.error:
        return MessageColors(
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
      case MessageType.warning:
        return MessageColors(
          backgroundColor: Colors.orange.shade600,
          textColor: Colors.white,
        );
      case MessageType.info:
        return MessageColors(
          backgroundColor: Colors.blue.shade600,
          textColor: Colors.white,
        );
      case MessageType.confirmation:
        return MessageColors(
          backgroundColor: Colors.purple.shade600,
          textColor: Colors.white,
        );
      case MessageType.loading:
        return MessageColors(
          backgroundColor: Colors.grey.shade700,
          textColor: Colors.white,
        );
      case MessageType.custom:
        return MessageColors(
          backgroundColor: Colors.grey.shade600,
          textColor: Colors.white,
        );
    }
  }

  /// Get icon based on message type
  static IconData _getMessageIcon(MessageType type) {
    switch (type) {
      case MessageType.success:
        return LucideIcons.checkCircle;
      case MessageType.error:
        return LucideIcons.xCircle;
      case MessageType.warning:
        return LucideIcons.alertTriangle;
      case MessageType.info:
        return LucideIcons.info;
      case MessageType.confirmation:
        return LucideIcons.check;
      case MessageType.loading:
        return LucideIcons.loader2;
      case MessageType.custom:
        return LucideIcons.messageSquare;
    }
  }

  /// Get left bar color
  static Color _getLeftBarColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Colors.green.shade400;
      case MessageType.error:
        return Colors.red.shade400;
      case MessageType.warning:
        return Colors.orange.shade400;
      case MessageType.info:
        return Colors.blue.shade400;
      case MessageType.confirmation:
        return Colors.purple.shade400;
      case MessageType.loading:
        return Colors.grey.shade400;
      case MessageType.custom:
        return Colors.grey.shade400;
    }
  }
}

/// Utility class for message colors
class MessageColors {
  final Color backgroundColor;
  final Color textColor;

  const MessageColors({
    required this.backgroundColor,
    required this.textColor,
  });
}

/// Extension for additional shortcuts
extension UIMessageExtensions on UIMessageManager {
  /// Specific messages for your delivery application
  static void parcelCreated() {
    UIMessageManager.success("Parcel created successfully");
  }

  static void parcelUpdated() {
    UIMessageManager.success("Parcel updated");
  }

  static void addressValidated() {
    UIMessageManager.success("Address validated");
  }

  static void photoLimitReached(int maxPhotos) {
    UIMessageManager.limitReached("Maximum $maxPhotos photos allowed");
  }

  static void dimensionsValidated() {
    UIMessageManager.success("Dimensions validated");
  }

  static void pickupTimeSet() {
    UIMessageManager.success("Pickup time slot set");
  }

  static void deliveryTimeSet() {
    UIMessageManager.success("Delivery time slot set");
  }

  static void handlingSelected(String handlingType) {
    UIMessageManager.success("Handling '$handlingType' selected");
  }

  static void priceCalculated() {
    UIMessageManager.info("Price calculated automatically");
  }

  static void floorUpdated() {
    UIMessageManager.updateSuccess("Floor");
  }

  static void elevatorUpdated() {
    UIMessageManager.updateSuccess("Elevator preference");
  }

  static void handlingUpdated() {
    UIMessageManager.updateSuccess("Handling assistance");
  }

  static void photoRemoved() {
    UIMessageManager.info("Photo removed");
  }

  static void addressCleared() {
    UIMessageManager.dataCleared("Address");
  }

  static void receiverInfoCleared() {
    UIMessageManager.dataCleared("Receiver information");
  }

  static void uploadingPhoto() {
    UIMessageManager.loading("Uploading photo...");
  }

  static void calculatingPrice() {
    UIMessageManager.loading("Calculating price...");
  }

  static void savingData() {
    UIMessageManager.loading("Saving data...");
  }

  static void geolocating() {
    UIMessageManager.loading("Locating address...");
  }

  // Date-related messages
  static void startDateMustBeEarlierThanEnd() {
    UIMessageManager.dateError("Start date must be earlier than end date");
  }

  static void dateMustBeInFuture() {
    UIMessageManager.dateError("Date must be in the future");  
  }

  static void minimumWindowDuration(int minutes) {
    UIMessageManager.dateError("The time window must be at least $minutes minutes long");
  }

  // Phone validation
  static void invalidPhoneNumber() {
    UIMessageManager.validationError("Please enter a valid phone number");
  }

  // File-related messages
  static void fileTooLarge(String fileName, String maxSize) {
    UIMessageManager.warning("$fileName exceeds $maxSize");
  }

  static void unsupportedFileFormat(String fileName) {
    UIMessageManager.warning("$fileName is not a valid image");
  }

  static void uploadFailed(String fileName) {
    UIMessageManager.error("Upload failed for $fileName");
  }

  // Specialized validation messages
  static void completeReceiverInfoOrDisableSwitch() {
    UIMessageManager.validationError("Please complete the receiver information or disable the switch");
  }

  static void checkTimeWindow() {
    UIMessageManager.validationError("Please check the time window");
  }

  static void specifyAddress(String addressType) {
    UIMessageManager.validationError("Please specify a $addressType address");
  }

  static void enterValidDimensions() {
    UIMessageManager.validationError("Please enter valid dimensions (non-zero and numeric)");
  }

  static void chooseWeight() {
    UIMessageManager.validationError("Please choose a weight");
  }

  static void chooseSize() {
    UIMessageManager.validationError("Please choose a size");
  }

  static void chooseHandling() {
    UIMessageManager.validationError("Please choose handling assistance");
  }

  // Permission-specific messages
  static void cameraPermissionRequired() {
    UIMessageManager.permissionError("Camera access is required");
  }

  static void storagePermissionRequired() {
    UIMessageManager.permissionError("Storage access is required");
  }

  static void locationPermissionRequired() {
    UIMessageManager.permissionError("Location access is required");
  }

  // Action messages with buttons
  static void confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = "CONFIRM",
  }) {
    UIMessageManager.showCustom(
      title: title,
      message: message,
      backgroundColor: Colors.orange.shade600,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          onConfirm();
        },
        child: Text(
          confirmText,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static void retryAction({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    UIMessageManager.showCustom(
      title: title,
      message: message,
      backgroundColor: Colors.red.shade600,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          onRetry();
        },
        child: const Text(
          "RETRY",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
