import 'package:baazar/classes/images_path.dart';
import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(10),
          child: Wrap(
            spacing: 20,
            children: <Widget>[
              Image.asset(
                ImagePath.logo,
                height: 50,
                width: 50,
              ),
              Text(
                "BAAZAR",
                style: TextStyle(
                    color: Theme.of(context).textTheme.headline6.color,
                    fontSize: 25),
              )
            ],
          ),
        ),
      ],
    );
  }
}
