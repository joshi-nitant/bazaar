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
import 'package:shared_preferences/shared_preferences.dart';

import 'google_maps_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProdReqUpdate extends StatefulWidget {
  static final String routeName = "/update";

  @override
  _ProdReqUpdateState createState() => _ProdReqUpdateState();
}

class _ProdReqUpdateState extends State<ProdReqUpdate> {
  bool isSeller;
  List<Category> catgeoryList;
  dynamic _selectedObject;
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

  static const String kGoogleApiKey = "AIzaSyBuZTVFf0pDt_MgQedl5aNsOxu286k7Wmw";
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      _image = File(pickedFile.path);
      _selectedObject.image = _image.path.split('/').last;
    });
  }

  Future<void> _getLocation() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
    );
    print("here");
    print(p);
    displayPrediction(p);
  }

  Future<List<String>> getAutoCompleteResponse(String query) async {
    var prs;

    PlacesAutocompleteResponse placesAutocompleteResponse =
        await _places.autocomplete(query);
    prs = placesAutocompleteResponse.predictions
        .map((prediction) => prediction.description)
        .toList();
    print('Predictions: ' + prs.toString());
    return prs;
  }

  Future<Null> displayPrediction(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);

      print("detail $detail");

      var placeId = p.placeId;
      double lat = detail.result.geometry.location.lat;
      double lng = detail.result.geometry.location.lng;

      print(p.description);
      var address = await Geocoder.local.findAddressesFromQuery(p.description);
      print("Address $address");
      print(lat);
      print(lng);
    }
  }

  void _categoryHandler(String value) {
    print(value);
    setState(() {
      _selectedObject.category.name = value;
      _selectedObject.category =
          catgeoryList.firstWhere((category) => category.name == value);
      selectedCategory = _selectedObject.category;
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
      _selectedObject.address = _selectedAddress.addressLine;
      _selectedObject.state = _selectedAddress.adminArea;
      _selectedObject.postalCode = _selectedAddress.postalCode.toString();
      _selectedObject.city = _selectedAddress.subAdminArea.toString();
      _selectedObject.latitude = _selectedCoord.latitude.toString();
      _selectedObject.longitude = _selectedCoord.longitude.toString();
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
      _selectedObject.qualityCertificate =
          this.qualityCertificate.path.split('/').last;
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
    print(qualityCertificate);
    print(_image);
    FormData formData = FormData.fromMap(
      {
        "qualityCertificate": isSeller && qualityCertificate != null
            ? await MultipartFile.fromFile(
                this.qualityCertificate.path,
                filename: _selectedObject.qualityCertificate,
              )
            : null,
        "productImage": isSeller && _image != null
            ? await MultipartFile.fromFile(
                _image.path,
                filename: _selectedObject.image,
              )
            : null,
        "id": _selectedObject.id,
        "isSeller": isSeller,
        "price": _priceController.text,
        "breed": _breedController.text,
        "quantity": _quantityController.text,
        "address": _selectedObject.address,
        "state": _selectedObject.state,
        "pincode": _selectedObject.postalCode,
        "city": _selectedObject.city,
        "latitude": _selectedObject.latitude,
        "longitude": _selectedObject.longitude,
        "user_id": _userId,
        "category": _selectedObject.category.id,
      },
    );
    try {
      var dio = Dio();
      Response response =
          await dio.post(Utils.URL + "/updateProdReq.php", data: formData);
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
    //print(_selectedAddress.addressLine);
    print(selectedCategory);
    print(_userId);
    if (_priceController.text != null &&
        _breedController.text != null &&
        _quantityController.text != null &&
        _userId != null) {
      print("got eveything");
      String jsonResponse = await uploadData();
      var data = json.decode(jsonResponse);
      if (data['response_code'] == 404) {
        String text = "Sorry!!!";
        String dialogMesage = "Product updation failed. Retry.....";
        String buttonMessage = "Ok!!";
        showMyDialog(context, text, dialogMesage, buttonMessage);
      } else if (data['response_code'] == 100) {
        String text = "Congratulations!!!";
        String dialogMesage = "Product updated successfully.";
        String buttonMessage = "Done";
        showMyDialog(context, text, dialogMesage, buttonMessage);
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

  @override
  Widget build(BuildContext context) {
    var routeArgs =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    _selectedObject = routeArgs['selected_object'];
    _breedController.text = _selectedObject.breed;
    _quantityController.text = _selectedObject.quantity;
    _priceController.text = _selectedObject.price_expected;
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
                    CategoryDropDown(_selectedObject.category.name,
                        getCategoryNameAsList(snapshot.data), _categoryHandler),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: TextInputCard(
                                icon: Icons.fiber_pin,
                                titype: TextInputType.number,
                                htext: 'Breed',
                                mdata: data,
                                controller: _breedController)),
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
                                ? NetworkImage(
                                    "${Utils.URL}images/${_selectedObject.image}")
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
                        )),
                        Expanded(
                            child: TextInputCard(
                          icon: Icons.monetization_on,
                          titype: TextInputType.number,
                          htext: 'Price',
                          mdata: data,
                          controller: _priceController,
                        )),
                      ],
                    ),
                    if (isSeller)
                      Row(
                        children: <Widget>[
                          Expanded(
                              child: ButtonWidget(
                            iconData: Icons.insert_drive_file,
                            text: 'Add Certificate',
                            handlerMethod: pickFile,
                          )),
                          Expanded(
                            child: _selectedObject.quality_certificate == null
                                ? Text("You didn't upload any certifcate")
                                : Text(_selectedObject.qualityCertificate),
                          )
                        ],
                      ),
                    // TextField(
                    //   // onChanged: (query) async {
                    //   //   await getAutoCompleteResponse(query);
                    //   //   setState(() {});
                    //   // },
                    //   onTap: () async {
                    //     //_openGoogleMaps(context);
                    //     //show input autocomplete with selected mode
                    //     //then get the Prediction selected

                    //     print("onTap");
                    //     Prediction p = await PlacesAutocomplete.show(
                    //       context: context,
                    //       apiKey: kGoogleApiKey,
                    //       language: "en",
                    //       mode: Mode.fullscreen,
                    //       components: [Component(Component.country, "in")],
                    //     );
                    //     print("here");
                    //     print(p);
                    //     displayPrediction(p);
                    //   },

                    //   textInputAction: TextInputAction.search,
                    //   decoration: InputDecoration(
                    //     hintText: "Enter your location",
                    //     border: InputBorder.none,
                    //     contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
                    //   ),
                    // ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ButtonWidget(
                            iconData: Icons.search,
                            text: "Enter Location",
                            handlerMethod: () {
                              _openGoogleMaps(context);
                            },
                          ),
                        ),
                        Expanded(
                          child: Text(_selectedObject.address),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 20.0,
                    ),

                    // Container(
                    //   height: data.size.height * 0.2,
                    //   width: data.size.width * 0.9,
                    //   color: primarycolor,
                    //   child: Text('Put Map Here'),
                    // ),
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
          //                   AppLocalizations.of(context).translate('Breed')),
          //           controller: _breedController,
          //           onSubmitted: (_) => _submitData(),
          //         ),
          //         CategoryDropDown(dropDownValue,
          //             getCategoryNameAsList(snapshot.data), _categoryHandler),
          //         TextField(
          //           decoration: InputDecoration(
          //               labelText:
          //                   AppLocalizations.of(context).translate('Quantity')),
          //           controller: _quantityController,
          //           keyboardType: TextInputType.number,
          //           onSubmitted: (_) => _submitData(),
          //         ),
          //         TextField(
          //           decoration: InputDecoration(
          //               labelText:
          //                   AppLocalizations.of(context).translate('Price')),
          //           controller: _priceController,
          //           keyboardType: TextInputType.number,
          //           onSubmitted: (_) => _submitData(),
          //         ),
          //         RaisedButton(
          //           child: Text(AppLocalizations.of(context)
          //               .translate('Select Location')),
          //           color: Theme.of(context).primaryColor,
          //           textColor: Theme.of(context).textTheme.button.color,
          //           onPressed: () {
          //             _openGoogleMaps(context);
          //           },
          //         ),
          //         Container(
          //           height: 40,
          //           child: Row(
          //             children: <Widget>[
          //               Expanded(
          //                 child: Text(
          //                   _selectedDate == null
          //                       ? 'No Date Chosen!'
          //                       : 'Picked Date ${DateFormat.yMd().format(_selectedDate)}',
          //                 ),
          //               ),
          //               FlatButton(
          //                 textColor: Theme.of(context).primaryColor,
          //                 child: Text(
          //                   AppLocalizations.of(context)
          //                       .translate('Choose Date'),
          //                   style: TextStyle(
          //                     fontWeight: FontWeight.bold,
          //                   ),
          //                 ),
          //                 onPressed: _presentDatePicker,
          //               ),
          //             ],
          //           ),
          //         ),
          //         Row(
          //           children: <Widget>[
          //             if (isSeller)
          //               RaisedButton(
          //                 child: Text(AppLocalizations.of(context)
          //                     .translate("Choose Quality Certificate")),
          //                 onPressed: () {
          //                   pickFile();
          //                 },
          //               ),
          //             RaisedButton(
          //               child:
          //                   Text(AppLocalizations.of(context).translate("Add")),
          //               onPressed: () {
          //                 _submitData();
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
