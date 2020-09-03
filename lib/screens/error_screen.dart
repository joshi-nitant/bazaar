import 'package:baazar/classes/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoProduct extends StatefulWidget {
  String errorText;

  NoProduct(this.errorText);
  @override
  _NoProductState createState() => _NoProductState();
}

const Color primarycolor = Color(0xFF739b21);

class _NoProductState extends State<NoProduct> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.width * 0.6,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Image.asset(
                  'assests/images/plant.png',
                  width: 120,
                  height: 120,
                ),
                FittedBox(
                  child: Text(
                    AppLocalizations.of(context).translate(widget.errorText),
                    style: Theme.of(context).textTheme.bodyText2.apply(
                          color: Theme.of(context).primaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
          elevation: 5,
          color: Colors.grey[200],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        ),
      ),
    );
  }
}
