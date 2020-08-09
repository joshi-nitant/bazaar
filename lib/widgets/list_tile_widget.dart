import 'package:baazar/classes/app_localizations.dart';
import 'package:flutter/material.dart';

class ListTileWidget extends StatelessWidget {
  IconData iconData;
  String text;
  Function controller;

  ListTileWidget(this.iconData, this.text, this.controller);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      color: Theme.of(context).primaryColor,
      child: Container(
          height: 55,
          width: 150,
          child: ListTile(
            onTap: controller,
            leading: Icon(
              iconData,
              color: Colors.white,
            ),
            title: Text(
              AppLocalizations.of(context).translate(text),
              style: Theme.of(context).textTheme.bodyText2.apply(
                    color: Colors.white,
                  ),
            ),
          )),
    );
  }
}
