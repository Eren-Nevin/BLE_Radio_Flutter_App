import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:garage_ble/bluetooth.dart';
import 'package:garage_ble/bluetooth_com.dart';
import 'package:garage_ble/viewmodel.dart';

// For Now
GarageRemoteButtonPlace? longPressedButton;

class RemoteRow extends StatelessWidget {
  RemoteRow({Key? key}) : super(key: key);

  final pageViewController = PageController(viewportFraction: 0.8);

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        width: 340,
        height: 500,
        // constraints: BoxConstraints.expand(height: 500),
        child: FractionallySizedBox(
            widthFactor: 1.25,
            // heightFactor: 1.25,
            child: PageView(
              controller: pageViewController,
              scrollDirection: Axis.horizontal,
              children: [
                GarageRemoteWidget(
                  100,
                  Colors.green,
                  Colors.grey,
                  Icons.home,
                  key: GlobalKey(),
                ),
                GarageRemoteWidget(
                    101, Colors.green, Colors.grey, Icons.business,
                    key: GlobalKey()),
              ],
            )));
  }
}

class GarageRemoteWidget extends StatefulWidget {
  final Color activeBackgroundColor;
  final Color deactiveBackgroundColor;
  final int id;
  // final String remoteName;
  final IconData iconData;
  const GarageRemoteWidget(this.id, this.activeBackgroundColor,
      this.deactiveBackgroundColor, this.iconData,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => GarageRemoteState(id);
}

class GarageRemoteState extends State<GarageRemoteWidget> {
  final int id;
  bool isConnected = false;
  // GarageRemote? remote;
  GarageRemoteState(this.id) {
    ViewModel.instance
        .getGarageOpenerConnectionStateStream(id)
        ?.listen((event) {
      if (event == GarageOpenerConnectionState.connected) {
        setState(() {
          isConnected = true;
        });
      } else if (event == GarageOpenerConnectionState.disconnected) {
        setState(() {
          isConnected = false;
        });
      }
    });
    // remote = ViewModel.instance.garageRemotes[widget.index];
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(20),
        child: Material(
            elevation: 2.5,
            child: Column(
              children: [
                BeautifulRemoteCard(id, widget.iconData, () {
                  if (ViewModel.instance.isGarageRemoteConnected(id)) {
                    print("Disconnecting $id");
                    ViewModel.instance.disconnectFromGarageOpener(id).then((_) {
                      print("Disconnected");
                    });
                  } else {
                    print("Connecting To $id");
                    ViewModel.instance
                        .findAndConnectToGarageOpener(id)
                        .then((value) {
                      print("Connected: $value");
                    });
                  }
                },
                    // Maybe Bug?
                    ViewModel.instance.garageRemotes[id]!.label,
                    isConnected
                        ? widget.activeBackgroundColor
                        : widget.deactiveBackgroundColor),
                BeautifulRemoteButtonCarousel(
                  [
                    BeautifulRemoteButton("A", () {
                      int? buttonCode = ViewModel.instance.garageRemotes[id]!
                          .buttons[GarageRemoteButtonPlace.A]?.code;
                      if (buttonCode != null) {
                        ViewModel.instance.listenOnStatusCharacteristic(id);
                        ViewModel.instance
                            .sendGarageRemoteButtonCodeToGarageOpener(
                                id, buttonCode);
                      }
                    }, () {
                      longPressedButton = GarageRemoteButtonPlace.A;
                      ViewModel.instance.sendLearnCommandToGarageOpener(id);
                      ViewModel.instance.addStatus(id, "Learning ...");
                    }),
                    BeautifulRemoteButton("B", () {
                      int? buttonCode = ViewModel.instance.garageRemotes[id]!
                          .buttons[GarageRemoteButtonPlace.B]?.code;
                      if (buttonCode != null) {
                        ViewModel.instance.listenOnStatusCharacteristic(id);
                        ViewModel.instance
                            .sendGarageRemoteButtonCodeToGarageOpener(
                                id, buttonCode);
                      }
                    }, () {
                      longPressedButton = GarageRemoteButtonPlace.B;
                      ViewModel.instance.sendLearnCommandToGarageOpener(id);
                      ViewModel.instance.addStatus(id, "Learning ...");
                    }),
                    BeautifulRemoteButton("C", () {
                      int? buttonCode = ViewModel.instance.garageRemotes[id]!
                          .buttons[GarageRemoteButtonPlace.C]?.code;
                      if (buttonCode != null) {
                        ViewModel.instance.listenOnStatusCharacteristic(id);
                        ViewModel.instance
                            .sendGarageRemoteButtonCodeToGarageOpener(
                                id, buttonCode);
                      }
                    }, () {
                      longPressedButton = GarageRemoteButtonPlace.C;
                      ViewModel.instance.sendLearnCommandToGarageOpener(id);
                      ViewModel.instance.addStatus(id, "Learning ...");
                    }),
                    BeautifulRemoteButton("D", () {
                      int? buttonCode = ViewModel.instance.garageRemotes[id]!
                          .buttons[GarageRemoteButtonPlace.D]?.code;
                      if (buttonCode != null) {
                        ViewModel.instance.listenOnStatusCharacteristic(id);
                        ViewModel.instance
                            .sendGarageRemoteButtonCodeToGarageOpener(
                                id, buttonCode);
                      }
                    }, () {
                      longPressedButton = GarageRemoteButtonPlace.D;
                      ViewModel.instance.sendLearnCommandToGarageOpener(id);
                      ViewModel.instance.addStatus(id, "Learning ...");
                    }),
                  ],
                )
              ],
            )));
  }
}

