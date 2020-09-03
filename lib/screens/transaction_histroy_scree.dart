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
import 'package:baazar/screens/transaction_detail_screen.dart';
import 'package:baazar/widgets/button_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:baazar/classes/app_localizations.dart';

class TransactionHistory extends StatefulWidget {
  static const String routeName = "/transactionHistory";

  @override
  _TransactionHistoryState createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  //List<Transaction> _transactionList = [];
  bool _isSeller;
  bool _isReqBid;

  int _userId;
  final _formatter = new NumberFormat("#,###");
  var _dateFormater = new DateFormat('dd-MM-yyyy hh:mm a');

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

  Future<List<Transaction>> _getCompletedTransaction() async {
    List<Transaction> _pendingTransactions = [];
    _userId = await _getUserId();

    if (_userId == null) {
      return _pendingTransactions;
    }
    _isSeller = await _checkIsSeller();

    var response = await http.post(
      Utils.URL + "transactionHistory.php",
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
    if (jsondata.length != 0) {
      if (jsondata['transaction_requirement'] != null) {
        _isReqBid = true;
        for (var u in jsondata['transaction_requirement']) {
          Requirement requirement = Requirement(
            id: u['req_id'],
            quantity: u['quantity'],
            price_expected: u['price_expected'],
            breed: u['breed'],
            category_id: u['category'],
            remainingQty: u['remaining_qty'],
            category: await _getCategory(u['category']),
          );
          RequirementBid bid = RequirementBid(
            reqBidId: int.parse(u['req_bid_id']),
            userId: int.parse(u['bid_user_id']),
            reqId: requirement,
            price: double.parse(u['bid_price']),
            quantity: int.parse(u['bid_quantity']),
            isAccepted: u['is_accepted'] == "1",
          );

          Transaction transaction = Transaction(
            transactionId: int.parse(u['transaction_id']),
            isProdBidId: false,
            buyerId: int.parse(u['buyer_id']),
            sellerId: int.parse(u['seller_id']),
            reqbidId: bid,
            endDate: DateTime.parse(u['end_date']),
            completionDate: DateTime.parse(u['complete_date']),
            totalAmount: int.parse(u['total_amount']),
            deliveryDate: DateTime.parse(u['delivery_date']),
            deliveryAddress: u['delivery_address'],
            deliveryAmount: int.parse(u['delivery_amount']),
            packagingAmount: int.parse(u['packaging_amount']),
            productCharge: int.parse(u['product_charge']),
            transactionAmount: int.parse(u['transaction_amount']),
          );
          _pendingTransactions.add(transaction);
        }
      }
      //print(_pendingTransactions.length);
      if (jsondata['transaction_product'] != null) {
        for (var u in jsondata['transaction_product']) {
          _isReqBid = false;
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
          );
          ProductBid bid = ProductBid(
            prodBidId: int.parse(u['prod_bid_id']),
            userId: int.parse(u['bid_user_id']),
            prodId: product,
            price: double.parse(u['bid_price']),
            quantity: int.parse(u['bid_quantity']),
            isAccepted: u['is_accepted'] == "1",
          );
          Transaction transaction = Transaction(
            transactionId: int.parse(u['transaction_id']),
            isProdBidId: true,
            buyerId: int.parse(u['buyer_id']),
            sellerId: int.parse(u['seller_id']),
            productBidId: bid,
            endDate: DateTime.parse(u['end_date']),
            completionDate: DateTime.parse(u['complete_date']),
            totalAmount: int.parse(u['total_amount']),
            deliveryDate: DateTime.parse(u['delivery_date']),
            deliveryAddress: u['delivery_address'],
            deliveryAmount: int.parse(u['delivery_amount']),
            packagingAmount: int.parse(u['packaging_amount']),
            productCharge: int.parse(u['product_charge']),
            transactionAmount: int.parse(u['transaction_amount']),
          );

          _pendingTransactions.add(transaction);
        }
      }
    }

    return _pendingTransactions;
  }

