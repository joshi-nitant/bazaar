import 'dart:convert';

import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/prod_bid.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement.dart';
import 'package:baazar/models/requirement_bid.dart';
import 'package:baazar/models/transaction.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/error_screen.dart';
import 'package:baazar/screens/payment_screen.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:baazar/widgets/button_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:baazar/classes/app_localizations.dart';

class CurrentTransaction extends StatefulWidget {
  static const String routeName = "/currentTransaction";

  @override
  _CurrentTransactionState createState() => _CurrentTransactionState();
}

class _CurrentTransactionState extends State<CurrentTransaction> {
  //List<Transaction> _transactionList = [];
  bool _isSeller;
  int _userId;
  final formatter = new NumberFormat("#,###");
  bool _isProduct;
  double _TRANSACTION_CHARGE_PERCENTAGE;
  double _DELIVERY_CHARGE_PER_KM;

  _getCategoryList() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String jsonString = sharedPreferences
        .getString(CategoryScreen.CATEGORY_LIST_SHARED_PREFERENCE);
    return jsonString;
  }

  Future<Category> _getCategory(String id) async {
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
    Category category = categoryList.firstWhere((element) => element.id == id,
        orElse: () => null);
    return category;
  }

  Future<bool> _checkIsSeller() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences
        .getBool(CheckUserScreen.USER_TYPE_SHARED_PREFERENCE);
  }

  Future<int> _getUserId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE);
  }

  Future<List<Transaction>> _getPendingTransaction() async {
    List<Transaction> _pendingTransactions = [];
    _userId = await _getUserId();
    if (_userId == null) {
      return _pendingTransactions;
    }
    _isSeller = await _checkIsSeller();

    var response = await http.post(
      Utils.URL + "getPendingTransactions.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'isSeller': _isSeller.toString(),
          'user_id': _userId.toString(),
        },
      ),
    );
    print(response.body);
    var jsondata = json.decode(response.body);

    if (jsondata.length == 0) {
      return _pendingTransactions;
    }

    ///setting the charges
    _DELIVERY_CHARGE_PER_KM = double.parse(jsondata['DELIVERY_CHARGE_PER_KM']);
    _TRANSACTION_CHARGE_PERCENTAGE =
        double.parse(jsondata['TRANSACTION_CHARGE_PERCENTAGE']);

    //print("Delivery charges = " + _DELIVERY_CHARGE_PER_KM.toString());

    if (jsondata['transaction_requirement'] != null) {
      _isProduct = false;

      for (var u in jsondata['transaction_requirement']) {
        Requirement requirement = Requirement(
          id: u['req_id'],
          quantity: u['quantity'],
          price_expected: u['price_expected'],
          breed: u['breed'],
          category_id: u['category'],
          remainingQty: u['remaining_qty'],
          category: await _getCategory(u['category']),
          userId: u['user_id'],
        );
        print(requirement.id);
        RequirementBid bid = RequirementBid(
          reqBidId: int.parse(u['req_bid_id']),
          userId: int.parse(u['bid_user_id']),
          reqId: requirement,
          price: double.parse(u['bid_price']),
          quantity: int.parse(u['bid_quantity']),
          isAccepted: u['is_accepted'] == "1",
          bidDays: int.parse(u['delivery_days']),
          packagingCharges: double.parse(u['packaging_charges']),
        );
        print(bid.reqId);
        Transaction transaction = Transaction(
          transactionId: int.parse(u['transaction_id']),
          isProdBidId: false,
          buyerId: int.parse(u['buyer_id']),
          sellerId: int.parse(u['seller_id']),
          reqbidId: bid,
          endDate: DateTime.parse(u['end_date']),
          deliveryStauts: int.parse(u['delivery_status']),
        );
        print(transaction);
        _pendingTransactions.add(transaction);
      }
    }
    print(_pendingTransactions.length);

    if (jsondata['transaction_product'] != null) {
      _isProduct = true;
      for (var u in jsondata['transaction_product']) {
        Product product = Product(
          id: u['prod_id'],
          quantity: u['quantity'],
          price_expected: u['price_expected'],
          breed: u['breed'],
          category_id: u['category_id'],
          remainingQty: u['remaining_qty'],
          image: u['image'],
          address: u['address'],
          qualityCertificate: u['quality_certificate'],
          category: await _getCategory(u['category_id']),
          userId: u['user_id'],
        );
        print(u['prod_bid_id']);
        ProductBid bid = ProductBid(
          prodBidId: int.parse(u['prod_bid_id']),
          userId: int.parse(u['bid_user_id']),
          prodId: product,
          price: double.parse(u['bid_price']),
          quantity: int.parse(u['bid_quantity']),
          isAccepted: u['is_accepted'] == "1",
          bidDays: int.parse(u['delivery_days']),
          packagingCharges: double.parse(u['packaging_charges']),
        );
        print(bid.prodId);
        Transaction transaction = Transaction(
          transactionId: int.parse(u['transaction_id']),
          isProdBidId: true,
          buyerId: int.parse(u['buyer_id']),
          sellerId: int.parse(u['seller_id']),
          productBidId: bid,
          endDate: DateTime.parse(u['end_date']),
          deliveryStauts: int.parse(u['delivery_status']),
        );

        _pendingTransactions.add(transaction);
      }
    }
    print(_pendingTransactions.length);
    return _pendingTransactions;
  }

  int _getTotalAmount(dynamic transaction) {
    Transaction tn = transaction as Transaction;
    if (tn.isProdBidId) {
      return (tn.productBidId.quantity * tn.productBidId.price).toInt();
    } else {
      return (tn.reqbidId.quantity * tn.reqbidId.price).toInt();
    }
  }

  String _getTitle(dynamic transaction) {
    Transaction tn = transaction as Transaction;

    if (tn.isProdBidId) {
      return tn.productBidId.prodId.category.name;
    } else {
      return tn.reqbidId.reqId.category.name;
    }
  }

  String _getBreed(dynamic transaction) {
    Transaction tn = transaction as Transaction;
    if (tn.isProdBidId) {
      return tn.productBidId.prodId.breed;
    } else {
      return tn.reqbidId.reqId.breed;
    }
  }

  NetworkImage _getImage(dynamic transaction) {
    Transaction tn = transaction as Transaction;

    if (tn.isProdBidId) {
      return NetworkImage(
          "${Utils.URL}images/${tn.productBidId.prodId.category.imgPath}");
    } else if (tn.reqbidId != null) {
      return NetworkImage(
          "${Utils.URL}images/${tn.reqbidId.reqId.category.imgPath}");
    }
  }

  void _procedToCheckout(dynamic object) {
    Transaction tn = object as Transaction;
    print(tn.productBidId);
    print(tn.reqbidId);

    if (tn.productBidId != null) {
      Navigator.of(context).pushNamed(
        PaymentScreen.routeName,
        arguments: {
          'bid_object': tn.productBidId,
          'transaction_id': tn.transactionId,
          'TRANSACTION_CHARGE_PERCENTAGE': _TRANSACTION_CHARGE_PERCENTAGE,
          'DELIVERY_CHARGE_PER_KM': _DELIVERY_CHARGE_PER_KM,
          'end_date': tn.endDate,
          'delivery_status': tn.deliveryStauts,
        },
      ).then((value) => setState(() {}));
    } else if (tn.reqbidId != null) {
      Navigator.of(context).pushNamed(
        PaymentScreen.routeName,
        arguments: {
          'bid_object': tn.reqbidId,
          'transaction_id': tn.transactionId,
          'TRANSACTION_CHARGE_PERCENTAGE': _TRANSACTION_CHARGE_PERCENTAGE,
          'DELIVERY_CHARGE_PER_KM': _DELIVERY_CHARGE_PER_KM,
          'end_date': tn.endDate,
          'delivery_status': tn.deliveryStauts,
        },
      ).then(
        (value) => setState(() {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final curr = MediaQuery.of(context).textScaleFactor;
    final appBar = AppBar(
      titleSpacing: 0,
      title: Row(
        children: <Widget>[
          Icon(Icons.history),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              AppLocalizations.of(context).translate('Current Transaction'),
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
      backgroundColor: Colors.white,
      appBar: appBar,
      body: FutureBuilder(
        future: _getPendingTransaction(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.data.length == 0) {
            return NoProduct("CURRENT TRANSACTION");
          }
          return Container(
            height: height,
            width: width,
            margin: EdgeInsets.all(5.0),
            child: Card(
              color: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Utils.BORDER_RADIUS_CARD)),
              child: ListView.builder(
                itemBuilder: (ctx, index) {
                  return GestureDetector(
                    onTap: () {
                      _procedToCheckout(snapshot.data[index]);
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        //contentPadding: EdgeInsets.only(bottom: 10),
                        //isThreeLine: true,
                        leading: Container(
                          margin: EdgeInsets.only(left: 0),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: _getImage(snapshot.data[index]),
                            backgroundColor: Colors.grey[300],
                          ),
                        ),

                        title: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Container(
                            width: width * 0.9,
                            child: Padding(
                              padding: _isSeller
                                  ? const EdgeInsets.all(0.0)
                                  : const EdgeInsets.all(0.0),
                              child: Text(
                                _getTitle(snapshot.data[index]),
                                style: Theme.of(context).textTheme.bodyText1,
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                        ),
                        contentPadding: EdgeInsets.all(0.0),
                        subtitle: _isSeller
                            ? Padding(
                                padding: _isSeller
                                    ? const EdgeInsets.all(0.0)
                                    : const EdgeInsets.all(0.0),
                                child: FittedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      "Pending transaction of \u20B9${formatter.format(_getTotalAmount(snapshot.data[index]))}",
                                      //"Pending transaction of \u20B9${formatter.format(1234567)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText2
                                          .apply(
                                            fontSizeDelta: -4,
                                          ),
                                      textAlign: TextAlign.start,
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 0.2,
                                child: FittedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      "Pending transaction of \u20B9${formatter.format(_getTotalAmount(snapshot.data[index]))}",
                                      //"Pending transaction of \u20B9${formatter.format(1234567)}",
                                      style:
                                          Theme.of(context).textTheme.bodyText2,
                                      textAlign: TextAlign.start,
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                              ),

                        trailing: !_isSeller
                            ? Container(
                                width: width * 0.3,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(25.0)),
                                  child: Container(
                                    height: 55,
                                    width:
                                        MediaQuery.of(context).size.width * 0.2,
                                    child: FlatButton.icon(
                                      icon: Icon(
                                        Icons.exit_to_app,
                                        color: Colors.white,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(32.0),
                                      ),
                                      color: Theme.of(context).primaryColor,
                                      textColor: Colors.white,
                                      padding: EdgeInsets.all(8.0),
                                      onPressed: () {
                                        _procedToCheckout(snapshot.data[index]);
                                      },
                                      label: FittedBox(
                                        child: Text(
                                          "Pay",
                                          overflow: TextOverflow.fade,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline2
                                              .apply(
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox(),
                      ),
                    ),
                  );
                },
                itemCount: snapshot.data.length,
              ),
            ),
          );
        },
      ),
    );
  }
}
