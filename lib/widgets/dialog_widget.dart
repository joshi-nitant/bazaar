import 'package:flutter/material.dart';

Future<void> showMyDialog(BuildContext context, String title, String message,
    String buttonMessage) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyText1.apply(
                color: Theme.of(context).primaryColor,
              ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                message,
                style: Theme.of(context).textTheme.bodyText2,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              height: 50,
              width: 100,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0)),
                child: FlatButton(
                  child: Text(buttonMessage,
                      style: Theme.of(context).textTheme.bodyText2.apply(
                            color: Colors.white,
                          )),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
