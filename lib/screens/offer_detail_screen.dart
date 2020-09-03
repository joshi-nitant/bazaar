import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/prod_bid.dart';
import 'package:baazar/models/requirement_bid.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/error_screen.dart';
import 'package:baazar/screens/manage_offer_screen.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart' as intl;
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfferDetailScreen extends StatefulWidget {
  static final String routeName = "/offerDetail";
  @override
  _OfferDetailScreenState createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  ProductBid productBid;
  RequirementBid requirementBid;
  bool _isReqBid;
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: Utils.API_KEY);
  final formatter = new intl.NumberFormat("#,###");
  User _buyer;
  User _seller;
  LatLng _buyerCoordinate;
  LatLng _sellerCoordinate;
  double _TRANSACTION_CHARGE_PERCENTAGE;
  double _DELIVERY_CHARGE_PER_KM;
  int _productCharge;
  bool _isFirstLoading = true;
  int _deliveryAmount;
  int _packagingAmount;
  int _transactionAmount;
  double _distance;
  var _addressText;
  Function _deleteItem, _selectItem;
  bool _isSeller;

  String _getImage() {
    if (_isReqBid) {
      return "${Utils.URL}/images/${requirementBid.reqId.category.imgPath}";
    } else {
      return "${Utils.URL}/productImage/${productBid.prodId.image}";
    }
  }

  String _getCategoryname() {
    if (_isReqBid) {
      return "${requirementBid.reqId.category.name}";
    } else {
      return "${productBid.prodId.category.name}";
    }
  }

  String _getCity() {
    if (_isReqBid) {
      return "${requirementBid.seller.city}";
    } else {
      return "${productBid.buyer.city}";
    }
  }

  String _getBreed() {
    if (_isReqBid) {
      return "${requirementBid.reqId.breed}";
    } else {
      return "${productBid.prodId.breed}";
    }
  }

  Future<void> _clickHandler() async {
    var _setbuyer = await _getLocation();

    if (_setbuyer != null) {
      _buyerCoordinate = LatLng(
        double.parse(_setbuyer.latitude),
        double.parse(_setbuyer.longitude),
      );
      _distance = await _getDistance(_buyerCoordinate, _sellerCoordinate);
      _deliveryAmount = _getDeliveryAmount(_distance).toInt();
      setState(() {
        _buyer = _setbuyer;
      });
    }
  }

  Future<User> _getLocation() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: Utils.API_KEY,
      mode: Mode.overlay, // Mode.fullscreen
      language: "en",
      components: [new Component(Component.country, "in")],
    );
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
    return await displayPrediction(p);
  }

  Future<User> displayPrediction(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);

      double lat = detail.result.geometry.location.lat;
      double lng = detail.result.geometry.location.lng;

      print(p.description);
      var address = await Geocoder.local.findAddressesFromQuery(p.description);

      var _selectedAddress = address.first;

      _buyer.address = _selectedAddress.addressLine;
      _buyer.latitude = lat.toString();
      _buyer.longitude = lng.toString();
      _buyer.pincode = _selectedAddress.postalCode;
      _buyer.state = _selectedAddress.adminArea;
      _buyer.city = _selectedAddress.locality;

      return _buyer;
    }
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

  Future<bool> _checkIsSeller() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences
        .getBool(CheckUserScreen.USER_TYPE_SHARED_PREFERENCE);
  }

  _getUserId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    int _userId = sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE);
    return _userId;
  }

  _getCategoryList() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String jsonString = sharedPreferences
        .getString(CategoryScreen.CATEGORY_LIST_SHARED_PREFERENCE);
    return jsonString;
  }

  Future<dynamic> _loadCatAndUserType() async {
    if (_isFirstLoading) {
      _isSeller = await _checkIsSeller();
      if (_isReqBid) {
        var _buyerId = await _getUserId();
        _buyer = await _getUser(_buyerId);
        _seller = await _getUser(requirementBid.userId);
      } else {
        _buyer = await _getUser(productBid.userId);
        var _sellerId = await _getUserId();
        _seller = await _getUser(_sellerId);
      }
      _buyerCoordinate = LatLng(
        double.parse(_buyer.latitude),
        double.parse(_buyer.longitude),
      );
      _sellerCoordinate = LatLng(
        double.parse(_seller.latitude),
        double.parse(_seller.longitude),
      );
      _distance = await _getDistance(_buyerCoordinate, _sellerCoordinate);
      _deliveryAmount = _getDeliveryAmount(_distance).toInt();

      if (_isReqBid) {
        _packagingAmount = (requirementBid.packagingCharges).toInt();
      } else {
        _packagingAmount = (productBid.packagingCharges).toInt();
      }

      if (_isReqBid) {
        _productCharge =
            (requirementBid.price * requirementBid.quantity).toInt();
      } else {
        _productCharge = (productBid.price * productBid.quantity).toInt();
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
      _addressText = _buyer.address;
      if (_isReqBid) {
        requirementBid.reqId.category = categoryList.firstWhere(
            (element) => element.id == requirementBid.reqId.category_id,
            orElse: () => null);
      } else {
        productBid.prodId.category = categoryList.firstWhere(
            (element) => element.id == productBid.prodId.category_id,
            orElse: () => null);
      }

      _isFirstLoading = false;
      _transactionAmount = _getTransactionAmount();
    }
    if (_isReqBid) {
      return requirementBid;
    } else {
      return productBid;
    }
  }

  Future<double> _getDistance(
      LatLng startCoordinates, LatLng destinationCoordinates) async {
    double distanceInMeters = await Geolocator().distanceBetween(
      startCoordinates.latitude,
      startCoordinates.longitude,
      destinationCoordinates.latitude,
      destinationCoordinates.longitude,
    );
    return distanceInMeters / 1000;
  }

  double _getDeliveryAmount(double distance) {
    return distance * _DELIVERY_CHARGE_PER_KM;
  }

  int _getTransactionAmount() {
    return ((_productCharge +
                _packagingAmount +
                _deliveryAmount * _TRANSACTION_CHARGE_PERCENTAGE) /
            100)
        .toInt();
  }

  int _getTotalAmount() {
    return _deliveryAmount +
        _transactionAmount +
        _packagingAmount +
        _productCharge;
  }

  double _getBidPrice() {
    if (_isReqBid) {
      return requirementBid.price;
    } else {
      return productBid.price;
    }
  }

  int _getBidQuantity() {
    if (_isReqBid) {
      return requirementBid.quantity;
    } else {
      return productBid.quantity;
    }
  }

  dynamic _getBidItem() {
    if (_isReqBid) {
      return requirementBid;
    } else {
      return productBid;
    }
  }

  int _getDays() {
    if (_isReqBid) {
      return requirementBid.bidDays;
    } else {
      return productBid.bidDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    var data =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    if (data['bid_object'] is ProductBid) {
      productBid = data['bid_object'];
      _isReqBid = false;
    } else if (data['bid_object'] is RequirementBid) {
      requirementBid = data['bid_object'];
      _isReqBid = true;
    }
    _TRANSACTION_CHARGE_PERCENTAGE = data['TRANSACTION_CHARGE_PERCENTAGE'];
    _DELIVERY_CHARGE_PER_KM = data['DELIVERY_CHARGE_PER_KM'];
    _selectItem = data['accept_handler'];
    _deleteItem = data['delete_handler'];

    final curr = MediaQuery.of(context).textScaleFactor;
    final appBar = AppBar(
      titleSpacing: 0,
      title: Row(
        children: <Widget>[
          Icon(Icons.people),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              AppLocalizations.of(context).translate('Manage Offer'),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 8.0),
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(bottom: 2.0),
                          width: width,
                          height: _isSeller ? height * 0.20 : height * 0.35,
                          child: Card(
                            color: Colors.grey[200],
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Card(
                                              child: CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                  _getImage(),
                                                ),
                                                backgroundColor:
                                                    Colors.grey[300],
                                                radius: 45.0,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              shadowColor: Colors.grey[300],
                                              elevation: 5.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              child: largeText(
                                                  context, _getCategoryname()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              child: normalText(
                                                  context, _getCity()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              child: normalText(
                                                  context, _getBreed()),
                                            ),
                                            if (!_isSeller)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: normalText(
                                                    context,
                                                    AppLocalizations.of(context)
                                                        .translate(
                                                            "Delivery Address")),
                                              ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                if (!_isSeller)
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _clickHandler,
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          32.0)),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Icon(Icons.location_on,
                                                        color: Theme.of(context)
                                                            .primaryColor),
                                                    SizedBox(width: 10.0),
                                                    Expanded(
                                                      child:
                                                          SingleChildScrollView(
                                                        child: Text(
                                                          _buyer.address,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyText2,
                                                          textAlign:
                                                              TextAlign.center,
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
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    Utils.BORDER_RADIUS_CARD)),
                          ),
                        ),
                        Container(
                          width: width,
                          height: _isSeller ? height * 0.3 : height * 0.4,
                          child: Card(
                            color: Colors.grey[200],
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        normalText(context, 'Bid Price : '),
                                        normalText(context, 'Bid Quantity : '),
                                        if (!_isSeller)
                                          normalText(
                                              context, 'Product Charge : '),
                                        if (!_isSeller)
                                          normalText(
                                              context, 'Delivery Charge : '),
                                        if (!_isSeller)
                                          normalText(
                                              context, 'Transaction Charge : '),
                                        if (!_isSeller)
                                          normalText(
                                              context, 'Package Charge : '),
                                        SizedBox(height: 15.0),
                                        !_isSeller
                                            ? largeText(
                                                context, 'Total Charge : ')
                                            : largeText(
                                                context, 'Total Earning : '),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        normalText(
                                            context,
                                            formatter.format(_getBidPrice()) +
                                                "/QTL"),
                                        normalText(
                                            context,
                                            formatter
                                                    .format(_getBidQuantity()) +
                                                " QTL"),
                                        if (!_isSeller)
                                          normalText(
                                              context,
                                              formatter.format(_productCharge) +
                                                  "\u20b9"),
                                        if (!_isSeller)
                                          normalText(
                                              context,
                                              formatter
                                                      .format(_deliveryAmount) +
                                                  "\u20b9"),
                                        if (!_isSeller)
                                          normalText(
                                              context,
                                              formatter.format(
                                                      _transactionAmount) +
                                                  "\u20b9"),
                                        if (!_isSeller)
                                          normalText(
                                              context,
                                              formatter.format(
                                                      _packagingAmount) +
                                                  "\u20b9"),
                                        SizedBox(height: 15.0),
                                        !_isSeller
                                            ? largeText(
                                                context,
                                                formatter.format(
                                                        _getTotalAmount()) +
                                                    "\u20b9")
                                            : largeText(
                                                context,
                                                formatter.format(
                                                        _productCharge) +
                                                    "\u20b9")
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    Utils.BORDER_RADIUS_CARD)),
                          ),
                        ),
                        if (!_isSeller)
                          Container(
                            height: height * 0.17,
                            margin: EdgeInsets.symmetric(vertical: 2.0),
                            width: width,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      Utils.BORDER_RADIUS_CARD)),
                              color: Colors.grey[200],
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: normalText(
                                    context,
                                    "Expected time of delivery is " +
                                        _getDays().toString() +
                                        " days"),
                              ),
                            ),
                          ),
                        Container(
                          height: height * 0.15,
                          margin: EdgeInsets.symmetric(vertical: 0.0),
                          width: width * 0.5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32.0)),
                                color: Colors.grey[200],
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: ClipOval(
                                    child: Material(
                                      color: Theme.of(context)
                                          .primaryColor, // button color
                                      child: InkWell(
                                        splashColor:
                                            Colors.grey, // inkwell color
                                        child: SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 50,
                                            )),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _selectItem(_getBidItem());
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32.0)),
                                color: Colors.grey[200],
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: ClipOval(
                                    child: Material(
                                      color: Theme.of(context)
                                          .primaryColor, // button color
                                      child: InkWell(
                                        splashColor:
                                            Colors.grey, // inkwell color
                                        child: SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 50,
                                            )),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _deleteItem(_getBidItem());
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }));
  }
}
