import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue/gen/flutterblue.pbjson.dart';
import 'package:garage_ble/bluetooth.dart';

class GarageOpener {
  // TODO: Do we need this?
  int id;
  String label;
  GarageOpenerIdentifier garageIdentifier;
  // Save Icon?

  BluetoothBase bluetoothBase = BluetoothBase.instance;

  late Stream<String> status;
  late StreamController<String> _statusStreamController;

  late Stream<GarageOpenerConnectionState> connectionStatus;
  late StreamController<GarageOpenerConnectionState>
      _connectionStatusStreamController;

  StreamSubscription? statusSubscription;
  StreamSubscription? connectionStatusSubscription;

  bool isConnected = false;

  GarageOpener(this.id, this.label, this.garageIdentifier) {
    _statusStreamController = StreamController.broadcast();
    status = _statusStreamController.stream;

    _connectionStatusStreamController = StreamController.broadcast();
    connectionStatus = _connectionStatusStreamController.stream;
    _connectionStatusStreamController
        .add(GarageOpenerConnectionState.notSearched);

    if (bluetoothBase.registerGarage(id)) {
      _listenOnDeviceConnectionStatus();
      print("Garage Opener $id registered");
    } else {
      print("Problem Adding Garage Opener. Check Id");
    }
  }

  Future<bool> startFindingGarage() async {
    if (await bluetoothBase.findGarage(id, garageIdentifier)) {
      // _listenOnDeviceConnectionStatus();
      return true;
    }
    return false;
  }

  Future<bool> connectToGarage() async {
    return await bluetoothBase.connect(id);
  }

  // Future<void> discoverServices() async {
  //   await bluetoothBase.discoverServices();
  // }

  // void _onDeviceFoundHandler() {
  //   print("Device $id Found");
  //   GarageOpenerBLEDevice? garageOpenerBLEDevice = bluetoothBase.devices[id];
  //   if (garageOpenerBLEDevice != null) {
  //     if (garageOpenerBLEDevice.deviceFound.value) {
  //       _connectionStatusStreamController.add(GarageConnectionState.found);
  //       connectionStatusSubscription =
  //           bluetoothBase.devices[id]?.deviceBluetoothState?.listen((event) {
  //         print("Device $id event $event");
  // switch (event) {
  //   case BluetoothDeviceState.connected:
  //     _connectionStatusStreamController
  //         .add(GarageConnectionState.connected);
  //     isConnected = true;
  //     break;
  //   case BluetoothDeviceState.disconnected:
  //     _connectionStatusStreamController
  //         .add(GarageConnectionState.disconnected);
  //     isConnected = false;
  //     break;
  //   case BluetoothDeviceState.connecting:
  //     _connectionStatusStreamController
  //         .add(GarageConnectionState.connecting);
  //     break;
  //   case BluetoothDeviceState.disconnecting:
  //     _connectionStatusStreamController
  //         .add(GarageConnectionState.disconnecting);
  //     break;
  // }
  //       });
  //     }
  //   }
  // }

  void _listenOnDeviceConnectionStatus() {
    // bluetoothBase.devices[id]?.deviceFound.addListener(_onDeviceFoundHandler);
    connectionStatusSubscription =
        bluetoothBase.devices[id]?.deviceConnectionStateStream.listen((event) {
      print("Device $id event $event");
      switch (event) {
        case GarageOpenerConnectionState.connected:
          _connectionStatusStreamController
              .add(GarageOpenerConnectionState.connected);
          isConnected = true;
          break;
        case GarageOpenerConnectionState.disconnected:
          _connectionStatusStreamController
              .add(GarageOpenerConnectionState.disconnected);
          isConnected = false;
          break;
        case GarageOpenerConnectionState.connecting:
          _connectionStatusStreamController
              .add(GarageOpenerConnectionState.connecting);
          break;
        case GarageOpenerConnectionState.disconnecting:
          _connectionStatusStreamController
              .add(GarageOpenerConnectionState.disconnecting);
          break;
        case GarageOpenerConnectionState.notSearched:
          // TODO: Handle this case.
          break;
        case GarageOpenerConnectionState.found:
          // TODO: Handle this case.
          break;
      }
    });
  }

// TODO: Remove subscriptions
  bool listenOnStatusCharacteristic() {
    if (bluetoothBase.devices[id]?.deviceLastStatusCharacteristic == null) {
      print("Still Null Why?");
      return false;
    }
    if (statusSubscription != null) {
      print("Already Subscribed");
      String lastStatus = utf8.decode(
          bluetoothBase.devices[id]!.deviceLastStatusCharacteristic!.lastValue);
      print("Last Status is $lastStatus");
      return false;
    }
    statusSubscription = bluetoothBase
        .devices[id]?.deviceLastStatusCharacteristic?.value
        .listen((binaryValue) {
      String value = utf8.decode(binaryValue);
      _statusStreamController.add(value);
      print("New Status $value");
    });
    return true;
  }

  void addStatus(String status) {
    _statusStreamController.add(status);
  }

  // void listenOnStatusCharacteristic() {
  //   bluetoothBase.garageRemoteStatusCharacteristicStream.last.then((characteristic){
  //     print("Status Characteristic Found");
  //     characteristic.value.listen((binaryValue) {
  //       String value = utf8.decode(binaryValue);
  //       _statusStreamController.add(value);
  //       print("New Status $value");
  //     });
  //     characteristic.setNotifyValue(true);
  //   });
  // }

  Future<bool> sendCommand(String command) async {
    if (bluetoothBase.devices[id]?.deviceLastCommandCharacteristic == null) {
      return false;
    }
    BluetoothCharacteristic? commandCharacteristicToSendTo =
        bluetoothBase.devices[id]?.deviceLastCommandCharacteristic!;

    // print(utf8.decode(currentCommandCharacteristic.lastValue));
    if (commandCharacteristicToSendTo == null) {
      return false;
    } else {
      await bluetoothBase.writeToCharacteristic(
          commandCharacteristicToSendTo, command, withoutResponse: false);
      return true;
    }
  }

  Future<void> disconnect() async {
    await statusSubscription?.cancel();
    statusSubscription = null;

    await bluetoothBase.disconnect(id);

    // await connectionStatusSubscription?.cancel();
    // await connectionStatusSubscription?.cancel();
    // connectionStatusSubscription = null;
    print("Connection Status Sub Cancelled");
    // bluetoothBase.devices[id]?.deviceFound
    //     .removeListener(_onDeviceFoundHandler);
  }
}
