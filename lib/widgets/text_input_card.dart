import 'package:flutter/material.dart';

class TextInputCard extends StatefulWidget {
  IconData icon;
  TextInputType titype;
  String htext;
  MediaQueryData mdata;
  TextEditingController controller;
  double width;
  String errorText;

  TextInputCard({
    this.icon,
    this.titype,
    this.htext,
    this.mdata,
    this.controller,
    @required this.width,
    this.errorText,
  });

  @override
  _TextInputCardState createState() => _TextInputCardState();
}

class _TextInputCardState extends State<TextInputCard> {
  FocusNode _focusNode = new FocusNode();
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      borderOnForeground: false,
      child: Container(
        width: this.widget.width,
        child: ListTile(
          title: TextFormField(
            //maxLines: 2,
            textInputAction: TextInputAction.next,
            focusNode: _focusNode,
            controller: widget.controller,
            keyboardType: widget.titype,

            onChanged: (text) {},
            //maxLines: 2,
            //autocorrect: true,
            decoration: InputDecoration(
              labelText: widget.htext,
              hintMaxLines: 2,
              errorText: widget.errorText,
              hintStyle: Theme.of(context).textTheme.bodyText2.apply(
                    color: Theme.of(context).primaryColor,
                  ),
              labelStyle: Theme.of(context).textTheme.bodyText2.apply(
                    color: Theme.of(context).primaryColor,
                  ),

              contentPadding: EdgeInsets.all(12),
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorMaxLines: 2,
              // errorStyle: Theme.of(context).textTheme.headline2.apply(
              //       fontSizeDelta: -5,
              //       color: Colors.red,

              //     ),
              helperMaxLines: 2,
              prefixIcon: Icon(
                widget.icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
            // style: TextStyle(
            //   color: Theme.of(context).primaryColor,
            // ),
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
        ),
      ),
    );
  }
}
