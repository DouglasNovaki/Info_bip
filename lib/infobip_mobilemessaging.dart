
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:infobip_mobilemessaging/models/Installation.dart';
import 'package:infobip_mobilemessaging/models/PersonalizeContext.dart';
import 'package:infobip_mobilemessaging/models/UserData.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/Configuration.dart';
import 'models/LibraryEvent.dart';
import 'models/Message.dart';

class InfobipMobilemessaging {
  static const MethodChannel _channel =
    const MethodChannel('infobip_mobilemessaging');
  static const EventChannel _libraryEvent =
    const EventChannel('infobip_mobilemessaging/broadcast');
  static StreamSubscription _libraryEventSubscription = _libraryEvent.receiveBroadcastStream()
      .listen((dynamic event) {
        print('Received event: $event');
        LibraryEvent libraryEvent = LibraryEvent.fromJson(jsonDecode(event));
        print("callbacks:");
        print(callbacks.toString());
        print("libraryEvent.eventName:");
        print(libraryEvent.eventName);
        if (callbacks.containsKey(libraryEvent.eventName)) {
          print("libraryEvent.eventName: " + libraryEvent.eventName);
          callbacks[libraryEvent.eventName]?.forEach((callback) {
            print("Try to call callback");
            if (libraryEvent.eventName == LibraryEvent.MESSAGE_RECEIVED) {
              callback(Message.fromJson(libraryEvent.payload));
            } else {
              callback(libraryEvent.payload);
            }
          });
        }
      },
      onError: (dynamic error) {
        print('Received error: ${error.message}');
      },
      cancelOnError: true);

  static Map<String, List<Function>?> callbacks = new HashMap();

  static Future<void> on(String eventName, Function callack) async {
    if (callbacks.containsKey(eventName)) {
      var existed = callbacks[eventName];
      existed?.add(callack);
      callbacks.update(eventName, (val) => existed);
    } else {
      callbacks.putIfAbsent(eventName, () => List.filled(1, callack));
    }
    _libraryEventSubscription.resume();
  }

  static Future<void> init(Configuration configuration) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    configuration.pluginVersion = packageInfo.version;
    await _channel.invokeMethod('init', jsonEncode(configuration.toJson()));
  }

  static Future<void> saveUser(UserData userData) async {
    await _channel.invokeMethod('saveUser', jsonEncode(userData.toJson()));
  }

  static Future<UserData> fetchUser() async {
    return await _channel.invokeMethod('fetchUser');
  }

  static Future<UserData> getUser() async {
    return await _channel.invokeMethod('getUser');
  }

  static Future<void> saveInstallation(Installation installation) async {
    await _channel.invokeMethod('saveInstallation', jsonEncode(installation.toJson()));
  }

  static Future<Installation> fetchInstallation() async {
    return await _channel.invokeMethod('fetchInstallation');
  }

  static Future<Installation> getInstallation() async {
    String result = await _channel.invokeMethod('getInstallation');
    return Installation.fromJson(jsonDecode(result));
  }

  static Future<void> personalize(PersonalizeContext context) async {
    await _channel.invokeMethod('personalize', jsonEncode(context.toJson()));
  }

  static Future<void> depersonalize() async {
    await _channel.invokeMethod('depersonalize');
  }

  static Future<void> depersonalizeInstallation(String pushRegistrationId) async {
    await _channel.invokeMethod('depersonalizeInstallation', pushRegistrationId);
  }

  static Future<void> setInstallationAsPrimary(InstallationPrimary installationPrimary) async {
    await _channel.invokeMethod('setInstallationAsPrimary',installationPrimary.toJson());
  }
}
