import 'dart:convert';

import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/prod_bid.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement.dart';
import 'package:baazar/models/requirement_bid.dart';
import 'package:baazar/models/transaction.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/payment_screen.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
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
    _isSeller = await _checkIsSeller();
    _userId = await _getUserId();

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

    if (jsondata['transaction_requirement'] != null) {
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
          totalAmount: int.parse(u['total_amount']),
        );
        _pendingTransactions.add(transaction);
      }
    }
    //print(_pendingTransactions.length);
    if (jsondata['transaction_product'] != null) {
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
          totalAmount: int.parse(u['total_amount']),
        );

        _pendingTransactions.add(transaction);
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
    if (_isSeller) {
      return tn.productBidId.prodId.category.name;
    } else {
      return tn.reqbidId.reqId.category.name;
    }
  }

  String _getBreed(dynamic transaction) {
    Transaction tn = transaction as Transaction;
    if (_isSeller) {
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

  @override
  Widget build(BuildContext context) {
    final curr = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      backgroundColor: Colors.white,
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
        future: _getCompletedTransaction(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Container(
            child: ListView.builder(
              itemBuilder: (ctx, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  margin: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 5,
                  ),
                  child: ListTile(
                    //contentPadding: EdgeInsets.only(bottom: 10),
                    //isThreeLine: true,
                    leading: CircleAvatar(
                      radius: 30.0,
                      backgroundImage: _getImage(snapshot.data[index]),
                      backgroundColor: Colors.transparent,
                    ),
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _getTitle(snapshot.data[index]),
                        style: Theme.of(context).textTheme.title,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    subtitle: Text(
                      //"Pending transaction of \u20B9 ${_getTotalAmount(snapshot.data[index])}",
                      "Transaction Date ${_dateFormater.format(snapshot.data[index].endDate)}",
                      style: TextStyle(
                        fontSize: 15 * curr,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                    trailing: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0)),
                      child: Container(
                        height: 55,
                        width: 120,
                        color: Colors.white,
                        child: RaisedButton(
                          color: Colors.white,
                          child: Text(
                            //"\u20B930000000",
                            "\u20B9${_formatter.format(snapshot.data[index].totalAmount)}",
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          onPressed: () {},
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),

                          textColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.all(8.0),

                          //label:
                        ),
                      ),
                    ),
                  ),
                );
              },
              itemCount: snapshot.data.length,
            ),
          );
        },
      ),
    );
  }
}
