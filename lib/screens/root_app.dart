import 'package:baazar/screens/dashboard_screen.dart';
import 'package:baazar/screens/google_maps_screen.dart';
import 'package:baazar/screens/prod_req_add_screen.dart';
import 'package:baazar/screens/prod_req_detail.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/singup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../classes/app_localizations.dart';
import 'package:baazar/screens/select_language_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';

class MyApp extends StatefulWidget {
  static final String logoPath = "assests/images/logo.png";

  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState _myAppState = context.findAncestorStateOfType<_MyAppState>();
    _myAppState.setLocale(locale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale;
  bool isLangSelected = false;
  void setLocale(Locale locale) {
    setState(() {
      isLangSelected = true;
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baazar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: Color(0xFF739b21),
          accentColor: Color(0xFFc4d5a1),
          textTheme: ThemeData.light().textTheme.copyWith(
                headline6: TextStyle(
                  color: Color(0xFF739b21),
                ),
              ),
          appBarTheme: AppBarTheme(
            textTheme: ThemeData.light().textTheme.copyWith(),
          )),
      locale: _locale,
      // List all of the app's supported locales here
      supportedLocales: [
        Locale('en', 'US'),
        Locale('gu', 'IN'),
        Locale('hi', 'IN'),
      ],

      // These delegates make sure that the localization data for the proper language is loaded
      localizationsDelegates: [
        // THIS CLASS WILL BE ADDED LATER
        // A class which loads the translations from JSON files
        AppLocalizations.delegate,
        // Built-in localization of basic text for Material widgets
        GlobalMaterialLocalizations.delegate,
        // Built-in localization for text direction LTR/RTL
        GlobalWidgetsLocalizations.delegate,
      ],

      // Returns a locale which will be used by the app
      localeResolutionCallback: (locale, supportedLocales) {
        // Check if the current device locale is supported
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode &&
              supportedLocale.countryCode == locale.countryCode) {
            return supportedLocale;
          }
        }
        // If the locale of the device is not supported, use the first one
        // from the list (English, in this case).
        return supportedLocales.first;
      },

      routes: {
        CategoryScreen.routeName: (ctx) => CategoryScreen(),
        Dashboard.routeName: (ctx) => Dashboard(),
        MapSample.routeName: (ctx) => MapSample(),
        ProdReqAdd.routeName: (ctx) => ProdReqAdd(),
        SingUpScreen.routeName: (ctx) => SingUpScreen(),
        ProdReqDetail.routeName: (ctx) => ProdReqDetail(),
      },

      home: isLangSelected ? CheckUserScreen() : ChooseLanguageScreen(),
    );
  }
}