  // int _getTotalAmount(dynamic transaction) {
  //   Transaction tn = transaction as Transaction;
  //   if (_isSeller) {
  //     return (tn.productBidId.quantity * tn.productBidId.price).toInt();
  //   } else {
  //     return (tn.reqbidId.quantity * tn.reqbidId.price).toInt();
  //   }
  // }

  String _getTitle(dynamic transaction) {
    Transaction tn = transaction as Transaction;
    if (tn.productBidId != null) {
      return tn.productBidId.prodId.category.name;
    } else {
      return tn.reqbidId.reqId.category.name;
    }
  }

  String _getBreed(dynamic transaction) {
    Transaction tn = transaction as Transaction;
    if (tn.productBidId != null) {
      return tn.productBidId.prodId.breed;
    } else {
      return tn.reqbidId.reqId.breed;
    }
  }

  NetworkImage _getImage(dynamic transaction) {
    Transaction tn = transaction as Transaction;

    if (tn.productBidId != null) {
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
          'transaction_id': tn.transactionId
        },
      );
    } else if (tn.reqbidId != null) {
      Navigator.of(context).pushNamed(
        PaymentScreen.routeName,
        arguments: {
          'bid_object': tn.reqbidId,
          'transaction_id': tn.transactionId
        },
      ).then(
        (value) => setState(() {}),
      );
    }
  }

  String getDate(DateTime object) {
    return DateFormat("dd-MM-yy").format(object);
  }

  String getTime(DateTime object) {
    return DateFormat.jm().format(object);
  }

  void _detailTransaction(Transaction object) {
    Navigator.of(context).pushNamed(TransactionDetailScreen.routeName,
        arguments: {'transaction_object': object});
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final curr = MediaQuery.of(context).textScaleFactor;
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
      backgroundColor: Colors.white,
      appBar: appBar,
      body: FutureBuilder(
        future: _getCompletedTransaction(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.data.length == 0) {
            return NoProduct("TRANSACTION HISTORY");
          }
          return Container(
            width: width,
            height: height,
            margin: EdgeInsets.all(5),
            child: Card(
              color: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Utils.BORDER_RADIUS_CARD)),
              child: ListView.builder(
                itemBuilder: (ctx, index) {
                  return GestureDetector(
                    onTap: () {
                      _detailTransaction(snapshot.data[index]);
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Utils.BORDER_RADIUS_CARD),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        //contentPadding: EdgeInsets.only(bottom: 10),
                        //isThreeLine: true,
                        leading: Container(
                          margin: EdgeInsets.only(left: 3),
                          child: CircleAvatar(
                            radius: 30.0,
                            backgroundImage: _getImage(snapshot.data[index]),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        title: Container(
                          width: width * 0.7,
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Text(
                              _getTitle(snapshot.data[index]),
                              style: Theme.of(context).textTheme.bodyText1,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ),
                        contentPadding: EdgeInsets.all(0),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: FittedBox(
                            child: Text(
                              //"Pending transaction of \u20B9 ${_getTotalAmount(snapshot.data[index])}",
                              "Delivered on ${getDate(snapshot.data[index].deliveryDate)}",
                              //"Date\n${getDate(snapshot.data[index].completionDate)}\nTime\n${getTime(snapshot.data[index].completionDate)}",
                              style: Theme.of(context).textTheme.headline2,
                              textAlign: TextAlign.start,
                              softWrap: true,
                            ),
                          ),
                        ),

                        trailing: Container(
                          height: 55,
                          width: width * 0.3,
                          child: FittedBox(
                            child: Card(
                              color: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0)),
                              child: RaisedButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.0)),
                                color: Colors.white,
                                child: Text(
                                  //"\u20B9300000000",
                                  "\u20B9${_formatter.format(snapshot.data[index].totalAmount)}",
                                  overflow: TextOverflow.fade,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1
                                      .apply(
                                        //fontWeightDelta: -1,
                                        color: Colors.grey[400],
                                      ),
                                ),
                                onPressed: () {},
                                textColor: Theme.of(context).primaryColor,
                                padding: EdgeInsets.all(8.0),

                                //label:
                              ),
                            ),
                          ),
                        ),
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