class BeautifulRemoteButtonCarousel extends StatelessWidget {
  final List<BeautifulRemoteButton> buttons;
  const BeautifulRemoteButtonCarousel(this.buttons, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 160,
        width: 300,
        child: Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              direction: Axis.horizontal,
              children: buttons,
            )));
  }
}

class BeautifulRemoteButton extends StatelessWidget {
  // final String label;
  final String label;
  final VoidCallback pressedCallback;
  final VoidCallback longPressCallback;
  const BeautifulRemoteButton(
      this.label, this.pressedCallback, this.longPressCallback,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 150,
        height: 80,
        child: OutlinedButton(
            onPressed: pressedCallback,
            onLongPress: longPressCallback,
            style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(side: BorderSide())),
            child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                        child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                            decoration: const ShapeDecoration(
                                shape: CircleBorder(
                                    side: BorderSide(
                                        width: 1.0,
                                        color: Colors.red,
                                        style: BorderStyle.solid)))),
                        Text(label),
                      ],
                    ))))));
  }
}

class BeautifulRemoteCard extends StatefulWidget {
  int id;
  final String label;
  final IconData iconData;
  final VoidCallback pressedCallback;
  final Color backgroundColor;
  BeautifulRemoteCard(this.id, this.iconData, this.pressedCallback, this.label,
      this.backgroundColor,
      {Key? key})
      : super(key: key);

  @override
  State<BeautifulRemoteCard> createState() {
    return BeautifulRemoteCardState(id);
  }
}

class BeautifulRemoteCardState extends State<BeautifulRemoteCard> {
  final int id;
  String remoteConnectionStatus = "";
  String remoteCommandStatus = "";
  late StreamSubscription<GarageOpenerConnectionState>?
      connectionStatusSubscription;
  late StreamSubscription<String>? statusSubscription;
  BeautifulRemoteCardState(this.id) {
    connectionStatusSubscription = ViewModel.instance
        .getGarageOpenerConnectionStateStream(id)
        ?.listen((event) {
      setState(() {
        remoteConnectionStatus = event.name;
      });
    });
    statusSubscription =
        ViewModel.instance.getGarageOpenerStatusStream(id)?.listen((event) {
      print(event);
      if (event.startsWith('Learned: ')) {
        int code = int.parse(RegExp(r'\d+').stringMatch(event)!);
        print("Code is $code");
        ViewModel.instance.changeButtonCode(id, longPressedButton!, code);
      }
      setState(() {
        remoteCommandStatus = event;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 300,
        width: 300,
        child: ElevatedButton(
          onPressed: widget.pressedCallback,
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
              const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(10))),
            ),
            // elevation: MaterialStateProperty.all(1.5),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            padding: MaterialStateProperty.all(const EdgeInsets.all(16)),
            backgroundColor: MaterialStateProperty.all(widget.backgroundColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 10),
              Icon(
                widget.iconData,
                size: 96,
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                textScaleFactor: 1.8,
              ),
              const SizedBox(height: 40),
              Text(remoteConnectionStatus, textScaleFactor: 1.2),
              const SizedBox(height: 10),
              Text(remoteCommandStatus, textScaleFactor: 1.2),
            ],
          ),
        ),
      ),
    );
  }
}
