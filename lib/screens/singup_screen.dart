import 'dart:convert';
import 'dart:io';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/google_maps_screen.dart';
import 'package:baazar/screens/prod_req_add_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
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
    String aadharCardName = _aadharCard.path.split('/').last;
    String panCardName = _panCard.path.split('/').last;

    FormData formData = FormData.fromMap({
      "aadharCard": await MultipartFile.fromFile(_aadharCard.path,
          filename: aadharCardName),
      "panCard":
          await MultipartFile.fromFile(_panCard.path, filename: panCardName),
      "username": _usernameController.text,
      "password": _passwordController.text,
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
        _aadharCard != null &&
        _usernameController != null &&
        _passwordController != null &&
        _contactNumberController != null &&
        _addressController != null) {
      String jsonString = await _uploadData(isSeller);
      var jsonData = json.decode(jsonString);
      int userId = jsonData["user_id"];

      if (userId != -1) {
        _storeUserId(userId);
        Navigator.of(context).pushReplacementNamed(ProdReqAdd.routeName);
      }
    }
  }

  void _storeUserId(int userId) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setInt(User.USER_ID_SHARED_PREFERNCE, userId);
  }

  @override
  Widget build(BuildContext context) {
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

          return Card(
            elevation: 5,
            child: Container(
              height: 400,
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).translate('Name')),
                    controller: _usernameController,
                  ),
                  TextField(
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).translate('Password')),
                    controller: _passwordController,
                  ),
                  TextField(
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)
                            .translate('Contact Number')),
                    controller: _contactNumberController,
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).translate('Address')),
                    controller: _addressController,
                  ),
                  Row(
                    children: <Widget>[
                      RaisedButton(
                        child: Text(AppLocalizations.of(context)
                            .translate("Aadhar Card")),
                        onPressed: () {
                          pickAadharCard();
                        },
                      ),
                      RaisedButton(
                        child: Text(
                            AppLocalizations.of(context).translate("Pan Card")),
                        onPressed: () {
                          pickPanCard();
                        },
                      ),
                      RaisedButton(
                        child: Text(
                            AppLocalizations.of(context).translate("Sign Up")),
                        onPressed: () {
                          _submitData(snapshot.data);
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
