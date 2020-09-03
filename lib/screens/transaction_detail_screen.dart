import 'dart:convert';
import 'dart:ffi';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/prod_bid.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement_bid.dart';
import 'package:baazar/models/transaction.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:baazar/widgets/dialog_widget.dart';
import 'package:baazar/widgets/hand_shake_icon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart' as intl;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'manage_offer_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  static String routeName = "/transactionDetail";
  @override
  _TransactionDetailScreenState createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  RequirementBid _requirementBid;
  ProductBid _productBid;
  User _buyer;
  User _seller;
  bool _isFirstLoading = true;
  bool _isReqBid;
  final formatter = new intl.NumberFormat("#,###");
  DateTime endDate;
  bool _isSeller = true;

  Transaction _transactionObject;

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

  int _getDays() {
    if (_isReqBid) {
      return _requirementBid.bidDays;
    } else {
      return _productBid.bidDays;
    }
  }

  String getDate(DateTime object) {
    return intl.DateFormat("dd-MM-yy").format(object);
  }

  String getTime(DateTime object) {
    return intl.DateFormat.jm().format(object);
  }

  Future<bool> _checkIsSeller() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences
        .getBool(CheckUserScreen.USER_TYPE_SHARED_PREFERENCE);
  }

  Future<dynamic> _loadCatAndUserType() async {
    if (_isFirstLoading) {
      var routeArgs =
          ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
      _transactionObject = routeArgs['transaction_object'];
      print("Id " + _transactionObject.transactionId.toString());
      endDate = routeArgs['end_date'];
      _isSeller = await _checkIsSeller();
      print("Delivery amount" + _transactionObject.deliveryAmount.toString());
      if (_transactionObject.reqbidId != null) {
        _requirementBid = _transactionObject.reqbidId;
        _isReqBid = true;
        var _buyerId = await _getUserId();
        _buyer = await _getUser(_buyerId);
        _seller = await _getUser(_requirementBid.userId);
      } else {
        _productBid = _transactionObject.productBidId;
        _buyer = await _getUser(_productBid.userId);
        var _sellerId = await _getUserId();
        _seller = await _getUser(_sellerId);
        _isReqBid = false;
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
    return _transactionObject;
  }

  String _getImage(Transaction object) {
    if (_isReqBid) {
      return "${Utils.URL}/images/${object.reqbidId.reqId.category.imgPath}";
    } else {
      return "${Utils.URL}/productImage/${object.productBidId.prodId.image}";
    }
  }

  double _getBidPrice() {
    if (_isReqBid) {
      return _requirementBid.price;
    } else {
      return _productBid.price;
    }
  }

  int _getBidQuantity() {
    if (_isReqBid) {
      return _requirementBid.quantity;
    } else {
      return _productBid.quantity;
    }
  }

  String _getCategoryname(dynamic object) {
    if (_isReqBid) {
      return "${_requirementBid.reqId.category.name}";
    } else {
      return "${_productBid.prodId.category.name}";
    }
  }

  String _getBreed(dynamic object) {
    if (_isReqBid) {
      return "${_requirementBid.reqId.breed}";
    } else {
      return "${_productBid.prodId.breed}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;

    final appBar = AppBar(
      titleSpacing: 0,
      title: Row(
        children: <Widget>[
          Icon(Icons.assignment),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              AppLocalizations.of(context).translate('Transaction History'),
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
                      width: data.size.width,
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
                                              _getImage(snapshot.data),
                                            ),
                                            backgroundColor: Colors.grey[300],
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
                                          padding: const EdgeInsets.all(3.0),
                                          child: largeText(context,
                                              _getCategoryname(snapshot.data)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: normalText(
                                              context, "${_seller.city}"),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: normalText(context,
                                              _getBreed(snapshot.data)),
                                        ),
                                        if (!_isSeller)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
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
                                        onTap: null,
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
                                                  child: SingleChildScrollView(
                                                    child: Text(
                                                      (snapshot.data
                                                              as Transaction)
                                                          .deliveryAddress,
                                                      style: Theme.of(context)
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    normalText(context, 'Bid Price : '),
                                    normalText(context, 'Bid Quantity : '),
                                    if (!_isSeller)
                                      normalText(context, 'Product Charge : '),
                                    if (!_isSeller)
                                      normalText(context, 'Delivery Charge : '),
                                    if (!_isSeller)
                                      normalText(
                                          context, 'Transaction Charge : '),
                                    if (!_isSeller)
                                      normalText(context, 'Package Charge : '),
                                    SizedBox(height: 15.0),
                                    !_isSeller
                                        ? largeText(context, 'Total Charge : ')
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    normalText(
                                        context,
                                        formatter.format(_getBidPrice()) +
                                            "/QTL"),
                                    normalText(
                                        context,
                                        formatter.format(_getBidQuantity()) +
                                            " QTL"),
                                    if (!_isSeller)
                                      normalText(
                                          context,
                                          formatter.format(
                                                  (snapshot.data as Transaction)
                                                      .productCharge) +
                                              "\u20b9"),
                                    if (!_isSeller)
                                      normalText(
                                          context,
                                          formatter.format(
                                                  (snapshot.data as Transaction)
                                                      .transactionAmount) +
                                              "\u20b9"),
                                    if (!_isSeller)
                                      normalText(
                                          context,
                                          formatter.format(
                                                  (snapshot.data as Transaction)
                                                      .transactionAmount) +
                                              "\u20b9"),
                                    if (!_isSeller)
                                      normalText(
                                          context,
                                          formatter.format(
                                                  (snapshot.data as Transaction)
                                                      .packagingAmount) +
                                              "\u20b9"),
                                    SizedBox(height: 15.0),
                                    largeText(
                                        context,
                                        formatter.format(
                                                (snapshot.data as Transaction)
                                                    .totalAmount) +
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
