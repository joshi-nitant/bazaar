import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/google_maps_screen.dart';
import 'package:baazar/screens/image_detail_screen.dart';
import 'package:baazar/screens/prod_req_add_screen.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:baazar/screens/singup_screen.dart';
import 'package:baazar/widgets/dialog_widget.dart';
import 'package:baazar/widgets/hand_shake_icon_icons.dart';
import 'package:baazar/widgets/m_y_baazar_icons.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:progress_dialog/progress_dialog.dart';
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
  String errorPrice;
  String errorQuantity;
  bool _initialLoad = true;

  bool _validator() {
    if (_validatorQuantity() && _validatorPrice()) {
      print("success");
      return true;
    } else {
      print("failed");
      return false;
    }
  }

  bool _validatorQuantity() {
    if (_quantityBidController.text.isEmpty) {
      errorQuantity = "Quantity must be added";
      return false;
    }

    if (_isNumeric(_quantityBidController.text.trim()) == false) {
      errorQuantity = "Quantity must be a number";
      return false;
    }

    if (int.tryParse(_quantityBidController.text.trim()) == null) {
      errorQuantity = "Remove decimal point";
      return false;
    }
    if (int.parse(_quantityBidController.text.trim()) <= 0) {
      errorQuantity = "Must be Greater than 0";
      return false;
    }

    if (isProduct) {
      if (int.parse(_quantityBidController.text.trim()) >
          int.parse(product.remainingQty)) {
        errorQuantity = "More than available quantity";
        return false;
      }
    } else if (!isProduct) {
      if (int.parse(_quantityBidController.text.trim()) >
          int.parse(requirement.remainingQty)) {
        errorQuantity = "More than available quantity";
        return false;
      }
    }
    print("quantity success");
    errorQuantity = null;
    return true;
  }

  bool _validatorPrice() {
    if (_priceBidController.text.isEmpty) {
      errorPrice = "Price must be added";
      return false;
    }
    if (_isNumeric(_priceBidController.text.trim()) == false) {
      errorPrice = "Price must be a number";
      return false;
    }
    if (int.tryParse(_priceBidController.text.trim()) == null) {
      errorPrice = "Remove decimal point";
      return false;
    }
    if (int.parse(_priceBidController.text.trim()) <= 0) {
      errorPrice = "Must be Greater than 0 ";
      return false;
    }
    print("price success");
    errorPrice = null;
    return true;
  }

  bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
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
    if (_initialLoad) {
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
      if (isProduct) {
        //print("User id" + product.userId);
        this._ownerUser = await _getUser(int.parse(product.userId));
      } else {
        //print("requirement id" + requirement.userId);
        this._ownerUser = await _getUser(int.parse(requirement.userId));
      }
      if (this.userId != null) {
        this._currentUser = await _getUser(this.userId);

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
      _initialLoad = false;
    }

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
      "price": _priceBidController.text.trim(),
      "quantity": _quantityBidController.text.trim(),
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
    if (_validator()) {
      final ProgressDialog pr = ProgressDialog(context,
          type: ProgressDialogType.Normal, isDismissible: true, showLogs: true);
      pr.style(
        message: 'Sending offer...',
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
      String jsonResponse = await _uploadData();
      var data = json.decode(jsonResponse);
      print(data);
      pr.hide();
      if (data['response_code'] == 404) {
        String text = "Sorry!!!";
        String dialogMesage = "Offer request failed. Retry.....";
        String buttonMessage = "Ok!!";
        // _showMyDialog(text, dialogMesage, buttonMessage);
        CustomDialog.openDialog(
                context: context,
                title: text,
                message: dialogMesage,
                mainIcon: Icons.close,
                subIcon: Icons.error)
            .then((value) => () {
                  FocusManager.instance.primaryFocus.unfocus();
                  Navigator.of(context).pop();
                });
      } else if (data['response_code'] == 405) {
        String text = "Sorry!!!";
        String dialogMesage =
            "You have not listed any product of ${category.name}";
        String buttonMessage = "Ok!!";
        CustomDialog.openDialog(
                context: context,
                title: text,
                message: dialogMesage,
                mainIcon: Icons.close,
                subIcon: Icons.error)
            .then((value) => () {
                  FocusManager.instance.primaryFocus.unfocus();
                  Navigator.of(context).pop();
                });
      } else if (data['response_code'] == 406) {
        String text = "Sorry!!!";
        String dialogMesage =
            "You do not have sufficient quantity of ${category.name}";
        String buttonMessage = "Ok!!";
        CustomDialog.openDialog(
                context: context,
                title: text,
                message: dialogMesage,
                mainIcon: Icons.close,
                subIcon: Icons.error)
            .then((value) => () {
                  FocusManager.instance.primaryFocus.unfocus();
                  Navigator.of(context).pop();
                });
      } else if (data['response_code'] == 100) {
        String text = "Congratulations!!!";
        String dialogMesage = "Offer sent successfully.";
        String buttonMessage = "Done";
        CustomDialog.openDialog(
                context: context,
                title: text,
                message: dialogMesage,
                mainIcon: Icons.close,
                subIcon: HandShakeIcon.handshake)
            .then((value) => () {
                  FocusManager.instance.primaryFocus.unfocus();
                  Navigator.of(context).pop();
                });
        //Navigator.pop(context);
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
          title: Text(title,
              style: Theme.of(context).textTheme.bodyText1.apply(
                    color: Theme.of(context).primaryColor,
                  )),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  child: Text(buttonMessage,
                      style: Theme.of(context).textTheme.bodyText2.apply(
                            color: Colors.white,
                          )),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    FocusManager.instance.primaryFocus.unfocus();
                    Navigator.of(context).pop();
                  },
                ),
              ],
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
      style: Theme.of(context).textTheme.bodyText2.apply(),
    );
  }

  void _checkUserIsLoggedIn() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE) == null) {
      Navigator.of(context).pushReplacementNamed(SingUpScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    double _detlaValue = 0;
    final data = MediaQuery.of(context);
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    final appBar = AppBar(
      title: Text(AppLocalizations.of(context).translate('Trade Details'),
          style: Theme.of(context).textTheme.headline1.apply(
                color: Colors.white,
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
              return Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return SingleChildScrollView(
              child: Container(
                height: height,
                width: width,
                child: Column(
                  children: <Widget>[
                    Container(
                      height: isSeller
                          ? data.size.height * 0.25
                          : data.size.height * 0.30,
                      width: data.size.width,
                      margin: EdgeInsets.all(data.size.width * 0.02),
                      child: Card(
                        child: FittedBox(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  isSeller
                                      ? GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) {
                                                  return DetailScreen(
                                                    tag: "qualityCertificate",
                                                    url: Utils.URL +
                                                        "images/" +
                                                        category.imgPath,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              Utils.URL +
                                                  "images/" +
                                                  category.imgPath,
                                            ),
                                            backgroundColor: Colors.grey[200],
                                            radius: data.size.height * 0.06,
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) {
                                                  return DetailScreen(
                                                    tag: "qualityCertificate",
                                                    url: Utils.URL +
                                                        "productImage/" +
                                                        product.image,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              Utils.URL +
                                                  "productImage/" +
                                                  product.image,
                                            ),
                                            backgroundColor: Colors.grey[200],
                                            radius: data.size.height * 0.06,
                                          ),
                                        ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
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
                                        if (!isSeller)
                                          firstCardInnerRow(
                                            this.userId == null && !isSeller
                                                ? "0"
                                                : _deliveryAmount.toString(),
                                            context,
                                            TextDirection.rtl,
                                          ),
                                        if (!isSeller)
                                          firstCardInnerRow(
                                            "0",
                                            context,
                                            TextDirection.rtl,
                                          ),
                                        if (!isSeller)
                                          firstCardInnerRow(
                                            "0",
                                            context,
                                            TextDirection.rtl,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                        color: Colors.grey[200],
                      ),
                    ),
                    Container(
                      height: height * 0.1,
                      width: width,
                      margin: EdgeInsets.all(data.size.width * 0.02),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0)),
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
                                      MYBaazar.balance,
                                      color: Theme.of(context).primaryColor,
                                      size: 20.0,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 1.0),
                                      child: isProduct
                                          ? Text(product.remainingQty,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline2
                                                  .apply(
                                                    fontSizeFactor:
                                                        MediaQuery.of(context)
                                                            .textScaleFactor,
                                                    fontSizeDelta: _detlaValue,
                                                  ))
                                          : Text(
                                              requirement.remainingQty + "QTL",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline2
                                                  .apply(
                                                    fontSizeFactor:
                                                        MediaQuery.of(context)
                                                            .textScaleFactor,
                                                    fontSizeDelta: _detlaValue,
                                                  )),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: 8.0),
                                  child: Text('Available',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline2
                                          .apply(
                                            fontSizeFactor:
                                                MediaQuery.of(context)
                                                    .textScaleFactor,
                                            fontSizeDelta: _detlaValue,
                                          )),
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
                                        MYBaazar.rupee_indian,
                                        color: Theme.of(context).primaryColor,
                                        size: 20.0,
                                      ),
                                      isProduct
                                          ? Text(
                                              product.price_expected,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline2
                                                  .apply(
                                                    fontSizeFactor:
                                                        MediaQuery.of(context)
                                                            .textScaleFactor,
                                                    fontSizeDelta: _detlaValue,
                                                  ),
                                            )
                                          : Text(
                                              requirement.price_expected,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline2
                                                  .apply(
                                                    fontSizeFactor:
                                                        MediaQuery.of(context)
                                                            .textScaleFactor,
                                                    fontSizeDelta: _detlaValue,
                                                  ),
                                            ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      'Offer/QTL',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline2
                                          .apply(
                                            fontSizeFactor:
                                                MediaQuery.of(context)
                                                    .textScaleFactor,
                                            fontSizeDelta: _detlaValue,
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
                                      MYBaazar.balance,
                                      color: Theme.of(context).primaryColor,
                                      size: 20.0,
                                    ),
                                    isProduct
                                        ? Text(
                                            product.quantity,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline2
                                                .apply(
                                                  fontSizeFactor:
                                                      MediaQuery.of(context)
                                                          .textScaleFactor,
                                                  fontSizeDelta: _detlaValue,
                                                ),
                                          )
                                        : Text(
                                            requirement.quantity + "QTL",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline2
                                                .apply(
                                                  fontSizeFactor:
                                                      MediaQuery.of(context)
                                                          .textScaleFactor,
                                                  fontSizeDelta: _detlaValue,
                                                ),
                                          ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Text('Total',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline2
                                            .apply(
                                              fontSizeFactor:
                                                  MediaQuery.of(context)
                                                      .textScaleFactor,
                                              fontWeightDelta: -1,
                                              fontSizeDelta: _detlaValue,
                                            )),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        color: Colors.grey[200],
                      ),
                    ),
                    if (isProduct && product.qualityCertificate != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) {
                                return DetailScreen(
                                    tag: "qualityCertificate",
                                    url:
                                        "${Utils.URL}qualityCertificate/${product.qualityCertificate}");
                              },
                            ),
                          );
                        },
                        child: Container(
                          height: height * 0.2,
                          width: width * 0.9,
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
                      ),
                    Container(
                      height: height * 0.25,
                      width: width,
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
                                        icon: MYBaazar.balance,
                                        titype: TextInputType.number,
                                        htext:
                                            errorQuantity == null ? "QTY" : "",
                                        mdata: data,
                                        controller: _quantityBidController,
                                        width: data.size.width * 0.3,
                                        errorText: errorQuantity,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: TextInputCard(
                                        icon: MYBaazar.rupee_indian,
                                        titype: TextInputType.number,
                                        htext:
                                            errorPrice == null ? "Price" : "",
                                        mdata: data,
                                        controller: _priceBidController,
                                        width: data.size.width * 0.3,
                                        errorText: errorPrice,
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
                                    disabledColor:
                                        Theme.of(context).primaryColorLight,
                                    onPressed: userId == null
                                        ? _checkUserIsLoggedIn
                                        : () {
                                            setState(() {
                                              FocusScope.of(context).unfocus();
                                              _submitData();
                                            });
                                          },
                                    child: Text(
                                        userId == null
                                            ? "Login Required"
                                            : 'Send Offer',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .apply(
                                              color: this.userId == null
                                                  ? Colors.redAccent
                                                  : Theme.of(context)
                                                      .primaryColor,
                                            )),
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
          }),
    );
  }
}
