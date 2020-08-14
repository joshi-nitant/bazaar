import 'package:baazar/screens/current_transaction_screen.dart';
import 'package:baazar/screens/dashboard_screen.dart';
import 'package:baazar/screens/google_maps_screen.dart';
import 'package:baazar/screens/manage_offer_screen.dart';
import 'package:baazar/screens/payment_screen.dart';
import 'package:baazar/screens/prod_req_add_screen.dart';
import 'package:baazar/screens/prod_req_detail.dart';
import 'package:baazar/screens/prod_req_view_screen.dart';
import 'package:baazar/screens/prod_req_update_screen.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/singup_screen.dart';
import 'package:baazar/screens/transaction_histroy_scree.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:page_transition/page_transition.dart';

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
          // Color("0xff85b02b");
          //156, 205, 50
          //Color.fromRGBO(140, 185, 45, 1)
          primaryColor: Colors.lightGreen[600],
          accentColor: Color(0xff739b21),
          primaryColorLight: Color(0xffc4d5a1),
          brightness: Brightness.light,
          fontFamily: 'Adam',
          textTheme: ThemeData.light().textTheme.copyWith(
                headline1: TextStyle(
                    fontSize: 24.0,
                    letterSpacing: 7.0,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Adam'),
                bodyText1: TextStyle(
                    fontSize: 22.0,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Adam'),
                bodyText2: TextStyle(
                    fontSize: 18.0,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Adam'),
                headline2: TextStyle(
                    fontSize: 16.0,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Adam'),
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
      // onGenerateRoute: (settings) {
      //   switch (settings.name) {
      //     case '/second':
      //       return PageTransition(
      //           child: SecondPage(), type: PageTransitionType.scale);
      //       break;
      //     default:
      //       return null;
      //   }
      // },
      routes: {
        CategoryScreen.routeName: (ctx) => CategoryScreen(),
        Dashboard.routeName: (ctx) => Dashboard(),
        MapSample.routeName: (ctx) => MapSample(),
        ProdReqAdd.routeName: (ctx) => ProdReqAdd(),
        SingUpScreen.routeName: (ctx) => SingUpScreen(),
        ProdReqDetail.routeName: (ctx) => ProdReqDetail(),
        ProdReqViewScreen.routeName: (ctx) => ProdReqViewScreen(),
        ProdReqUpdate.routeName: (ctx) => ProdReqUpdate(),
        OfferViewScreen.routeName: (ctx) => OfferViewScreen(),
        PaymentScreen.routeName: (ctx) => PaymentScreen(),
        CurrentTransaction.routeName: (ctx) => CurrentTransaction(),
        TransactionHistory.routeName: (ctx) => TransactionHistory(),
      },

      home: isLangSelected ? CheckUserScreen() : ChooseLanguageScreen(),
    );
  }
}
