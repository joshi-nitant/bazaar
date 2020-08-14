import 'package:baazar/widgets/footer_widget.dart';
import 'package:flutter/material.dart';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/language.dart';
import 'package:baazar/screens/root_app.dart';
import 'package:baazar/widgets/choose_language_widget.dart';
import 'package:flutter/services.dart';

class ChooseLanguageScreen extends StatefulWidget {
  @override
  _ChooseLanguageScreenState createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends State<ChooseLanguageScreen> {
  var appBar;
  void _changeLanguage(Language language) {
    Locale _locale;
    _locale = Locale(language.code, language.dialect);
    MyApp.setLocale(context, _locale);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);

    appBar = AppBar(
      title: Text(AppLocalizations.of(context).translate('app_title'),
          style: Theme.of(context).textTheme.headline1.apply(
                color: Colors.white,
              )),
      iconTheme: IconThemeData(color: Colors.white),
    );
    var height = (MediaQuery.of(context).size.height -
        appBar.preferredSize.height -
        MediaQuery.of(context).padding.top);
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: this.appBar,
      body: Container(
          width: width,
          height: height,
          child: ChooseLanguageWidget(changeLangHandler: _changeLanguage)),
      bottomSheet: FooterWidget(),
    );
  }
}
