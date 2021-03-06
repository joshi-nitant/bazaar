import 'package:baazar/classes/images_path.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/widgets/footer_widget.dart';
import 'package:flutter/material.dart';

import 'package:baazar/classes/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckUserScreen extends StatelessWidget {
  static const String USER_TYPE_SHARED_PREFERENCE = "isSeller";

  void _saveToPreference(var data) async {
    SharedPreferences sharedPreference = await SharedPreferences.getInstance();
    sharedPreference.setBool(USER_TYPE_SHARED_PREFERENCE, data == "seller");
  }

  void loadCategory(BuildContext context, String userType) {
    _saveToPreference(userType);

    Navigator.of(context).pushNamed(CategoryScreen.routeName, arguments: {
      'userType': userType,
    });
  }

  @override
  Widget build(BuildContext context) {
    //SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    var height = (MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('app_title'),
            style: Theme.of(context).textTheme.headline1.apply(
                  color: Colors.white,
                )),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(top: height * 0.05),
                child: Align(
                  alignment: FractionalOffset.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 5, horizontal: 40),
                          child: Text(
                              AppLocalizations.of(context).translate("who_r_u"),
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  .apply(
                                    color: Colors.white,
                                    fontSizeFactor:
                                        MediaQuery.of(context).textScaleFactor,
                                    fontSizeDelta: 4,
                                    fontWeightDelta: 1,
                                  )),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(30.0)),
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Padding(padding: EdgeInsets.only(top: 20)),
                      Wrap(
                        direction: Axis.horizontal,
                        spacing: 20,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              loadCategory(context, 'seller');
                            },
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Card(
                                    child: CircleAvatar(
                                      backgroundImage:
                                          AssetImage(ImagePath.seller),
                                      radius: 55,
                                      backgroundColor: Colors.grey[300],
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(55),
                                    ),
                                    shadowColor: Colors.grey[300],
                                    elevation: 5.0,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate("seller"),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1
                                      .apply(
                                        color: Theme.of(context).primaryColor,
                                        fontSizeFactor: MediaQuery.of(context)
                                            .textScaleFactor,
                                        fontSizeDelta: 4,
                                      ),
                                )
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              loadCategory(context, 'buyer');
                            },
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Card(
                                    child: CircleAvatar(
                                      backgroundImage:
                                          AssetImage(ImagePath.buyer),
                                      radius: 55,
                                      backgroundColor: Colors.grey[300],
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(55),
                                    ),
                                    shadowColor: Colors.grey[300],
                                    elevation: 5.0,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate("buyer"),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1
                                      .apply(
                                        color: Theme.of(context).primaryColor,
                                        fontSizeFactor: MediaQuery.of(context)
                                            .textScaleFactor,
                                        fontSizeDelta: 4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: FooterWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
