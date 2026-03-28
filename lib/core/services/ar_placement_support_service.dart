import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ArPlacementSupport {
  final bool isSupported;
  final String availability;
  final String? message;

  const ArPlacementSupport._({
    required this.isSupported,
    required this.availability,
    this.message,
  });

  const ArPlacementSupport.supported({required String availability})
    : this._(isSupported: true, availability: availability);

  const ArPlacementSupport.unsupported({
    required String availability,
    required String message,
  }) : this._(
         isSupported: false,
         availability: availability,
         message: message,
       );
}

class ArPlacementSupportService {
  static const MethodChannel _channel = MethodChannel('decormate/arcore');

  static Future<ArPlacementSupport> getSupport() async {
    if (kIsWeb) {
      return const ArPlacementSupport.unsupported(
        availability: 'WEB_UNSUPPORTED',
        message: 'Room placement is only available on mobile devices.',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const ArPlacementSupport.supported(availability: 'IOS_SUPPORTED');
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      return const ArPlacementSupport.unsupported(
        availability: 'PLATFORM_UNSUPPORTED',
        message: 'Room placement is only available on Android and iOS.',
      );
    }

    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        final support = _fromResponse(
          await _channel.invokeMapMethod<String, dynamic>('getAvailability'),
        );
        if (!_isTransientAvailability(support.availability)) {
          return support;
        }

        await Future<void>.delayed(const Duration(milliseconds: 400));
      }

      final support = _fromResponse(
        await _channel.invokeMapMethod<String, dynamic>('getAvailability'),
      );
      if (_isTransientAvailability(support.availability)) {
        return const ArPlacementSupport.unsupported(
          availability: 'UNKNOWN_TIMED_OUT',
          message:
              'AR compatibility could not be confirmed right now. Try again in a moment.',
        );
      }

      return support;
    } on PlatformException {
      return const ArPlacementSupport.unsupported(
        availability: 'CHANNEL_ERROR',
        message: 'Could not verify AR compatibility on this device.',
      );
    }
  }

  static ArPlacementSupport _fromResponse(Map<String, dynamic>? response) {
    final availability = response?['availability'] as String? ?? 'UNKNOWN_ERROR';
    final isSupported = response?['supported'] as bool? ?? false;

    if (isSupported) {
      return ArPlacementSupport.supported(availability: availability);
    }

    return ArPlacementSupport.unsupported(
      availability: availability,
      message: _messageForAvailability(availability),
    );
  }

  static bool _isTransientAvailability(String availability) =>
      availability == 'UNKNOWN_CHECKING' || availability == 'UNKNOWN_TIMED_OUT';

  static String _messageForAvailability(String availability) {
    switch (availability) {
      case 'UNSUPPORTED_DEVICE_NOT_CAPABLE':
        return 'This device is not certified for Google Play Services for AR, so Place in Room is unavailable on this phone.';
      case 'UNKNOWN_CHECKING':
      case 'UNKNOWN_TIMED_OUT':
        return 'AR compatibility could not be confirmed right now. Try again in a moment.';
      default:
        return 'This device cannot start the AR placement experience.';
    }
  }
}