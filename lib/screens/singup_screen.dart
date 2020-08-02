import 'dart:convert';
import 'dart:ffi';
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
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_otp/flutter_otp.dart';
import 'package:otp/otp.dart';

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
  String _addressText = "Enter location";
  static const String kGoogleApiKey = Utils.API_KEY;
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
  LatLng _selectedCoord;
  var finalLocation;
  var _selectedAddress;

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

  Future<String> _getLocation() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction p = await PlacesAutocomplete.show(
        context: context,
        apiKey: kGoogleApiKey,
        mode: Mode.overlay, // Mode.fullscreen
        language: "en",
        components: [new Component(Component.country, "in")]);
    await displayPrediction(p);
    return _addressText;
  }

  Future<String> displayPrediction(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);

      print("detail $detail");

      var placeId = p.placeId;
      double lat = detail.result.geometry.location.lat;
      double lng = detail.result.geometry.location.lng;

      print(p.description);
      var address = await Geocoder.local.findAddressesFromQuery(p.description);
      print(address.toString());
      this._selectedAddress = address.first;
      _addressText = _selectedAddress.addressLine;
      this._selectedCoord = LatLng(lat, lng);

      return _addressText;
    }
  }

  Future<String> _uploadData(bool isSeller) async {
    String panCardName = _panCard.path.split('/').last;
    //print(isSeller);
    FormData formData = FormData.fromMap({
      "panCard":
          await MultipartFile.fromFile(_panCard.path, filename: panCardName),
      "username": _usernameController.text,
      "address": _selectedAddress.addressLine,
      "contact_number": _contactNumberController.text,
      "isSeller": isSeller,
      "state": _selectedAddress.adminArea,
      "pincode": _selectedAddress.postalCode,
      "city": _selectedAddress.subAdminArea,
      "latitude": _selectedCoord.latitude,
      "longitude": _selectedCoord.longitude,
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

  Future<void> _clickHandler() async {
    var address = await _getLocation();
    setState(() {
      _addressText = address;
    });
  }

  Future<void> showOtpDialog(bool isSeller) async {
    // var code = OTP.generateTOTPCodeString(
    //     'JBSWY3DPEHPK3PXP', DateTime.now().millisecondsSinceEpoch);
    // print(code);
    FlutterOtp otp = FlutterOtp();
    otp.sendOtp(_contactNumberController.text);

    String enteredOtp;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          title: Text("Otp is sent to ${_contactNumberController.text}"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      enteredOtp = val;
                    })
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("Verify"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0)),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                if (otp.resultChecker(int.parse(enteredOtp))) {
                  Navigator.pop(context);
                  _submitData(isSeller);
                } else {
                  print("failed");
                  Navigator.pop(context);
                  showMyDialog(context, "OTP Verification failed",
                      "OTP verification failed please retry.", "OK");
                }
              },
            ),
          ],
        );
      },
    );
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
        // /Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed(ProdReqAdd.routeName);
      } else {
        String text = "Sorry!!!";
        String dialogMesage = "Singup insertion failed.";
        String buttonMessage = "Ok!!";

        showMyDialog(context, text, dialogMesage, buttonMessage);
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
          AppLocalizations.of(context).translate('app_title'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
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
                          width: data.size.width * 0.9,
                        ),
                        TextInputCard(
                          icon: Icons.phone,
                          titype: TextInputType.phone,
                          htext: 'Contact Number',
                          mdata: data,
                          controller: _contactNumberController,
                          width: data.size.width * 0.9,
                        ),

                        GestureDetector(
                          onTap: _clickHandler,
                          child: Wrap(
                            children: <Widget>[
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32.0)),
                                child: Container(
                                  width: data.size.width * 0.9,
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          Icons.location_on,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        Expanded(
                                          child: Text(
                                            _addressText,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontSize: 17.0,
                                            ),
                                            textAlign: TextAlign.center,
                                            //overflow: TextOverflow.clip,
                                            //maxLines: 5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: 10.0,
                        ),
                        // Container(
                        //   width: data.size.width * 0.9,
                        //   //height: data.size.height * 0.1,
                        //   child: Card(
                        //     shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(32.0)),
                        //     child: FlatButton.icon(
                        //       icon: Icon(Icons.location_on),
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(32.0),
                        //       ),
                        //       color: Colors.white,
                        //       textColor: Theme.of(context).primaryColor,
                        //       padding: EdgeInsets.all(8.0),
                        //       onPressed: _clickHandler,
                        //       label: Text(
                        //         _addressText,
                        //         textAlign: TextAlign.justify,
                        //         overflow: TextOverflow.ellipsis,
                        //         style: TextStyle(
                        //           fontSize: 14.0,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        // SizedBox(
                        //   height: 10.0,
                        // ),
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
                              showOtpDialog(snapshot.data);
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
