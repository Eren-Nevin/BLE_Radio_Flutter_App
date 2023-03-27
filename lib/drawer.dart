
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return 
       Drawer(
          backgroundColor: Colors.white,
          child: Column(children: [
            DrawerBanner(),
            DrawerItem("پریزها"),
            DrawerItem("روشنایی"),
            DrawerItem("سرمایش"),
          ]));
  }

}

class DrawerItem extends StatelessWidget {
  String label;
  DrawerItem(this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: Text(label),
      ),
      Divider(),
    ]));
  }
}

class DrawerBanner extends StatelessWidget {
  const DrawerBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UserAccountsDrawerHeader(
      accountName: Text("سعید فرخی"),
      accountEmail: Text("09125513319"),
    );
    // return DrawerHeader(
    //     decoration: BoxDecoration(color: Colors.blue),
    //     child: Container(
    //         alignment: Alignment.center,
    //         child: Icon(
    //           Icons.verified_user_outlined,
    //           size: 72,
    //         )));
  }
}