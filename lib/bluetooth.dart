import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

typedef GarageOpenerIdentifier = bool Function(BluetoothDevice device);
const String COMMAND_CHARACTERISITC_UUID =
    "dfb5483e-36e1-4688-b7f5-8807361b26a8";
const String STATUS_CHARACTERISTIC_UUID =
    "beb5483e-36e1-4688-b7f5-ea07361b26a8";

enum GarageOpenerConnectionState {
  notSearched,
  found,
  disconnected,
  connecting,
  connected,
  disconnecting
}

class GarageOpenerBLEDevice {
  int id = 0;
  BluetoothDevice? device;
  Stream<BluetoothDeviceState>? deviceBluetoothState;

  late Stream<GarageOpenerConnectionState> deviceConnectionStateStream;
  final StreamController<GarageOpenerConnectionState>
      _deviceConnectionStateStreamController = StreamController.broadcast();
  StreamSubscription<BluetoothDeviceState>? _listeningOnDeviceState;

  // ValueNotifier<bool> deviceFound = ValueNotifier(false);
  // ValueNotifier<bool> deviceConnected = ValueNotifier(false);

  BluetoothCharacteristic? deviceLastStatusCharacteristic;
  BluetoothCharacteristic? deviceLastCommandCharacteristic;

  // These stream the characterestic itself.
  late Stream<BluetoothCharacteristic> deviceStatusCharacteristicStream;
  late Stream<BluetoothCharacteristic> deviceCommandCharacteristicStream;

  final StreamController<BluetoothCharacteristic>
      _deviceStatusCharStreamController = StreamController.broadcast();
  final StreamController<BluetoothCharacteristic>
      _deviceCommandCharStreamController = StreamController.broadcast();

  StreamSubscription<List<BluetoothService>>? _listeningOnDeviceCharacteristics;

  GarageOpenerBLEDevice(this.id) {
    deviceStatusCharacteristicStream = _deviceStatusCharStreamController.stream;
    deviceCommandCharacteristicStream =
        _deviceCommandCharStreamController.stream;
    deviceConnectionStateStream = _deviceConnectionStateStreamController.stream;
    _deviceConnectionStateStreamController
        .add(GarageOpenerConnectionState.notSearched);
  }
}

// Currently we assume we can only connect to one garage at any moment.
class BluetoothBase {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  late final String commandCharacteristicUUID;
  late final String statusCharacteristicUUID;

  late Stream<BluetoothState> deviceBluetoothState;

  Map<int, GarageOpenerBLEDevice> devices = {};

  static final BluetoothBase _instance =
      BluetoothBase(COMMAND_CHARACTERISITC_UUID, STATUS_CHARACTERISTIC_UUID);
  static BluetoothBase get instance => _instance;

  // BluetoothDevice? foundDevice;
  // Stream<BluetoothDeviceState>? foundDeviceBluetoothState;

  // ValueNotifier<bool> garageRemoteFound = ValueNotifier(false);
  // ValueNotifier<bool> garageRemoteConnected = ValueNotifier(false);

  // late Stream<BluetoothCharacteristic> garageRemoteStatusCharacteristicStream;
  // late Stream<BluetoothCharacteristic> garageRemoteCommandCharacteristicStream;

  // BluetoothCharacteristic? garageRemoteLastStatusCharacteristic;
  // BluetoothCharacteristic? garageRemoteLastCommandCharacteristic;

  // These stream the characterestic itself.
  // final StreamController<BluetoothCharacteristic>
  //     _garageRemoteStatusCharStreamController = StreamController.broadcast();
  // final StreamController<BluetoothCharacteristic>
  //     _garageRemoteCommandCharStreamController = StreamController.broadcast();

  // StreamSubscription<List<BluetoothService>>?
  //     _listeningOnGarageRemoteCharacteristics;

