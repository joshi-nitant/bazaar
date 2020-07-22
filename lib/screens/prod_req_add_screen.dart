import 'dart:convert';
import 'dart:io';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/user.dart';

import 'package:baazar/models/user_location.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:baazar/widgets/drop_down_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_maps_screen.dart';
import 'package:file_picker/file_picker.dart';

class ProdReqAdd extends StatefulWidget {
  static final String routeName = "/location";

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
      print("Inside finalLocation");
      print(_selectedAddress);
      _selectedCoord = finalLocation;
      _selectedAddress = finalAddress.first;
    });
  }

  Future<List<Address>> _getLocationFromCoordinate(LatLng coords) async {
    final coordinates = new Coordinates(coords.latitude, coords.longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    print("Inside address");
    print(addresses);
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
    print("Cateory List Start");
    String jsonString = await _getCategoryList();
    print(jsonString);
    this.isSeller = await _getUserType();
    print(this.isSeller);
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
    print("Cateory List End");
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
    if (isSeller) {
      qualityCertificate.path.split('/').last;
    }
    FormData formData = FormData.fromMap({
      "qualityCertificate": isSeller
          ? await MultipartFile.fromFile(qualityCertificate.path,
              filename: fileName)
          : null,
      "isSeller": isSeller,
      "price": _priceController.text,
      "breed": _breedController.text,
      "quantity": _quantityController.text,
      "date": _selectedDate,
      "address": _selectedAddress.addressLine,
      "state": _selectedAddress.adminArea,
      "pincode": _selectedAddress.postalCode,
      "city": _selectedAddress.subAdminArea,
      "latitude": _selectedCoord.latitude,
      "longitude": _selectedCoord.longitude,
      "user_id": _userId,
      "category": selectedCategory.id,
    });
    try {
      var dio = Dio();
      Response response =
          await dio.post(Utils.URL + "/insertProdReq.php", data: formData);
      print(response);
      return response.data;
    } on Exception catch (e) {
      print(e);
    }
  }

  void _submitData() {
    if (_priceController.text != null &&
        _breedController.text != null &&
        _quantityController.text != null &&
        _selectedDate != null &&
        _selectedAddress != null &&
        selectedCategory != null &&
        _userId != null) {
      print(_priceController.text);
      print(_breedController.text);
      print(_quantityController.text);
      print(_selectedDate);
      print(_selectedAddress.featureName);
      print(_selectedAddress.addressLine);

      print(_selectedCoord.latitude);
      print(_selectedCoord.longitude);
      print(selectedCategory);
      print(qualityCertificate);
      print(isSeller);
      print(_userId);
      uploadData();
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
                            AppLocalizations.of(context).translate('Breed')),
                    controller: _breedController,
                    onSubmitted: (_) => _submitData(),
                  ),
                  CategoryDropDown(dropDownValue,
                      getCategoryNameAsList(snapshot.data), _categoryHandler),
                  TextField(
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).translate('Quantity')),
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _submitData(),
                  ),
                  TextField(
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).translate('Price')),
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _submitData(),
                  ),
                  RaisedButton(
                    child: Text(AppLocalizations.of(context)
                        .translate('Select Location')),
                    color: Theme.of(context).primaryColor,
                    textColor: Theme.of(context).textTheme.button.color,
                    onPressed: () {
                      _openGoogleMaps(context);
                    },
                  ),
                  Container(
                    height: 40,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'No Date Chosen!'
                                : 'Picked Date ${DateFormat.yMd().format(_selectedDate)}',
                          ),
                        ),
                        FlatButton(
                          textColor: Theme.of(context).primaryColor,
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('Choose Date'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _presentDatePicker,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      if (isSeller)
                        RaisedButton(
                          child: Text(AppLocalizations.of(context)
                              .translate("Choose Quality Certificate")),
                          onPressed: () {
                            pickFile();
                          },
                        ),
                      RaisedButton(
                        child:
                            Text(AppLocalizations.of(context).translate("Add")),
                        onPressed: () {
                          _submitData();
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
