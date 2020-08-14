import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/images_path.dart';
import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            ImagePath.logo,
            height: 45,
            width: 45,
          ),
        ),
        Text(AppLocalizations.of(context).translate('app_title'),
            style: Theme.of(context).textTheme.headline1.apply(
                  color: Theme.of(context).primaryColor,
                ))
      ],
    );
  }
}
