import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/dashboard_screen.dart';
import 'package:baazar/screens/google_maps_screen.dart';
import 'package:baazar/screens/prod_req_add_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:baazar/widgets/button_widget.dart';
import 'package:baazar/widgets/dialog_widget.dart';
import 'package:baazar/widgets/hand_shake_icon_icons.dart';
import 'package:baazar/widgets/text_input_card.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:progress_dialog/progress_dialog.dart';
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
  String errorUsername;
  String errorContactNumber;
  String errorAddress;
  String errorPanCard;
  bool _isOtpRight;

  @override
  void didChangeDependencies() {
    errorPanCard = AppLocalizations.of(context).translate("Name of the file");
    super.didChangeDependencies();
  }

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

  bool _validator() {
    if (_validateUsername() &&
        _validateContactNumber() &&
        _validateAddress() &&
        _validatePanCard()) {
      print("here");
      return true;
    } else {
      return false;
    }
  }

  bool _validateUsername() {
    if (_usernameController == null) {
      errorUsername = "Username is required";
      return false;
    }

    if (_usernameController.text.trim().length < 3) {
      errorUsername = "Username must be more than 3 characters";
      return false;
    }
    if (_usernameController.text.trim().length > 30) {
      errorUsername = "Username must be less than 30 characters";
      return false;
    }
    errorUsername = null;
    return true;
  }

  bool _validateAddress() {
    if (_selectedAddress == null) {
      errorAddress = "Address is required";
      return false;
    }
    errorAddress = null;
    return true;
  }

  bool _validatePanCard() {
    if (_panCard == null) {
      errorPanCard = "PanCard is required";
      return false;
    }
    errorPanCard = null;
    return true;
  }

  bool _validateContactNumber() {
    if (_contactNumberController == null) {
      errorContactNumber = "Contact Number is required";
      return false;
    }

    if (_contactNumberController.text.trim().length != 10) {
      errorContactNumber = "Contact Number must be of 10 digits";
      return false;
    }

    if (_isNumeric(_contactNumberController.text.trim()) == false) {
      errorContactNumber = "Contact Number must contain only digits";
      return false;
    }
    errorContactNumber = null;
    return true;
  }

  bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  Future<String> _getLocation() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    try {
      Prediction p = await PlacesAutocomplete.show(
          context: context,
          apiKey: kGoogleApiKey,
          mode: Mode.overlay, // Mode.fullscreen
          language: "en",
          components: [new Component(Component.country, "in")]);

      final ProgressDialog pr = ProgressDialog(context,
          type: ProgressDialogType.Normal, isDismissible: true, showLogs: true);
      pr.style(
        message: 'Adding Address...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
      );
      await pr.show();

      await displayPrediction(p);
      pr.hide();
    } catch (e) {}
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
      "username": _usernameController.text.trim(),
      "address": _selectedAddress.addressLine.toString().trim(),
      "contact_number": _contactNumberController.text.trim(),
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
    FocusScope.of(context).unfocus();
    try {
      var address = await _getLocation();
      setState(() {
        errorAddress = null;
        _addressText = address;
      });
    } catch (e) {}
  }

  void checkOtp(FlutterOtp otp, String enteredOtp) {
    if (enteredOtp == "") {
      setState(() {
        this._isOtpRight = false;
      });
      return;
    }

    if (otp.resultChecker(int.tryParse(enteredOtp))) {
      setState(() {
        this._isOtpRight = true;
      });
    } else {
      setState(() {
        this._isOtpRight = false;
      });
    }
  }

  Future<bool> showOtpDialog(bool isSeller) async {
    try {
      FlutterOtp otp = FlutterOtp();
      otp.sendOtp(_contactNumberController.text);
      String enteredOtp = "";

      return showDialog<bool>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.0)),
            title: Text(
              "Otp is sent to ${_contactNumberController.text}",
              style: Theme.of(context).textTheme.bodyText1.apply(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
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
              Container(
                height: 50,
                width: 100,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  child: FlatButton(
                    child: Text("Verify",
                        style: Theme.of(context).textTheme.bodyText2.apply(
                              color: Colors.white,
                            )),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0)),
                    color: Theme.of(context).primaryColor,
                    onPressed: () async {
                      await checkOtp(otp, enteredOtp);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {}
    return false;
  }

  void _submitData(bool isSeller) async {
    if (_validator()) {
      await showOtpDialog(isSeller);
      if (this._isOtpRight) {
        final ProgressDialog pr = ProgressDialog(context,
            type: ProgressDialogType.Normal,
            isDismissible: true,
            showLogs: true);
        pr.style(
          message: 'Singing Up Please Wait...',
          borderRadius: 10.0,
          backgroundColor: Colors.white,
          progressWidget: CircularProgressIndicator(),
          elevation: 10.0,
          insetAnimCurve: Curves.easeInOut,
          progress: 0.0,
          maxProgress: 100.0,
          progressTextStyle: TextStyle(
              color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
          messageTextStyle: TextStyle(
              color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
        );
        await pr.show();
        String jsonString = await _uploadData(isSeller);
        var jsonData = json.decode(jsonString);
        pr.hide();
        int userId = jsonData["user_id"];

        if (userId != -1) {
          await _storeUserId(userId);
          String text = "Congratulations!!!";
          String dialogMesage = "Registration successfull.";
          String buttonMessage = "Ok!!";
          await CustomDialog.openDialog(
              context: context,
              title: text,
              message: dialogMesage,
              mainIcon: Icons.check,
              subIcon: HandShakeIcon.handshake);
          print("here");
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed(ProdReqAdd.routeName);
        } else {
          String text = "Sorry!!!";
          String dialogMesage = "Singup insertion failed.";
          String buttonMessage = "Ok!!";
          await CustomDialog.openDialog(
              context: context,
              title: text,
              message: dialogMesage,
              mainIcon: Icons.check,
              subIcon: Icons.error);
          //showMyDialog(context, text, dialogMesage, buttonMessage);
        }
      } else {
        String text = "Sorry!!!";
        String dialogMesage = "Otp verification failed.";
        String buttonMessage = "Ok!!";

        await CustomDialog.openDialog(
            context: context,
            title: text,
            message: dialogMesage,
            mainIcon: Icons.check,
            subIcon: Icons.error);
      }
    }
  }

  Future<void> _storeUserId(int userId) async {
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
          style: Theme.of(context).textTheme.headline1.apply(
                color: Colors.white,
                letterSpacingDelta: -5,
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
                          errorText: errorUsername,
                        ),
                        TextInputCard(
                          icon: Icons.phone,
                          titype: TextInputType.phone,
                          htext: 'Contact Number',
                          mdata: data,
                          controller: _contactNumberController,
                          width: data.size.width * 0.9,
                          errorText: errorContactNumber,
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
                                    padding: const EdgeInsets.all(22.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          Icons.location_on,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 20),
                                            child: Text(
                                              errorAddress == null
                                                  ? _addressText
                                                  : errorAddress,

                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2
                                                  .apply(
                                                    color: errorAddress == null
                                                        ? Theme.of(context)
                                                            .primaryColor
                                                        : Colors.red,
                                                  ),

                                              textAlign: TextAlign.start,
                                              //overflow: TextOverflow.clip,
                                              //maxLines: 5,
                                            ),
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
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ButtonWidget(
                                iconData: Icons.insert_drive_file,
                                text: AppLocalizations.of(context)
                                    .translate('Pan Card'),
                                handlerMethod: pickPanCard,
                                height: 55,
                                width: 150,
                                isError: errorPanCard == null,
                              ),
                            ),
                            SizedBox(
                              width: 12.0,
                            ),
                            Expanded(
                              child: Text(
                                _panCard == null
                                    ? errorPanCard
                                    : _panCard.path.split('/').last,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20.0,
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
                              setState(() {
                                FocusScope.of(context).unfocus();
                                _submitData(snapshot.data);
                              });
                            },
                            child: Text(
                              AppLocalizations.of(context).translate("Sign Up"),
                              style: TextStyle(
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                        ),
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
