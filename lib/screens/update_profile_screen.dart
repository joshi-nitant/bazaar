import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/dashboard_screen.dart';
import 'package:baazar/screens/google_maps_screen.dart';
import 'package:baazar/screens/image_detail_screen.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_otp/flutter_otp.dart';
import 'package:otp/otp.dart';
import 'package:http/http.dart' as http;

class UpdateProfileScreen extends StatefulWidget {
  static final String routeName = "/updateProfile";
  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
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
  File _image;
  bool isPanCardChanged = false;
  List<String> allowedExtension = ['gif', 'png', 'jpg', 'jpeg'];
  bool isInitialLoad = true;
  User user;
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
    print("username ");
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
    print("address");
    if (_selectedAddress == null) {
      errorAddress = "Address is required";
      return false;
    }
    errorAddress = null;
    return true;
  }

  bool _validatePanCard() {
    print("panCard");
    if (_image == null && isPanCardChanged) {
      errorPanCard = "PanCard is required";
      return false;
    }
    errorPanCard = null;
    return true;
  }

  bool _validateContactNumber() {
    print("contact");
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

  Future getImage() async {
    File file = await FilePicker.getFile();
    String exten = file.path.split('.').last.toLowerCase();
    print(exten);

    if (file != null) {
      setState(() {
        if (allowedExtension.contains(exten)) {
          _image = file;
          isPanCardChanged = true;
        } else {
          isPanCardChanged = false;
        }
      });
    }
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

  Future<String> _uploadData(User user) async {
    print('uploading');
    String panCardName = "";
    if (isPanCardChanged) {
      panCardName = _image.path.split('/').last;
    }
    //print(isSeller);
    FormData formData = FormData.fromMap({
      "panCard": isPanCardChanged
          ? await MultipartFile.fromFile(_image.path, filename: panCardName)
          : user.panCard,
      "panCardStatus": isPanCardChanged ? "0" : user.panCardStatus,
      "username": _usernameController.text.trim(),
      "address": _selectedAddress.addressLine.toString().trim(),
      "contact_number": _contactNumberController.text.trim(),
      "state": _selectedAddress.adminArea,
      "pincode": _selectedAddress.postalCode,
      "city": _selectedAddress.subAdminArea,
      "latitude": _selectedCoord.latitude,
      "longitude": _selectedCoord.longitude,
      "id": user.id,
      "isPanChanged": isPanCardChanged,
    });
    try {
      var dio = Dio();
      Response response =
          await dio.post(Utils.URL + "/updateUser.php", data: formData);
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
    // setState(() {
    //   this._isOtpRight = true;
    // });
  }

  Future<bool> showOtpDialog() async {
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
                borderRadius: BorderRadius.circular(Utils.BORDER_RADIUS)),
            title: Text(
              "Otp is sent to ${_contactNumberController.text}",
              style: Theme.of(context).textTheme.bodyText1.apply(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: .0, horizontal: 20.0),
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

  void _submitData(User user) async {
    print('submiting');
    if (_validator()) {
      await showOtpDialog();
      if (this._isOtpRight) {
        final ProgressDialog pr = ProgressDialog(context,
            type: ProgressDialogType.Normal,
            isDismissible: true,
            showLogs: true);
        pr.style(
          message: 'Updating Up Please Wait...',
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
        String jsonString = await _uploadData(user);
        var jsonData = json.decode(jsonString);
        pr.hide();
        int response_code = jsonData["response_code"];
        print(response_code);
        if (response_code == 101) {
          String text = "Congratulations!!!";
          String dialogMesage = "Update successfull.";
          String buttonMessage = "Ok!!";
          await CustomDialog.openDialog(
              context: context,
              title: text,
              message: dialogMesage,
              mainIcon: Icons.check,
              subIcon: HandShakeIcon.handshake);
          print("here");
          // Navigator.of(context).pop();
          // Navigator.of(context).pushReplacementNamed(ProdReqAdd.routeName);
        } else {
          String text = "Sorry!!!";
          String dialogMesage = "Update failed.";
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

  Future<int> _getUserId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE);
  }

  Future<User> _getUserData() async {
    if (isInitialLoad == true) {
      int id = await _getUserId();
      if (id != null) {
        var response = await http.post(
          Utils.URL + "getUserDataForUpdate.php",
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(
            <String, int>{
              'id': id,
            },
          ),
        );
        print(response.body);
        var jsondata = json.decode(response.body);
        print(jsondata);
        var userMap = jsondata[0];
        user = User(
          id: userMap['user_id'],
          latitude: userMap['latitude'],
          longitude: userMap['longitude'],
          address: userMap['address'],
          state: userMap['state'],
          city: userMap['city'],
          contactNumber: userMap['contact'],
          name: userMap['name'],
          panCardStatus: userMap['pan_card_status'],
          panCard: userMap['pan_card'],
          isSeller: userMap['is_seller'],
        );
        _usernameController.text = user.name;
        _contactNumberController.text = user.contactNumber;
        _addressText = user.address;
        var address = await Geocoder.local.findAddressesFromQuery(_addressText);
        _selectedAddress = address.first;

        _selectedCoord = new LatLng(
            double.parse(user.latitude), double.parse(user.longitude));

        print(user.panCard);
        isInitialLoad = false;
      }
    }
    return user;
  }

  ///0 means pending
  ///1 means approved
  ///2 means rejected
  String _getPanCardStatus(User user) {
    if (user.panCardStatus == "0" || isPanCardChanged) {
      return AppLocalizations.of(context).translate("Pan Card Pending");
    } else if (user.panCardStatus == "1") {
      return AppLocalizations.of(context).translate("Pan Card Accepted");
    } else if (user.panCardStatus == "2") {
      return AppLocalizations.of(context).translate("Pan Card Rejected");
    }
  }

  ///0 means pending
  ///1 means approved
  ///2 means rejected
  Color _getPanCardColor(User user) {
    if (user.panCardStatus == "0" || isPanCardChanged) {
      return Colors.orange;
    } else if (user.panCardStatus == "1") {
      return Colors.green;
    } else if (user.panCardStatus == "2") {
      return Colors.red;
    }
  }

  Widget getLocalImage(User user) {
    print(_image);
    return DetailScreen(
      tag: "panCard",
      url: Utils.URL + "panCard/" + user.panCard,
      isNetworkImage: false,
      imageFile: _image,
    );
  }

  var appBar;
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      titleSpacing: 0,
      title: Row(
        children: <Widget>[
          Icon(Icons.person),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              AppLocalizations.of(context).translate('Update Profile'),
              style: Theme.of(context).textTheme.headline1.apply(
                    color: Colors.white,
                    letterSpacingDelta: -2,
                  ),
            ),
          ),
        ],
      ),
      iconTheme: IconThemeData(color: Colors.white),
    );
    var height = (MediaQuery.of(context).size.height -
        appBar.preferredSize.height -
        MediaQuery.of(context).padding.top);
    var width = MediaQuery.of(context).size.width;
    final data = MediaQuery.of(context);
    return Scaffold(
      appBar: appBar,
      body: FutureBuilder(
        future: _getUserData(),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 15, 12, 7),
              child: SingleChildScrollView(
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      CircleAvatar(
                        backgroundImage: AssetImage('assests/images/logo.png'),
                        radius: 45.0,
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextInputCard(
                          icon: Icons.person,
                          titype: TextInputType.text,
                          htext: 'Name',
                          mdata: data,
                          controller: _usernameController,
                          width: data.size.width * 0.9,
                          errorText: errorUsername,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextInputCard(
                          icon: Icons.phone,
                          titype: TextInputType.phone,
                          htext: 'Contact Number',
                          mdata: data,
                          controller: _contactNumberController,
                          width: data.size.width * 0.9,
                          errorText: errorContactNumber,
                        ),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                      Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ButtonWidget(
                                  iconData: Icons.insert_drive_file,
                                  text: AppLocalizations.of(context)
                                      .translate('Pan Card'),
                                  handlerMethod: getImage,
                                  height: 55,
                                  width: 150,
                                  isError: false,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) {
                                      return isPanCardChanged
                                          ? getLocalImage(snapshot.data)
                                          : DetailScreen(
                                              tag: "panCard",
                                              url: Utils.URL +
                                                  "panCard/" +
                                                  snapshot.data.panCard,
                                              isNetworkImage: true,
                                            );
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                width: width * 0.30,
                                child: FittedBox(
                                  child: CircleAvatar(
                                    backgroundImage: _image == null
                                        ? NetworkImage(
                                            "${Utils.URL}panCard/${snapshot.data.panCard}")
                                        : FileImage(File(_image.path)),
                                    backgroundColor: Colors.white,
                                    radius: 35.0,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 12.0,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _getPanCardStatus(snapshot.data),
                          style: TextStyle(
                            color: _getPanCardColor(snapshot.data),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
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
                            AppLocalizations.of(context).translate("Update"),
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
          );
        },
      ),
    );
  }
}