  BluetoothBase(this.commandCharacteristicUUID, this.statusCharacteristicUUID) {
    deviceBluetoothState = flutterBlue.state;

    // garageRemoteStatusCharacteristicStream =
    //     _garageRemoteStatusCharStreamController.stream;
    // garageRemoteCommandCharacteristicStream =
    //     _garageRemoteCommandCharStreamController.stream;
  }

  bool registerGarage(int id) {
    if (devices[id] != null) {
      print("Can't Add, Already Added");
      return false;
    }
    devices[id] = GarageOpenerBLEDevice(id);
    return true;
  }

// TODO: Rename?
  Future<bool> findGarage(int id, GarageOpenerIdentifier filter,
      {int scanTimeSeconds = 5}) async {
    if (!await checkBluetoothIsAvailable()) {
      return false;
    }
    if (!await checkBluetoothIsOn()) {
      return false;
    }

    BluetoothDevice? device = await _findDevice(filter, scanTimeSeconds);

    if (device == null) {
      return false;
    }

    // foundDevice = device;
    // foundDeviceBluetoothState = foundDevice?.state.asBroadcastStream();
    // broadcastBoolValueChanged(garageRemoteFound, true);

    devices[id]?.device = device;
    devices[id]?.deviceBluetoothState =
        devices[id]?.device?.state.asBroadcastStream();
    devices[id]
        ?._deviceConnectionStateStreamController
        .add(GarageOpenerConnectionState.found);

    // devices[id]
    //     ?._deviceConnectionStateStreamController
    //     .addStream(devices[id]?.deviceBluetoothState);
    // broadcastBoolValueChanged(devices[id]?.deviceFound, true);
    return true;
  }

  Future<bool> connect(int id) async {
    if (devices[id]?.device == null) {
      return false;
    }

    await _startListeningOnDeviceConnectionStates(id);
    if (await _connectToDevice(devices[id]!.device!)) {
      await _startListeningOnGarageCharacteristics(
          id, statusCharacteristicUUID, commandCharacteristicUUID);
      await discoverServices(id);
      return true;
    }
    return false;

    // if (foundDevice == null) {
    //   return false;
    // }
    // if (await _connectToDevice(foundDevice!)) {
    //   await _startListeningOnGarageCharacteristics(
    //       statusCharacteristicUUID, commandCharacteristicUUID);
    //   await discoverServices();
    //   return true;
    // }
    // return false;
  }

// Use await?
  Future<void> discoverServices(int id) async {
    await devices[id]?.device?.discoverServices();
  }

  Future<void> writeToCharacteristic(
      BluetoothCharacteristic characteristic, String value,
      {bool withoutResponse = true}) async {
    await characteristic.write(utf8.encode(value),
        withoutResponse: withoutResponse);
  }

  Future<void> disconnect(int id) async {
    if (devices[id]?._listeningOnDeviceCharacteristics != null) {
      await devices[id]?._listeningOnDeviceCharacteristics?.cancel();
      devices[id]?._listeningOnDeviceCharacteristics = null;
    }
    await devices[id]?.device?.disconnect();

    // Hack so that the disconnect event is relayed before we stop listening on
    // deviceBluetooth State.

    await Future.delayed(Duration(seconds: 1));

// Should we cancel this?
    if (devices[id]?._listeningOnDeviceState != null) {
      await devices[id]?._listeningOnDeviceState?.cancel();
      devices[id]?._listeningOnDeviceState = null;
    }
    devices[id]?.deviceBluetoothState == null;

    devices[id]?.device = null;
  }

  Future<bool> _startListeningOnDeviceConnectionStates(int id) async {
    if (devices[id]?.device == null) {
      return false;
    } else {
      if (devices[id]?._listeningOnDeviceState != null) {
        return false;
      }
      devices[id]?._listeningOnDeviceState =
          devices[id]?.deviceBluetoothState?.listen((event) {
        switch (event) {
          case BluetoothDeviceState.connected:
            devices[id]
                ?._deviceConnectionStateStreamController
                .add(GarageOpenerConnectionState.connected);
            break;
          case BluetoothDeviceState.disconnected:
            devices[id]
                ?._deviceConnectionStateStreamController
                .add(GarageOpenerConnectionState.disconnected);
            break;
          case BluetoothDeviceState.connecting:
            devices[id]
                ?._deviceConnectionStateStreamController
                .add(GarageOpenerConnectionState.connecting);
            break;
          case BluetoothDeviceState.disconnecting:
            devices[id]
                ?._deviceConnectionStateStreamController
                .add(GarageOpenerConnectionState.disconnecting);
            break;
        }
      });
      return true;
    }
  }

