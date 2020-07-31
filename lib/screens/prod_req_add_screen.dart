import 'dart:convert';
import 'dart:io';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/widgets/drop_down_widget.dart';

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

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      _image = File(pickedFile.path);
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
    _addressText = await displayPrediction(p);
    return _addressText;
  }

  // Future<List<String>> getAutoCompleteResponse(String query) async {
  //   var prs;

  //   PlacesAutocompleteResponse placesAutocompleteResponse =
  //       await _places.autocomplete(query);
  //   prs = placesAutocompleteResponse.predictions
  //       .map((prediction) => prediction.description)
  //       .toList();
  //   print('Predictions: ' + prs.toString());
  //   return prs;
  // }

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

  // Future<void> _showMyDialog(
  //     String title, String message, String buttonMessage) async {
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false, // user must tap button!
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         shape:
  //             RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
  //         title: Text(title),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: <Widget>[
  //               Text(message),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           FlatButton(
  //             child: Text(buttonMessage),
  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(32.0)),
  //             color: Theme.of(context).primaryColor,
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
        "price": _priceController.text,
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
    print("submiting");
    print(_priceController.text);
    print(_breedController.text);
    print(_quantityController.text);
    print(selectedCategory);
    print(_userId);
    if (_priceController.text != null &&
        _breedController.text != null &&
        _quantityController.text != null &&
        selectedCategory != null &&
        _userId != null) {
      if ((isSeller && _image != null) || !isSeller) {
        String jsonResponse = await uploadData();
        var data = json.decode(jsonResponse);

        if (data['response_code'] == 404) {
          String text = "Sorry!!!";
          String dialogMesage = "Product insertion failed. Retry.....";
          String buttonMessage = "Ok!!";
          showMyDialog(context, text, dialogMesage, buttonMessage);
        } else if (data['response_code'] == 100) {
          String text = "Congratulations!!!";
          String dialogMesage = "Product added successfully.";
          String buttonMessage = "Done";
          await showMyDialog(context, text, dialogMesage, buttonMessage);
          Navigator.of(context).pop();
        }
      }
    }
  }

  List<String> getCategoryNameAsList(List<Category> catgeoryList) {
    List<String> catList = [];
    print(this.catgeoryList);

    for (Category category in this.catgeoryList) {
      catList.add(category.name);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate("app_title")),
      ),
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
                child: Column(
                  children: <Widget>[
                    CategoryDropDown(dropDownValue,
                        getCategoryNameAsList(snapshot.data), _categoryHandler),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextInputCard(
                            icon: Icons.fiber_pin,
                            titype: TextInputType.number,
                            htext: 'Breed',
                            mdata: data,
                            controller: _breedController,
                            width: data.size.width * 0.9,
                          ),
                        ),
                        if (isSeller)
                          Expanded(
                            child: ButtonWidget(
                              iconData: Icons.photo,
                              text: 'Add Photo',
                              handlerMethod: getImage,
                            ),
                          ),
                        if (isSeller)
                          CircleAvatar(
                            backgroundImage: _image == null
                                ? AssetImage('assests/images/logo.png')
                                : FileImage(File(_image.path)),
                            backgroundColor: Colors.white,
                            radius: 25.0,
                          ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: TextInputCard(
                          icon: Icons.fiber_pin,
                          titype: TextInputType.number,
                          htext: 'Quantity',
                          mdata: data,
                          controller: _quantityController,
                          width: data.size.width * 0.9,
                        )),
                        Expanded(
                            child: TextInputCard(
                          icon: Icons.monetization_on,
                          titype: TextInputType.number,
                          htext: 'Price',
                          mdata: data,
                          controller: _priceController,
                          width: data.size.width * 0.9,
                        )),
                      ],
                    ),
                    // Row(
                    //   children: <Widget>[
                    //     Expanded(child: prefix.buildButton(context, Icons.insert_drive_file, 'Add Certificate')),
                    //     Expanded(child: Text('Certificate Name'))
                    //   ],
                    // ),

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

                    SizedBox(
                      height: 20.0,
                    ),

                    SizedBox(
                      height: 50.0,
                    ),
                    Container(
                      height: 55,
                      width: 170,
                      child: FlatButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            side: BorderSide(
                                color: Theme.of(context).primaryColor)),
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(8.0),
                        onPressed: () {
                          _submitData();
                        },
                        child: Text(
                          AppLocalizations.of(context).translate("Post Offer"),
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
          );
        },
      ),
    );
  }
}
