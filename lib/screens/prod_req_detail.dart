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
import 'package:baazar/widgets/text_input_card.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
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
  User _currentUser;
  User _ownerUser;
  int _costPerKm = 10;

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

  _getUser(int id) async {
    var response = await http.post(
      Utils.URL + "getUser.php",
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
    User user = User(
      id: userMap['user_id'],
      latitude: userMap['latitude'],
      longitude: userMap['longitude'],
      address: userMap['address'],
      state: userMap['state'],
      city: userMap['city'],
    );

    return user;
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

    this.isSeller = await _getUserType();
    this.userId = await _getUserId();
    if (this.userId != null) {
      this._currentUser = await _getUser(this.userId);

      if (isProduct) {
        this._ownerUser = await _getUser(int.parse(product.userId));
      } else {
        this._ownerUser = await _getUser(int.parse(requirement.userId));
      }

      LatLng startCoordinate = LatLng(
        double.parse(_currentUser.latitude),
        double.parse(_currentUser.longitude),
      );
      LatLng endCoordinate = LatLng(
        double.parse(_ownerUser.latitude),
        double.parse(_ownerUser.longitude),
      );
      double distance = await _getDistance(startCoordinate, endCoordinate);
      distance = distance / 1000;
      _deliveryAmount = (distance * _costPerKm).toInt();
    }
    String jsonString = await _getCategoryList();
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

    print(product);
    if (_detailObject is Product) {
      category = categoryList.firstWhere(
          (element) => element.id == product.category_id,
          orElse: () => null);
    } else {
      category = categoryList.firstWhere(
          (element) => element.id == requirement.category_id,
          orElse: () => null);
    }
    //print(product.image);
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

  // Future<List<Address>> _getLocationFromCoordinate(LatLng coords) async {
  //   final coordinates = new Coordinates(coords.latitude, coords.longitude);
  //   var addresses =
  //       await Geocoder.local.findAddressesFromCoordinates(coordinates);
  //   //print("Inside address");
  //   //print(addresses);
  //   return addresses;
  // }

  Future<double> _getDistance(
      LatLng startCoordinates, LatLng destinationCoordinates) async {
    double distanceInMeters = await Geolocator().distanceBetween(
      startCoordinates.latitude,
      startCoordinates.longitude,
      destinationCoordinates.latitude,
      destinationCoordinates.longitude,
    );
    return distanceInMeters;
  }

  // void _openGoogleMaps(BuildContext context) async {
  //   var finalLocation = await Navigator.of(context).pushNamed(
  //     MapSample.routeName,
  //   );
  //   var finalAddress = await _getLocationFromCoordinate(finalLocation);
  //   //double distance = await _getDistance(finalLocation);
  //   setState(() {
  //     //print("Inside finalLocation");
  //     _distance = distance;
  //     print(deliveryAddress);
  //     deliveryCoord = finalLocation;
  //     deliveryAddress = finalAddress.first;
  //   });
  // }

  Future<String> _uploadData() async {
    FormData formData = FormData.fromMap({
      "isSeller": isSeller,
      "price": _priceBidController.text,
      "quantity": _quantityBidController.text,
      "user_id": userId,
      "delivery_amount": _deliveryAmount,
      "id": isProduct ? product.id : requirement.id,
      'category': isProduct ? product.category_id : requirement.category_id,
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
      } else if (data['response_code'] == 405) {
        String text = "Sorry!!!";
        String dialogMesage =
            "You have not listed any product of ${category.name}";
        String buttonMessage = "Ok!!";
        _showMyDialog(text, dialogMesage, buttonMessage);
      } else if (data['response_code'] == 406) {
        String text = "Sorry!!!";
        String dialogMesage =
            "You do not have sufficient quantity of ${category.name}";
        String buttonMessage = "Ok!!";
        _showMyDialog(text, dialogMesage, buttonMessage);
      } else if (data['response_code'] == 100) {
        String text = "Congratulations!!!";
        String dialogMesage = "Offer sent successfully.";
        String buttonMessage = "Done";
        await _showMyDialog(text, dialogMesage, buttonMessage);
        Navigator.pop(context);
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

  Widget firstCardInnerRow(
      String text, BuildContext context, TextDirection direction) {
    return Text(
      text,
      textDirection: direction,
      //softWrap: false,
      //overflow: TextOverflow.ellipsis,
      style: TextStyle(
          color: Colors.black,
          fontSize: MediaQuery.of(context).textScaleFactor * 14,
          fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;

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
          future: _loadCatAndUserType(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return SingleChildScrollView(
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      height: isSeller
                          ? data.size.height * 0.2
                          : data.size.height * 0.3,
                      width: data.size.width,
                      margin: EdgeInsets.all(data.size.width * 0.02),
                      child: Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                isSeller
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          Utils.URL +
                                              "images/" +
                                              category.imgPath,
                                        ),
                                        backgroundColor: Colors.grey[200],
                                        radius: data.size.height * 0.06,
                                      )
                                    : CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          Utils.URL +
                                              "productImage/" +
                                              product.image,
                                        ),
                                        backgroundColor: Colors.grey[200],
                                        radius: data.size.height * 0.06,
                                      ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    firstCardInnerRow(
                                      AppLocalizations.of(context)
                                          .translate(category.name),
                                      context,
                                      TextDirection.ltr,
                                    ),
                                    firstCardInnerRow(
                                      'Location',
                                      context,
                                      TextDirection.ltr,
                                    ),
                                    if (isSeller == false)
                                      firstCardInnerRow(
                                        'Delivery Charges',
                                        context,
                                        TextDirection.ltr,
                                      ),
                                    if (isSeller == false)
                                      firstCardInnerRow(
                                        'Packaging Charges',
                                        context,
                                        TextDirection.ltr,
                                      ),
                                    if (isSeller == false)
                                      firstCardInnerRow(
                                        'Transaction Charges',
                                        context,
                                        TextDirection.ltr,
                                      ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    isProduct
                                        ? firstCardInnerRow(
                                            product.breed,
                                            context,
                                            TextDirection.rtl,
                                          )
                                        : firstCardInnerRow(
                                            requirement.breed,
                                            context,
                                            TextDirection.rtl,
                                          ),
                                    firstCardInnerRow(
                                      "${_ownerUser.city},${_ownerUser.state}",
                                      context,
                                      TextDirection.rtl,
                                    ),
                                    if (isSeller == false)
                                      firstCardInnerRow(
                                        this.userId == null
                                            ? "Login Required"
                                            : _deliveryAmount.toString(),
                                        context,
                                        TextDirection.rtl,
                                      ),
                                    if (isSeller == false)
                                      firstCardInnerRow(
                                        'xxxxxx',
                                        context,
                                        TextDirection.rtl,
                                      ),
                                    if (isSeller == false)
                                      firstCardInnerRow(
                                        'xxxxxx',
                                        context,
                                        TextDirection.rtl,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                        color: Colors.grey[200],
                      ),
                    ),
                    Container(
                      height: data.size.height * 0.1,
                      width: data.size.width,
                      margin: EdgeInsets.all(data.size.width * 0.02),
                      child: Card(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.line_weight,
                                      color: Theme.of(context).primaryColor,
                                      size: 20.0,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 1.0),
                                      child: isProduct
                                          ? Text(
                                              product.remainingQty,
                                              style: TextStyle(
                                                fontSize: curScaleFactor * 14,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Text(
                                              requirement.remainingQty,
                                              style: TextStyle(
                                                fontSize: curScaleFactor * 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Available Qty',
                                    style: TextStyle(
                                      fontSize: curScaleFactor * 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 10, 0),
                                  child: Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.monetization_on,
                                        color: Theme.of(context).primaryColor,
                                        size: 20.0,
                                      ),
                                      isProduct
                                          ? Text(
                                              product.price_expected,
                                              style: TextStyle(
                                                fontSize: curScaleFactor * 14,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Text(
                                              requirement.price_expected,
                                              style: TextStyle(
                                                fontSize: curScaleFactor * 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      'Offer',
                                      style: TextStyle(
                                        fontSize: curScaleFactor * 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.line_weight,
                                      color: Theme.of(context).primaryColor,
                                      size: 20.0,
                                    ),
                                    isProduct
                                        ? Text(
                                            product.quantity,
                                            style: TextStyle(
                                              fontSize: curScaleFactor * 14,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            requirement.quantity,
                                            style: TextStyle(
                                              fontSize: curScaleFactor * 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      'Total Qty',
                                      style: TextStyle(
                                        fontSize: curScaleFactor * 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                        color: Colors.grey[200],
                      ),
                    ),
                    if (isProduct && product.qualityCertificate != null)
                      Container(
                        height: data.size.height * 0.2,
                        width: data.size.width * 0.9,
                        margin: EdgeInsets.all(data.size.width * 0.02),
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              "${Utils.URL}qualityCertificate/${product.qualityCertificate}",
                            ),
                          ),
                        ),
                      ),
                    Container(
                      height: data.size.height * 0.2,
                      width: data.size.width,
                      margin: EdgeInsets.all(data.size.width * 0.02),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 1,
                                      child: TextInputCard(
                                        icon: Icons.ac_unit,
                                        titype: TextInputType.number,
                                        htext: "Quantity",
                                        mdata: data,
                                        controller: _quantityBidController,
                                        width: data.size.width * 0.3,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: TextInputCard(
                                        icon: Icons.ac_unit,
                                        titype: TextInputType.number,
                                        htext: "Price",
                                        mdata: data,
                                        controller: _priceBidController,
                                        width: data.size.width * 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  width: data.size.width * 1,
                                  child: RaisedButton(
                                    onPressed:
                                        userId == null ? null : _submitData,
                                    child: Text(
                                      'Send Offer',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 14.0),
                                    ),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0)),
                                    elevation: 25.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        color: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                      ),
                    ),
                  ],
                ),
              ),
            );
            // return Container(
            //   child: Column(
            //     children: <Widget>[
            //       Row(
            //         children: <Widget>[
            //           isSeller
            //               ? Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: CircleAvatar(
            //                     radius: 30.0,
            //                     backgroundImage: NetworkImage(
            //                       Utils.URL + "images/" + category.imgPath,
            //                     ),
            //                     backgroundColor: Colors.transparent,
            //                   ),
            //                 )
            //               : Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: CircleAvatar(
            //                     radius: 30.0,
            //                     backgroundImage: NetworkImage(
            //                       Utils.URL + "images/" + product.image,
            //                     ),
            //                     backgroundColor: Colors.transparent,
            //                   ),
            //                 ),
            //           Padding(
            //             padding: const EdgeInsets.all(8.0),
            //             child: Column(
            //               children: <Widget>[
            //                 Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: Text(AppLocalizations.of(context)
            //                       .translate(category.name)),
            //                 ),
            //                 Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: Text(isProduct
            //                       ? "City ${product.city}"
            //                       : "City ${requirement.city}"),
            //                 ),
            //                 Column(
            //                   children: <Widget>[
            //                     Padding(
            //                       padding: const EdgeInsets.all(8.0),
            //                       child: Text(isProduct
            //                           ? "State ${product.state}"
            //                           : "State ${requirement.state}"),
            //                     ),
            //                   ],
            //                 ),
            //                 Column(
            //                   children: <Widget>[
            //                     Padding(
            //                       padding: const EdgeInsets.all(8.0),
            //                       child: Text("Delivery $_deliveryAmount"),
            //                     ),
            //                   ],
            //                 ),
            //               ],
            //             ),
            //           )
            //         ],
            //       ),
            //       Row(
            //         children: <Widget>[
            //           Padding(
            //             padding: const EdgeInsets.all(8.0),
            //             child: Text(isProduct
            //                 ? "Remaining ${product.remaining_qty}"
            //                 : "Remaining ${requirement.remaining_qty}"),
            //           ),
            //           Padding(
            //             padding: const EdgeInsets.all(8.0),
            //             child: Text(isProduct
            //                 ? "Total ${product.quantity}"
            //                 : "Total ${requirement.quantity}"),
            //           ),
            //           Padding(
            //             padding: const EdgeInsets.all(8.0),
            //             child: Text(isProduct
            //                 ? "Price ${product.price_expected}"
            //                 : "Price ${requirement.price_expected}"),
            //           ),
            //         ],
            //       ),
            //       Row(
            //         children: <Widget>[
            //           Padding(
            //             padding: const EdgeInsets.all(8.0),
            //             child: Container(
            //               width: 100,
            //               child: TextField(
            //                   keyboardType: TextInputType.number,
            //                   controller: _priceBidController),
            //             ),
            //           ),
            //           Padding(
            //             padding: const EdgeInsets.all(8.0),
            //             child: Container(
            //               width: 100,
            //               child: TextField(
            //                 keyboardType: TextInputType.number,
            //                 controller: _quantityBidController,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       // RaisedButton(
            //       //   onPressed: () {
            //       //     _openGoogleMaps(context);
            //       //   },
            //       //   child: Text('Find address'),
            //       // ),
            //       //SearchMapPlaceWidget(apiKey: Utils.API_KEY),
            //       RaisedButton(
            //         child: Text('Send Offer'),
            //         onPressed: userId == null ? null : _submitData,
            //       ),
            //     ],
            //   ),
            // );
          }),
    );
  }
}
