import 'dart:convert';
import 'dart:ffi';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/prod_bid.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement_bid.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/widgets/dialog_widget.dart';
import 'package:baazar/widgets/hand_shake_icon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart' as intl;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'manage_offer_screen.dart';

class PaymentScreen extends StatefulWidget {
  static String routeName = "/payment";
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  RequirementBid _requirementBid;
  ProductBid _productBid;

  int _buyerId;
  int _deliveryAmount;
  int _packagingAmount;
  int _transactionAmount;
  double _distance;
  int _costPerKm = 10;
  User _buyer;
  User _seller;
  String _addressText;
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: Utils.API_KEY);
  LatLng _buyerCoordinate;
  LatLng _sellerCoordinate;
  bool _isFirstLoading = true;
  Razorpay razorpay;
  bool _isReqBid;
  int _productCharge;
  int _transactionId;
  final formatter = new intl.NumberFormat("#,###");

  @override
  void initState() {
    super.initState();

    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _paymentSucess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _paymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _wallet);
  }

  @override
  void dispose() {
    super.dispose();
    razorpay.clear();
  }

  void _openCheckout() {
    var options = {
      "key": Utils.PAYMENT_KEY,
      "amount": _getTotalAmount() * 100,
      "name": "Baazar",
      "description": "Payment for the product",
      "prefill": {"contact": _buyer.contactNumber, "email": ""},
      "external": {
        "wallets": ["paytm"]
      }
    };

    try {
      razorpay.open(options);
    } catch (e) {
      print(e);
    }
  }

  void _paymentSucess(PaymentSuccessResponse res) async {
    String data = await _sendPaymentDetails(res);
    print(data);
    Navigator.of(context).pop();
    if (data == "101") {
      String text = "Payment Successfull";
      String dialogMessage = "Congratulations your payment is successfull";

      await CustomDialog.openDialog(
          context: context,
          title: text,
          message: dialogMessage,
          mainIcon: Icons.check,
          subIcon: HandShakeIcon.handshake);
    }
  }

  Future<String> _sendPaymentDetails(PaymentSuccessResponse res) async {
    var response = await http.post(
      Utils.URL + "transactionCompleted.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'transaction_id': _transactionId.toString(),
          'delivery_address': _buyer.address,
          'total_amount': _getTotalAmount().toString(),
          'product_amount': _productCharge.toString(),
          'transaction_charge': _transactionAmount.toString(),
          'packaging_charge': _packagingAmount.toString(),
          'delivery_charge': _deliveryAmount.toString(),
          'razorpay_payment_id': res.paymentId,
          'razorpay_order_id': res.orderId,
          'razorpay_signature': res.signature,
        },
      ),
    );
    print(response.body);
    return json.decode(response.body);
  }

  void _paymentError() {
    print('Error');
  }

  void _wallet() {
    print('wallet');
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

  Future<dynamic> _loadCatAndUserType() async {
    if (_isFirstLoading) {
      var routeArgs =
          ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
      dynamic bidObject = routeArgs['bid_object'];
      _transactionId = routeArgs['transaction_id'];
      if (bidObject is RequirementBid) {
        _requirementBid = bidObject;
        _isReqBid = true;
      } else {
        _productBid = bidObject;
        _isReqBid = false;
      }

      _buyerId = await _getUserId();
      if (_buyerId != null) {
        this._buyer = await _getUser(_buyerId);

        if (_isReqBid) {
          this._seller = await _getUser(_requirementBid.userId);
        } else {
          this._seller = await _getUser(int.parse(_productBid.prodId.userId));
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
        _transactionAmount = (_deliveryAmount * 3) ~/ 100;
        _packagingAmount = 30;
        if (_isReqBid) {
          _productCharge =
              (_requirementBid.price * _requirementBid.quantity).toInt();
        } else {
          _productCharge = (_productBid.price * _productBid.quantity).toInt();
        }
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
        _requirementBid.reqId.category = categoryList.firstWhere(
            (element) => element.id == _requirementBid.reqId.category_id,
            orElse: () => null);
      } else {
        _productBid.prodId.category = categoryList.firstWhere(
            (element) => element.id == _productBid.prodId.category_id,
            orElse: () => null);
      }

      _isFirstLoading = false;
    }

    if (_isReqBid) {
      return _requirementBid;
    } else {
      return _productBid;
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
    return distance * 10;
  }

  int _getTotalAmount() {
    return _deliveryAmount +
        _transactionAmount +
        _packagingAmount +
        _productCharge;
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
      print(address.toString());
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

  Future<void> _clickHandler() async {
    _buyer = await _getLocation();

    if (_buyer != null) {
      _buyerCoordinate = LatLng(
        double.parse(_buyer.latitude),
        double.parse(_buyer.longitude),
      );
      _distance = await _getDistance(_buyerCoordinate, _sellerCoordinate);
      _deliveryAmount = _getDeliveryAmount(_distance).toInt();
      setState(() {});
    }
  }

  String _getImage(dynamic object) {
    if (_isReqBid) {
      return "${Utils.URL}/images/${object.reqId.category.imgPath}";
    } else {
      object = object as ProductBid;
      return "${Utils.URL}/productImage/${object.prodId.image}";
    }
  }

  String _getCategoryname(dynamic object) {
    if (_isReqBid) {
      return "${_requirementBid.reqId.category.name}";
    } else {
      object = object as ProductBid;
      return "${_productBid.prodId.category.name}";
    }
  }

  String _getBreed(dynamic object) {
    if (_isReqBid) {
      return "${_requirementBid.reqId.breed}";
    } else {
      object = object as ProductBid;
      return "${_productBid.prodId.breed}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('Checkout'),
          style: Theme.of(context).textTheme.headline1.apply(
                color: Colors.white,
                letterSpacingDelta: -5,
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(bottom: 8.0),
                      width: data.size.width,
                      height: data.size.height * 0.30,
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
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            _getImage(snapshot.data),
                                          ),
                                          backgroundColor: Colors.white,
                                          radius: 45.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        largeText(context,
                                            _getCategoryname(snapshot.data)),
                                        normalText(context,
                                            "${_seller.city},${_seller.state}"),
                                        normalText(
                                            context, _getBreed(snapshot.data)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
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
                                                BorderRadius.circular(32.0)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Icon(Icons.location_on,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                              SizedBox(width: 10.0),
                                              Expanded(
                                                child: Text(
                                                  _buyer.address,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText2,
                                                  textAlign: TextAlign.center,
                                                  //overflow: TextOverflow.clip,
                                                  //maxLines: 5,
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
                            borderRadius: BorderRadius.circular(32.0)),
                      ),
                    ),
                    Container(
                      width: data.size.width,
                      height: data.size.height * 0.3,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    normalText(context, 'Product Charge : '),
                                    normalText(context, 'Delivery Charge : '),
                                    normalText(
                                        context, 'Transaction Charge : '),
                                    normalText(context, 'Package Charge : '),
                                    SizedBox(height: 15.0),
                                    largeText(context, 'Total Charge : '),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    normalText(context,
                                        formatter.format(_productCharge)),
                                    normalText(context,
                                        formatter.format(_deliveryAmount)),
                                    normalText(context,
                                        formatter.format(_transactionAmount)),
                                    normalText(context,
                                        formatter.format(_packagingAmount)),
                                    SizedBox(height: 15.0),
                                    largeText(context,
                                        formatter.format(_getTotalAmount())),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0)),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      height: 55,
                      width: data.size.width,
                      child: FlatButton(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              side: BorderSide(
                                  color: Theme.of(context).primaryColor)),
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(8.0),
                          onPressed: () {
                            _openCheckout();
                          },
                          child: Text(
                            AppLocalizations.of(context).translate("Checkout"),
                            style: Theme.of(context).textTheme.bodyText1.apply(
                                  color: Colors.white,
                                ),
                          )),
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
