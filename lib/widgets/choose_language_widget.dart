import 'package:baazar/classes/images_path.dart';
import 'package:baazar/widgets/footer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../classes/language.dart';

class ChooseLanguageWidget extends StatelessWidget {
  Function changeLangHandler;
  static final String routeName = "/language";

  final List<Language> languageList = [
    Language(
      name: "ગુજરતી",
      code: "gu",
      dialect: "IN",
      path: ImagePath.gujaratiLang,
    ),
    Language(
        name: "ENGLISH",
        code: "en",
        dialect: "US",
        path: ImagePath.englishLang),
    Language(
      name: "हिन्दी",
      code: "hi",
      dialect: "IN",
      path: ImagePath.hindiLang,
    ),
  ];

  ChooseLanguageWidget({@required this.changeLangHandler});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: languageList.map((lang) {
                return GestureDetector(
                  onTap: () {
                    changeLangHandler(lang);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        height: 100,
                        child: Image.asset(
                          lang.path,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        child: Text(
                          lang.name,
                          style: lang.name == "ENGLISH"
                              ? Theme.of(context).textTheme.bodyText1.apply(
                                    fontSizeFactor:
                                        MediaQuery.of(context).textScaleFactor,
                                    color: Theme.of(context).primaryColor,
                                    fontWeightDelta: 2,
                                    fontSizeDelta: -1,
                                  )
                              : Theme.of(context).textTheme.bodyText1.apply(
                                    fontSizeFactor:
                                        MediaQuery.of(context).textScaleFactor,
                                    color: Theme.of(context).primaryColor,
                                    fontWeightDelta: -2,
                                  ),
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Container(
          //   child: FooterWidget(),
          // ),
        ],
      ),
    );
  }
}
