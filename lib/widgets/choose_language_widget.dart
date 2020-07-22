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
        name: "English",
        code: "en",
        dialect: "US",
        path: ImagePath.englishLang),
    Language(
      name: "हिन्दी",
      code: "hi",
      dialect: "IN",
      path: ImagePath.hindiLang,
    ),
    Language(
      name: "ગુજરતી",
      code: "gu",
      dialect: "IN",
      path: ImagePath.gujaratiLang,
    ),
  ];

  ChooseLanguageWidget({@required this.changeLangHandler});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          flex: 1,
          fit: FlexFit.tight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        Flexible(
          flex: 0,
          fit: FlexFit.tight,
          child: FooterWidget(),
        ),
      ],
    );
  }
}
