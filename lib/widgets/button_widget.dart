import 'package:flutter/material.dart';

class ButtonWidget extends StatefulWidget {
  Function handlerMethod;
  IconData iconData;
  String text;
  int width = -1;
  int height = -1;
  ButtonWidget(
      {this.iconData, this.text, this.handlerMethod, this.width, this.height});
  @override
  _ButtonWidgetState createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      child: Container(
        height: widget.height == -1 ? 55 : widget.height.toDouble(),
        width: widget.width == -1 ? 150 : widget.width.toDouble(),
        child: FlatButton.icon(
          icon: Icon(widget.iconData),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0),
          ),
          color: Colors.white,
          textColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.all(8.0),
          onPressed: widget.handlerMethod,
          label: Text(
            widget.text,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }
}
