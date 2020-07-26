import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/google_maps_screen.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:search_map_place/search_map_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_maps_webservice/places.dart';
//import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';

class ProdReqDetail extends StatefulWidget {
  static final String routeName = "/detail";

  @override
  _ProdReqDetailState createState() => _ProdReqDetailState();
}

class _ProdReqDetailState extends State<ProdReqDetail> {
  Product product;
  Requirement requirement;
  Category category;
  int userId;
  bool isSeller;
  bool isProduct;
  final _priceBidController = TextEditingController();
  final _quantityBidController = TextEditingController();
  static const kGoogleApiKey = Utils.API_KEY;
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
  var deliveryAddress;
  LatLng deliveryCoord;
  double _distance = 0.0;
  int _deliveryAmount = 0;

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

  Future<Category> _loadCatAndUserType() async {
    var routeArgs =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    Object _detailObject = routeArgs['object'];

    if (_detailObject is Product) {
      product = _detailObject;
      isProduct = true;
    } else {
      requirement = _detailObject;
      isProduct = false;
    }
    String jsonString = await _getCategoryList();
    this.isSeller = await _getUserType();
    this.userId = await _getUserId();
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
    if (_detailObject is Product) {
      category = categoryList.firstWhere((element) => element.id == product.id,
          orElse: () => null);
    } else {
      category = categoryList.firstWhere(
          (element) => element.id == requirement.id,
          orElse: () => null);
    }
    print(category.id);
    return category;
  }

  Future<Null> displayPrediction(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);

      var placeId = p.placeId;
      double lat = detail.result.geometry.location.lat;
      double lng = detail.result.geometry.location.lng;

      var address = await Geocoder.local.findAddressesFromQuery(p.description);

      print(lat);
      print(lng);
    }
  }

  Future<List<Address>> _getLocationFromCoordinate(LatLng coords) async {
    final coordinates = new Coordinates(coords.latitude, coords.longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    //print("Inside address");
    //print(addresses);
    return addresses;
  }

  Future<double> _getDistance(LatLng destinationCoordinates) async {
    LatLng startCoordinates;
    if (isProduct) {
      startCoordinates = LatLng(
          double.parse(product.latitude), double.parse(product.longitude));
    } else {
      startCoordinates = LatLng(double.parse(requirement.latitude),
          double.parse(requirement.longitude));
    }

    double distanceInMeters = await Geolocator().distanceBetween(
      startCoordinates.latitude,
      startCoordinates.longitude,
      destinationCoordinates.latitude,
      destinationCoordinates.longitude,
    );
    return distanceInMeters;
  }

  void _openGoogleMaps(BuildContext context) async {
    var finalLocation = await Navigator.of(context).pushNamed(
      MapSample.routeName,
    );
    var finalAddress = await _getLocationFromCoordinate(finalLocation);
    double distance = await _getDistance(finalLocation);
    setState(() {
      //print("Inside finalLocation");
      _distance = distance;
      print(deliveryAddress);
      deliveryCoord = finalLocation;
      deliveryAddress = finalAddress.first;
    });
  }

  Future<String> _uploadData() async {
    FormData formData = FormData.fromMap({
      "isSeller": isSeller,
      "price": _priceBidController.text,
      "quantity": _quantityBidController.text,
      "user_id": userId,
      "delivery_amount": _deliveryAmount,
      "id": isProduct ? product.id : requirement.id,
    });
    try {
      var dio = Dio();
      Response response =
          await dio.post(Utils.URL + "/insertProdReqBid.php", data: formData);
      print(response);
      return response.data as String;
    } on Exception catch (e) {
      print(e);
      print("exeception");
    }
  }

  void _submitData() async {
    print(_quantityBidController);
    if (_quantityBidController != null && _priceBidController != null) {
      String jsonResponse = await _uploadData();
      var data = json.decode(jsonResponse);
      if (data['response_code'] == 404) {
        String text = "Sorry!!!";
        String dialogMesage = "Offer request failed. Retry.....";
        String buttonMessage = "Ok!!";
        _showMyDialog(text, dialogMesage, buttonMessage);
      } else if (data['response_code'] == 100) {
        String text = "Congratulations!!!";
        String dialogMesage = "Offer sent successfully.";
        String buttonMessage = "Done";
        _showMyDialog(text, dialogMesage, buttonMessage);
      }
    }
  }

  Future<void> _showMyDialog(
      String title, String message, String buttonMessage) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(buttonMessage),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0)),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('app_title'),
        ),
      ),
      body: FutureBuilder(
          future: _loadCatAndUserType(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return Container(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      isSeller
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                radius: 30.0,
                                backgroundImage: NetworkImage(
                                  Utils.URL + "images/" + category.imgPath,
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                radius: 30.0,
                                backgroundImage: NetworkImage(
                                  Utils.URL + "images/" + product.image,
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(AppLocalizations.of(context)
                                  .translate(category.name)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(isProduct
                                  ? "City ${product.city}"
                                  : "City ${requirement.city}"),
                            ),
                            Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(isProduct
                                      ? "State ${product.state}"
                                      : "State ${requirement.state}"),
                                ),
                              ],
                            ),
                            Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("Delivery $_deliveryAmount"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(isProduct
                            ? "Remaining ${product.remaining_qty}"
                            : "Remaining ${requirement.remaining_qty}"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(isProduct
                            ? "Total ${product.quantity}"
                            : "Total ${requirement.quantity}"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(isProduct
                            ? "Price ${product.price_expected}"
                            : "Price ${requirement.price_expected}"),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 100,
                          child: TextField(
                              keyboardType: TextInputType.number,
                              controller: _priceBidController),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 100,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: _quantityBidController,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // RaisedButton(
                  //   onPressed: () {
                  //     _openGoogleMaps(context);
                  //   },
                  //   child: Text('Find address'),
                  // ),
                  //SearchMapPlaceWidget(apiKey: Utils.API_KEY),
                  RaisedButton(
                    child: Text('Send Offer'),
                    onPressed: userId == null ? null : _submitData,
                  ),
                ],
              ),
            );
          }),
    );
  }
}