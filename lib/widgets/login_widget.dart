import 'package:baazar/classes/app_localizations.dart';
import 'package:flutter/material.dart';

class LoginCard extends StatefulWidget {
  IconData icon;
  TextInputType titype;
  String htext;
  MediaQueryData mdata;
  Function controller;

  LoginCard({
    this.icon,
    this.titype,
    this.htext,
    this.mdata,
    this.controller,
  });
  @override
  _LoginCardState createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      borderOnForeground: false,
      child: Container(
        width: widget.mdata.size.width * 0.9,
        child: ListTile(
          title: TextFormField(
            onTap: () {
              widget.controller(context);
            },
            keyboardType: widget.titype,
            decoration: InputDecoration(
              errorText: "This is required",
              hintText: AppLocalizations.of(context).translate(widget.htext),
              hintStyle: TextStyle(color: Theme.of(context).primaryColor),
              contentPadding: EdgeInsets.all(12),
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              prefixIcon: Icon(
                widget.icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
