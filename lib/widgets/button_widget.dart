import 'package:flutter/material.dart';

class ButtonWidget extends StatefulWidget {
  Function handlerMethod;
  IconData iconData;
  String text;
  int width = -1;
  int height = -1;
  bool isError = false;
  ButtonWidget(
      {this.iconData,
      this.text,
      this.handlerMethod,
      this.width,
      this.height,
      this.isError});
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
        width: widget.width == -1 ? 170 : widget.width.toDouble(),
        child: FlatButton.icon(
          icon: Icon(
            widget.iconData,
            color: Theme.of(context).primaryColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0),
          ),
          color: Colors.white,

          //textColor: widget.isError ? Colors.red : Colors.black,
          padding: EdgeInsets.all(8.0),
          onPressed: widget.handlerMethod,
          label: FittedBox(
            child: Text(
              widget.text,

              //overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.bodyText2.apply(
                    color: widget.isError
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                    fontSizeDelta: -2,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
