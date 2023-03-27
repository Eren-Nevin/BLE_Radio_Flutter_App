import 'dart:async';

import 'package:garage_ble/bluetooth.dart';
import 'package:garage_ble/bluetooth_com.dart';

GarageOpenerIdentifier sampleGarageFindFilter = (device) {
  return device.name.startsWith('My Garage');
};

class ViewModel {
  // late GarageOpener myGarageOpener;
  int numberOfConnectedRemotes = 0;

  Map<int, GarageRemote> garageRemotes = {};

  static ViewModel _instance = ViewModel();
  static ViewModel get instance => _instance;

  ViewModel() {
    // TEST REMOTES
    garageRemotes = {
      100: createGarageRemote(100, "خانه", sampleGarageFindFilter,
          codeA: 31234, codeB: 2350658, codeC: 551231, codeD: 55123),
      101: createGarageRemote(101, "دفتر", sampleGarageFindFilter,
          codeA: 31534, codeB: 65123, codeC: 11256, codeD: 77431),
    };

    // myGarageOpener = GarageOpener(100, 'My Garage');

    print("View Model Initialized");
  }

  GarageOpener? getGarageRemoteOpener(int garageRemoteId) {
    return garageRemotes[garageRemoteId]?.garageOpener;
  }

  bool isGarageRemoteConnected(int garageRemoteId) {
    GarageOpener? garageOpener = getGarageRemoteOpener(garageRemoteId);
    if (garageOpener != null) {
      return garageOpener.isConnected;
    }
    // It can be false if the garage remote is not defined.
    return false;
  }

  Stream<GarageOpenerConnectionState>? getGarageOpenerConnectionStateStream(
      int garageRemoteId) {
    return garageRemotes[garageRemoteId]?.garageOpener.connectionStatus;
  }

  Stream<String>? getGarageOpenerStatusStream(int garageRemoteId) {
    return garageRemotes[garageRemoteId]?.garageOpener.status;
  }

  void sendGarageRemoteButtonCodeToGarageOpener(
      int garageRemoteId, int code) async {
    await garageRemotes[garageRemoteId]?.garageOpener.sendCommand("Send $code");
  }

  void sendLearnCommandToGarageOpener(int garageRemoteId) async {
    await garageRemotes[garageRemoteId]?.garageOpener.sendCommand("Learn");
  }

  Future<bool> findAndConnectToGarageOpener(int garageRemoteId) async {
    if (await findGarageOpener(garageRemoteId)) {
      return await connectToGarageOpener(garageRemoteId);
    }
    return false;
  }

  Future<bool> findGarageOpener(int garageRemoteId) async {
    GarageOpener? garageOpener = garageRemotes[garageRemoteId]?.garageOpener;
    if (garageOpener != null) {
      if (numberOfConnectedRemotes == 0) {
        return await garageOpener.startFindingGarage();
      } else {
        print("A connection is established already!");
      }
    }
    return false;
  }

  Future<bool> connectToGarageOpener(int garageRemoteId) async {
    GarageOpener? garageOpener = garageRemotes[garageRemoteId]?.garageOpener;
    if (garageOpener != null) {
      if (await garageOpener.connectToGarage()) {
        numberOfConnectedRemotes++;
        return true;
      }
    }
    return false;
  }

  bool listenOnStatusCharacteristic(int garageRemoteId) {
    GarageOpener? garageOpener = garageRemotes[garageRemoteId]?.garageOpener;
    if (garageOpener != null) {
      return garageOpener.listenOnStatusCharacteristic();
    }
    return false;
  }

  void addStatus(int garageRemoteId, String status) {
    garageRemotes[garageRemoteId]?.garageOpener.addStatus(status);
  }

  void changeButtonCode(
      int garageRemoteId, GarageRemoteButtonPlace place, int code) {
    garageRemotes[garageRemoteId]?.buttons[place]?.code = code;
  }

  Future<void> disconnectFromGarageOpener(int garageRemoteId) async {
    await garageRemotes[garageRemoteId]?.garageOpener.disconnect();
    numberOfConnectedRemotes--;
  }

  GarageRemote createGarageRemote(
      int id, String label, GarageOpenerIdentifier identifier,
      {int codeA = 0, int codeB = 0, int codeC = 0, int codeD = 0}) {
    GarageRemote remote = GarageRemote(id, label, identifier);
    remote.label = label;
    remote.buttons = {
      GarageRemoteButtonPlace.A: GarageRemoteButton(code: codeA),
      GarageRemoteButtonPlace.B: GarageRemoteButton(code: codeB),
      GarageRemoteButtonPlace.C: GarageRemoteButton(code: codeC),
      GarageRemoteButtonPlace.D: GarageRemoteButton(code: codeD),
    };

    return remote;
  }
}

class GarageRemote {
  int id = 0;
  String label = "";
  late GarageOpener garageOpener;
  // TODO: Icon?
  Map<GarageRemoteButtonPlace, GarageRemoteButton> buttons = {};

  // bool isGarageOpenerConnected = false;

  GarageRemote(this.id, this.label, GarageOpenerIdentifier identifier) {
    garageOpener = GarageOpener(id, label, identifier);
    //   garageOpener.connectionStatus.listen((status) {
    //     if (status == GarageConnectionState.connected) {
    //       isGarageOpenerConnected = true;
    //     } else if (status == GarageConnectionState.disconnected) {
    //       isGarageOpenerConnected = false;
    //     }
    //   });
    // }
  }
}

class GarageRemoteButton {
  int code = 0;
  GarageRemoteButton({this.code = 0});
}

enum GarageRemoteButtonPlace { A, B, C, D }