  Future<bool> _startListeningOnGarageCharacteristics(
    int id,
    String statusCharacteristicUUID,
    String commandCharacteristicUUID,
  ) async {
    if (devices[id]?.device == null) {
      return false;
    } else {
      if (devices[id]?._listeningOnDeviceCharacteristics != null) {
        return false;
      }
      devices[id]?._listeningOnDeviceCharacteristics =
          devices[id]?.device?.services.listen((services) {
        services.forEach((service) {
          service.characteristics.forEach((characteristic) {
            if (characteristic.uuid.toString() == statusCharacteristicUUID) {
              devices[id]
                  ?._deviceStatusCharStreamController
                  .add(characteristic);
              devices[id]?.deviceLastStatusCharacteristic = characteristic;
              devices[id]?.deviceLastStatusCharacteristic?.setNotifyValue(true);
              print("Status Characteristic Found");
            } else if (characteristic.uuid.toString() ==
                commandCharacteristicUUID) {
              devices[id]
                  ?._deviceCommandCharStreamController
                  .add(characteristic);
              devices[id]?.deviceLastCommandCharacteristic = characteristic;
              print("Command Characteristic Found");
            }
          });
        });
      });
    }
    return true;
  }

  Future<bool> checkBluetoothIsAvailable() async {
    return flutterBlue.isAvailable;
  }

  Future<bool> checkBluetoothIsOn() async {
    return flutterBlue.isOn;
  }

  Future<BluetoothDevice?> _findDevice(
      GarageOpenerIdentifier filter, int scanTimeSeconds) async {
    flutterBlue.startScan(timeout: Duration(seconds: scanTimeSeconds));
    List<ScanResult> correctResultList = await flutterBlue.scanResults
        .firstWhere((resultList) =>
            resultList.any((element) => filter(element.device)));

    BluetoothDevice? _foundDevice = correctResultList
        .firstWhere((element) => filter(element.device))
        .device;

    return _foundDevice;
  }

  Future<bool> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: Duration(seconds: 4));
      return true;
    } catch (error) {
      log(error.toString());
      return false;
    }
  }

  // Future<Map<String, BluetoothService>> _getAllServices(
  //     BluetoothDevice device) async {
  //   List<BluetoothService> allServices = await device.discoverServices();
  //   Map<String, BluetoothService> services = {};
  //   allServices.forEach((service) {
  //     services[service.uuid.toString()] = service;
  //   });
  //   return services;
  // }

  // Future<Map<String, BluetoothCharacteristic>> _getAllCharacteristics(
  //     BluetoothDevice device) async {
  //   var services = await _getAllServices(device);
  //   Map<String, BluetoothCharacteristic> characteristics = {};
  //   services.values.forEach((service) {
  //     service.characteristics.forEach((characteristic) {
  //       characteristics[characteristic.uuid.toString()] = characteristic;
  //     });
  //   });
  //   return characteristics;
  // }

  // BluetoothCharacteristic? _getCharacteristic(String characteristicUUID,
  //     Map<String, BluetoothCharacteristic> characteristics) {
  //   return characteristics[Guid(characteristicUUID).toString()];
  // }
}

void broadcastBoolValueChanged(ValueNotifier<bool>? notifier, bool value) {
  if (notifier == null) {
    return;
  }
  if (notifier.value != value) {
    notifier.value = value;
    notifier.notifyListeners();
    print("Successfully Notified Device Found!");
  }
}
