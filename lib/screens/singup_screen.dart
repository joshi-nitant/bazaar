import 'dart:convert';
import 'dart:io';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/google_maps_screen.dart';
import 'package:baazar/screens/prod_req_add_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:baazar/widgets/button_widget.dart';
import 'package:baazar/widgets/dialog_widget.dart';
import 'package:baazar/widgets/text_input_card.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingUpScreen extends StatefulWidget {
  static final String routeName = "/singup";
  @override
  _SingUpScreenState createState() => _SingUpScreenState();
}

class _SingUpScreenState extends State<SingUpScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  File _aadharCard;
  File _panCard;

  Future<bool> _checkUserType() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences
        .getBool(CheckUserScreen.USER_TYPE_SHARED_PREFERENCE);
  }

  void pickAadharCard() async {
    File file = await FilePicker.getFile();
    setState(() {
      this._aadharCard = file;
    });
  }

  void pickPanCard() async {
    File file = await FilePicker.getFile();
    setState(() {
      this._panCard = file;
    });
  }

  Future<String> _uploadData(bool isSeller) async {
    String panCardName = _panCard.path.split('/').last;
    print(isSeller);
    FormData formData = FormData.fromMap({
      "panCard":
          await MultipartFile.fromFile(_panCard.path, filename: panCardName),
      "username": _usernameController.text,
      "address": _addressController.text,
      "contact_number": _contactNumberController.text,
      "isSeller": isSeller
    });
    try {
      var dio = Dio();
      Response response =
          await dio.post(Utils.URL + "/insertUser.php", data: formData);
      print(response);
      return response.data;
    } on Exception catch (e) {
      return "Error";
    }
  }

  void _submitData(bool isSeller) async {
    if (_panCard != null &&
        _usernameController != null &&
        _contactNumberController != null &&
        _addressController != null &&
        _panCard != null) {
      String jsonString = await _uploadData(isSeller);
      var jsonData = json.decode(jsonString);
      int userId = jsonData["user_id"];

      if (userId != -1) {
        _storeUserId(userId);
        Navigator.of(context).pushReplacementNamed(ProdReqAdd.routeName);
      } else {
        String text = "Sorry!!!";
        String dialogMesage = "Singup insertion failed.";
        String buttonMessage = "Ok!!";

        DialogWidget(
          title: text,
          dialogMessage: dialogMesage,
          buttonTitle: buttonMessage,
        );
      }
    }
  }

  void _storeUserId(int userId) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setInt(User.USER_ID_SHARED_PREFERNCE, userId);
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate("app_title"),
        ),
      ),
      body: FutureBuilder(
        future: _checkUserType(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Container(
            height: data.size.height,
            width: data.size.width,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                child: SingleChildScrollView(
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircleAvatar(
                          backgroundImage:
                              AssetImage('assests/images/logo.png'),
                          radius: 55.0,
                          backgroundColor: Colors.white,
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        TextInputCard(
                          icon: Icons.person,
                          titype: TextInputType.text,
                          htext: 'Name',
                          mdata: data,
                          controller: _usernameController,
                        ),
                        TextInputCard(
                          icon: Icons.phone,
                          titype: TextInputType.phone,
                          htext: 'Contact Number',
                          mdata: data,
                          controller: _contactNumberController,
                        ),
                        TextInputCard(
                          icon: Icons.location_on,
                          titype: TextInputType.multiline,
                          htext: 'Address',
                          mdata: data,
                          controller: _addressController,
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ButtonWidget(
                                iconData: Icons.insert_drive_file,
                                text: AppLocalizations.of(context)
                                    .translate('Pan Card'),
                                handlerMethod: pickPanCard,
                              ),
                            ),
                            SizedBox(
                              width: 12.0,
                            ),
                            Expanded(
                              child: Text(
                                _panCard == null
                                    ? AppLocalizations.of(context)
                                        .translate('Name of the file')
                                    : _panCard.path.split('/').last,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 40.0,
                        ),
                        Container(
                          height: 55,
                          width: 170,
                          child: FlatButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32.0),
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            color: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            padding: EdgeInsets.all(8.0),
                            onPressed: () {
                              _submitData(snapshot.data);
                            },
                            child: Text(
                              AppLocalizations.of(context).translate("Sign Up"),
                              style: TextStyle(
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                        ),
                        // SizedBox(
                        //   height: 10.0,
                        // ),
                        // Text(
                        //   'Already Registerd??',
                        //   style: TextStyle(
                        //     fontSize: 19.0,
                        //     color: primarycolor,
                        //     fontWeight: FontWeight.w700,
                        //   ),
                        // ),
                        // SizedBox(
                        //   height: 10.0,
                        // ),
                        // InkWell(
                        //   child: Text(
                        //     'Login',
                        //     style: TextStyle(
                        //         color: primarycolor,
                        //         fontWeight: FontWeight.w700,
                        //         fontSize: 19.0,
                        //         decoration: TextDecoration.underline),
                        //   ),
                        //   onTap: () => Navigator.push(context,
                        //       MaterialPageRoute(builder: (context) => login())),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          // return Card(
          //   elevation: 5,
          //   child: Container(
          //     height: 400,
          //     padding: EdgeInsets.all(10),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.end,
          //       children: <Widget>[
          //         TextField(
          //           decoration: InputDecoration(
          //               labelText:
          //                   AppLocalizations.of(context).translate('Name')),
          //           controller: _usernameController,
          //         ),
          //         TextField(
          //           decoration: InputDecoration(
          //               labelText:
          //                   AppLocalizations.of(context).translate('Password')),
          //           controller: _passwordController,
          //         ),
          //         TextField(
          //           decoration: InputDecoration(
          //               labelText: AppLocalizations.of(context)
          //                   .translate('Contact Number')),
          //           controller: _contactNumberController,
          //           keyboardType: TextInputType.phone,
          //         ),
          //         TextField(
          //           decoration: InputDecoration(
          //               labelText:
          //                   AppLocalizations.of(context).translate('Address')),
          //           controller: _addressController,
          //         ),
          //         Row(
          //           children: <Widget>[
          //             RaisedButton(
          //               child: Text(AppLocalizations.of(context)
          //                   .translate("Aadhar Card")),
          //               onPressed: () {
          //                 pickAadharCard();
          //               },
          //             ),
          //             RaisedButton(
          //               child: Text(
          //                   AppLocalizations.of(context).translate("Pan Card")),
          //               onPressed: () {
          //                 pickPanCard();
          //               },
          //             ),
          //             RaisedButton(
          //               child: Text(
          //                   AppLocalizations.of(context).translate("Sign Up")),
          //               onPressed: () {
          //                 _submitData(snapshot.data);
          //               },
          //             ),
          //           ],
          //         )
          //       ],
          //     ),
          //   ),
          // );
        },
      ),
    );
  }
}
