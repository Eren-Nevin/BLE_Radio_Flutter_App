import 'dart:async';

import 'package:flutter/material.dart';
import 'package:garage_ble/bluetooth_com.dart';

import 'package:garage_ble/viewmodel.dart';
import 'package:garage_ble/remote_widget.dart';
import 'package:garage_ble/drawer.dart';

// import 'package:flutter_icons/flutter_icons.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'IoT Demo',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
        ),
        home: Directionality(
          child: const MyHomePage(title: 'درب پارکینگ'),
          textDirection: TextDirection.rtl,
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  _MyHomePageState() {
    var _viewModel = ViewModel.instance;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // _viewModel.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 24),
            const Spacer(),
            RemoteRow(),
            const Spacer(),
            Container(
                decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10)))),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ButtonRow(),
                )),
          ],
        ),
      ),
    );
  }
}

class ButtonRow extends StatelessWidget {
  const ButtonRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: [
          BeautifulButton(() {
            // ViewModel.instance.listenOnStatusCharacteristic();
            // ViewModel.instance
            //     .getGarageOpenerOperationStatusStream()
            //     .last
            //     .then((value) {
            //   print(value);
            // });
            // ViewModel.instance.sendGarageRemoteButtonCodeToGarageOpener(22);
            // viewModel.sendCommand('Send');
          }, 'ریموت جدید', Icons.add_outlined),
          BeautifulButton(() {
            // print("Remote Management!");
            // ViewModel.instance.findGarageOpener().then((value) {
            //   if (value) {
            //     ViewModel.instance.connectToGarageOpener().then((value) {
            //       print("Connected To Remote");
            //       print(ViewModel.instance.listenOnStatusCharacteristic());
            //     });
            //   }
            // });
            // // viewModel.sendCommand('Learn');
          }, 'مدیریت ریموت ها', Icons.speaker_phone_outlined),
        ],
      ),
    );
  }
}

// class ConnectionButton extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() {
//     return ConnectionButtonState();
//   }
// }

// class ConnectionButtonState extends State<ConnectionButton> {
//   String label = "";

//   ConnectionButtonState() {
//     if (ViewModel.instance.isGarageOpenerConnected) {
//       setState(() {
//         label = "Disconnect";
//       });
//     } else {
//       setState(() {
//         label = "Connect";
//       });
//     }
//     // ViewModel.instance.getGarageOpenerConnectionStatusStream().listen((event) {
//     //   if (event == GarageConnectionState.)

//     // });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BeautifulButton(
//       () {
//       if (ViewModel.instance.isGarageOpenerConnected) {
//         ViewModel.instance.disconnectFromGarageOpener();
//       } else {
//         ViewModel.instance.connectToGarageOpener();
//       }
//     }
//     , label, Icons.connect_without_contact);
//   }
// }

class BeautifulButton extends StatelessWidget {
  final VoidCallback pressedCallaback;
  final String label;
  final IconData iconData;

  const BeautifulButton(this.pressedCallaback, this.label, this.iconData,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Center(
        child: SizedBox(
          height: 90,
          width: 140,
          child: ElevatedButton(
            onPressed: pressedCallaback,
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              elevation: MaterialStateProperty.all(0),
              foregroundColor: MaterialStateProperty.all(Colors.white),
              // padding: MaterialStateProperty.all(const EdgeInsets.all(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  iconData,
                  size: 42,
                ),
                // const SizedBox(height: 10),
                Text(
                  label,
                  textScaleFactor: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
