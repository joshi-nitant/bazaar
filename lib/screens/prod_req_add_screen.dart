import 'dart:convert';
import 'dart:io';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/widgets/drop_down_widget.dart';
import 'package:baazar/widgets/hand_shake_icon_icons.dart';
import 'package:baazar/widgets/m_y_baazar_icons.dart';

import 'package:geocoder/geocoder.dart';
//import 'package:google_maps_webservice/places.dart';
//import 'package:baazar/models/user_location.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:baazar/widgets/button_widget.dart';
import 'package:baazar/widgets/dialog_widget.dart';
//import 'package:baazar/widgets/drop_down_widget.dart';
import 'package:baazar/widgets/text_input_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
//import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:search_map_place/search_map_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_maps_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:progress_dialog/progress_dialog.dart';

class ProdReqAdd extends StatefulWidget {
  static final String routeName = "/add";

  @override
  _ProdReqAddState createState() => _ProdReqAddState();
}

class _ProdReqAddState extends State<ProdReqAdd> {
  bool isSeller;
  List<Category> catgeoryList;

  var finalLocation;
  var _selectedAddress;
  final _breedController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime _selectedDate;
  File qualityCertificate;
  Category selectedCategory;
  String dropDownValue;
  int _userId;
  LatLng _selectedCoord;
  File _image;
  final picker = ImagePicker();
  String _addressText = "Enter location";
  static const String kGoogleApiKey = Utils.API_KEY;
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
  String errorBreed;
  String errorPrice;
  String errorQuantity;
  String errorCategory;
  String _photoText = "Add Photo";
  bool _isPhotoError = false;

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _photoText = "Add Photo";
        _isPhotoError = false;
      });
    }
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
    _addressText = await displayPrediction(p);
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

  void _categoryHandler(String value) {
    print(value);
    setState(() {
      this.dropDownValue = value;
      selectedCategory =
          catgeoryList.firstWhere((category) => category.name == value);
    });
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2019),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _openGoogleMaps(BuildContext context) async {
    var finalLocation = await Navigator.of(context).pushNamed(
      MapSample.routeName,
    );
    var finalAddress = await _getLocationFromCoordinate(finalLocation);
    setState(() {
      //print("Inside finalLocation");
      print(_selectedAddress);
      _selectedCoord = finalLocation;
      _selectedAddress = finalAddress.first;
    });
  }

  Future<List<Address>> _getLocationFromCoordinate(LatLng coords) async {
    final coordinates = new Coordinates(coords.latitude, coords.longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    //print("Inside address");
    //print(addresses);
    return addresses;
  }

  _getCategoryList() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String jsonString = sharedPreferences
        .getString(CategoryScreen.CATEGORY_LIST_SHARED_PREFERENCE);
    return jsonString;
  }

  _getUserId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    int _userId = sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE);
    return _userId;
  }

  _getUserType() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool isSeller =
        sharedPreferences.getBool(CheckUserScreen.USER_TYPE_SHARED_PREFERENCE);
    return isSeller;
  }

  Future<List<Category>> _loadCatAndUserType() async {
    //print("Cateory List Start");
    String jsonString = await _getCategoryList();
    // print(jsonString);
    this.isSeller = await _getUserType();
    //print(this.isSeller);
    this._userId = await _getUserId();
    var jsonData = json.decode(jsonString);
    List<Category> categoryList = [];
    for (var category in jsonData) {
      categoryList.add(
        Category(
          id: category["cat_id"],
          name: category["category_name"],
          imgPath: category["category_image"],
        ),
      );
    }
    //print("Cateory List End");
    this.catgeoryList = categoryList;
    return categoryList;
  }

  void pickFile() async {
    File file = await FilePicker.getFile();
    setState(() {
      this.qualityCertificate = file;
    });
  }

  Future<String> uploadData() async {
    String fileName;
    // if (isSeller) {
    //   qualityCertificate.path.split('/').last;
    // }
    FormData formData = FormData.fromMap(
      {
        // "qualityCertificate": isSeller
        //     ? await MultipartFile.fromFile(qualityCertificate.path,
        //         filename: fileName)
        //     : null,
        "productImage": isSeller
            ? await MultipartFile.fromFile(
                _image.path,
                filename: _image.path.split('/').last,
              )
            : null,
        "isSeller": isSeller,
        "price": num.parse(_priceController.text.trim()).toStringAsFixed(2),
        "breed": _breedController.text,
        "quantity": _quantityController.text,
        "date": _selectedDate,
        // "address": _selectedAddress.addressLine,
        // "state": _selectedAddress.adminArea,
        // "pincode": _selectedAddress.postalCode,
        // "city": _selectedAddress.subAdminArea,
        // "latitude": _selectedCoord.latitude,
        // "longitude": _selectedCoord.longitude,
        "user_id": _userId,
        "category": selectedCategory.id,
      },
    );
    try {
      var dio = Dio();
      Response response =
          await dio.post(Utils.URL + "/insertProdReq.php", data: formData);
      print(response.data);
      return response.data as String;
    } on Exception catch (e) {
      print(e);
      print("exeception");
    }
  }

  void _submitData() async {
    if (_validator() && _userId != null) {
      //For normal dialog
      final ProgressDialog pr = ProgressDialog(context,
          type: ProgressDialogType.Normal, isDismissible: true, showLogs: true);
      pr.style(
        message: 'Adding Please Wait...',
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
      String jsonResponse = await uploadData();
      var data = json.decode(jsonResponse);
      print(data);
      await pr.hide();
      if (data['response_code'] == 404) {
        String text = "Sorry!!!";
        String dialogMesage = "Product insertion failed. Retry.....";
        String buttonMessage = "Ok!!";
        await CustomDialog.openDialog(
            context: context,
            title: text,
            message: dialogMesage,
            mainIcon: Icons.check,
            subIcon: Icons.error);
      } else if (data['response_code'] == 100) {
        String text = "Congratulations!!!";
        String dialogMesage = "Product added successfully.";
        String buttonMessage = "Done";
        Navigator.of(context).pop();
        await CustomDialog.openDialog(
            context: context,
            title: text,
            message: dialogMesage,
            mainIcon: Icons.check,
            subIcon: HandShakeIcon.handshake);
      }
    }
  }

  bool _validator() {
    if (_validateCategory() &&
        _validatorBreed() &&
        _validatorPhoto() &&
        _validatorQuantity() &&
        _validatorPrice()) {
      print("success");
      return true;
    } else {
      print("failed");
      return false;
    }
  }

  bool _validateCategory() {
    if (selectedCategory == null) {
      errorCategory =
          AppLocalizations.of(context).translate("Category not selected");
      print("category failed");
      return false;
    }
    errorCategory = null;
    print("category success");
    return true;
  }

  bool _validatorBreed() {
    if (_breedController.text.isEmpty) {
      errorBreed =
          AppLocalizations.of(context).translate("Breed must be added");
      return false;
    }
    if (_breedController.text.trim().length > 10) {
      errorBreed = AppLocalizations.of(context)
          .translate("Breed must be have less than 10 characters");
      return false;
    }
    print("breed success");
    errorBreed = null;
    return true;
  }

  bool _validatorQuantity() {
    if (_quantityController.text.isEmpty) {
      errorQuantity =
          AppLocalizations.of(context).translate("Quantity must be added");
      return false;
    }

    if (_isNumeric(_quantityController.text.trim()) == false) {
      errorQuantity =
          AppLocalizations.of(context).translate("Quantity must be a number");
      return false;
    }

    if (int.tryParse(_quantityController.text.trim()) == null) {
      errorQuantity =
          AppLocalizations.of(context).translate("Remove decimal point");
      return false;
    }
    if (int.parse(_quantityController.text.trim()) <= 0) {
      errorQuantity = AppLocalizations.of(context).translate("Greater than 0");
      return false;
    }
    print("quantity success");
    errorQuantity = null;
    return true;
  }

  bool _validatorPrice() {
    if (_priceController.text.isEmpty) {
      errorPrice =
          AppLocalizations.of(context).translate("Price must be added");
      return false;
    }
    if (_isNumeric(_priceController.text.trim()) == false) {
      errorPrice =
          AppLocalizations.of(context).translate("Price must be a number");
      return false;
    }
    // if (double.tryParse(_priceController.text.trim()) <
    //     double.tryParse(_priceController.text.trim()).ceil()) {
    //   errorPrice = "Remove decimal point";
    //   return false;
    // }
    if (double.tryParse(_priceController.text.trim()) <= 0) {
      errorPrice = AppLocalizations.of(context).translate("Greater than 0");
      return false;
    }
    print("price success");
    errorPrice = null;
    return true;
  }

  bool _validatorPhoto() {
    if (isSeller == false) {
      _photoText = AppLocalizations.of(context).translate("Add Photo");
      _isPhotoError = false;
      return true;
    }
    if (_image == null) {
      _photoText = AppLocalizations.of(context).translate("Photo not added");
      _isPhotoError = true;
      return false;
    }
    _isPhotoError = false;
    _photoText = AppLocalizations.of(context).translate("Add Photo");
    return true;
  }

  bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  List<String> getCategoryNameAsList(List<Category> catgeoryList) {
    List<String> catList = [];
    print(this.catgeoryList);

    for (Category category in this.catgeoryList) {
      catList.add(AppLocalizations.of(context).translate(category.name));
    }
    return catList;
  }

  void _clickHandler() async {
    String address = await _getLocation();
    setState(() {
      _addressText = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    var appBar = AppBar(
      title: Text(AppLocalizations.of(context).translate('Product Details'),
          style: Theme.of(context).textTheme.headline1.apply(
                color: Colors.white,
                letterSpacingDelta: -5.0,
              )),
      iconTheme: IconThemeData(color: Colors.white),
    );
    var height = (MediaQuery.of(context).size.height -
        appBar.preferredSize.height -
        MediaQuery.of(context).padding.top);
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: appBar,
      body: FutureBuilder(
        future: _loadCatAndUserType(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            if (snapshot.data == null) {
              return Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }
          this.catgeoryList = snapshot.data;
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: SingleChildScrollView(
              child: Container(
                height: height,
                width: width,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: CategoryDropDown(
                        categoryHandler: _categoryHandler,
                        dropDownItems: getCategoryNameAsList(snapshot.data),
                        dropdownValue: dropDownValue,
                        errorText: errorCategory,
                        titleText:
                            AppLocalizations.of(context).translate("Category"),
                        hintText: AppLocalizations.of(context)
                            .translate("Drop Down Hint"),
                      ),
                    ),
                    Container(
                      width: width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextInputCard(
                              icon: Icons.fiber_pin,
                              titype: TextInputType.number,
                              htext: AppLocalizations.of(context)
                                  .translate('Breed'),
                              mdata: data,
                              controller: _breedController,
                              width: data.size.width * 0.9,
                              errorText: errorBreed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          if (isSeller)
                            Container(
                              width: width * 0.5,
                              child: ButtonWidget(
                                iconData: Icons.photo,
                                text: _photoText,
                                handlerMethod: getImage,
                                height: 55,
                                width: 150,
                                isError: _isPhotoError,
                              ),
                            ),
                          if (isSeller)
                            Container(
                              width: width * 0.4,
                              child: FittedBox(
                                child: CircleAvatar(
                                  backgroundImage: _image == null
                                      ? AssetImage('assests/images/logo.png')
                                      : FileImage(File(_image.path)),
                                  backgroundColor: Colors.white,
                                  radius: 35.0,
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextInputCard(
                            icon: MYBaazar.balance,
                            titype: TextInputType.number,
                            htext: AppLocalizations.of(context)
                                .translate('Quantity'),
                            mdata: data,
                            controller: _quantityController,
                            width: data.size.width * 0.9,
                            errorText: errorQuantity,
                          ),
                        ),
                        Expanded(
                          child: TextInputCard(
                            icon: MYBaazar.rupee_indian,
                            titype: TextInputType.number,
                            htext:
                                AppLocalizations.of(context).translate('Price'),
                            mdata: data,
                            controller: _priceController,
                            width: data.size.width * 0.9,
                            errorText: errorPrice,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Container(
                        height: 55,
                        width: 200,
                        child: FlatButton(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32.0),
                              side: BorderSide(
                                  color: Theme.of(context).primaryColor)),
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(8.0),
                          onPressed: () {
                            setState(() {
                              FocusScope.of(context).unfocus();
                              _submitData();
                            });
                          },
                          child: Text(
                            AppLocalizations.of(context)
                                .translate("Post Offer"),
                            style: Theme.of(context).textTheme.bodyText1.apply(
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // @override
  // void deactivate() {
  //   FocusScope.of(context).unfocus();
  //   super.deactivate();
  // }
}
