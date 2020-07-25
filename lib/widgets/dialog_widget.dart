import 'package:flutter/material.dart';

class DialogWidget extends StatefulWidget {
  String title;
  String dialogMessage;
  String buttonTitle;

  DialogWidget({this.title, this.dialogMessage, this.buttonTitle});

  @override
  _DialogWidgetState createState() => _DialogWidgetState();
}

class _DialogWidgetState extends State<DialogWidget> {
  _showDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          title: Text(widget.title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(widget.dialogMessage),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(widget.buttonTitle),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0)),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showDialog();
  }
}
