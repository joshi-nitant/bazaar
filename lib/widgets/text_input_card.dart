import 'package:flutter/material.dart';

class TextInputCard extends StatefulWidget {
  IconData icon;
  TextInputType titype;
  String htext;
  MediaQueryData mdata;
  TextEditingController controller;
  TextInputCard(
      {this.icon, this.titype, this.htext, this.mdata, this.controller});
  @override
  _TextInputCardState createState() => _TextInputCardState();
}

class _TextInputCardState extends State<TextInputCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      borderOnForeground: false,
      child: Container(
        width: widget.mdata.size.width * 0.3,
        child: ListTile(
          title: TextFormField(
            controller: widget.controller,
            keyboardType: widget.titype,
            decoration: InputDecoration(
              hintText: widget.htext,
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
