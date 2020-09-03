import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/prod_bid.dart';
import 'package:baazar/models/product.dart';

import 'package:baazar/models/requirement.dart';
import 'package:baazar/models/requirement_bid.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/error_screen.dart';
import 'package:baazar/screens/offer_detail_screen.dart';
import 'package:baazar/screens/payment_screen.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:baazar/widgets/dialog_widget.dart';
import 'package:baazar/widgets/hand_shake_icon_icons.dart';
import 'package:baazar/widgets/m_y_baazar_icons.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:baazar/screens/prod_req_update_screen.dart';

Text normalText(BuildContext context, String text) {
  return Text(
    text,
    style: Theme.of(context).textTheme.bodyText2.apply(),
    textAlign: TextAlign.left,
  );
}

Text largeText(BuildContext context, String text) {
  return Text(
    text,
    style: Theme.of(context).textTheme.bodyText1,
  );
}

class OfferViewScreen extends StatefulWidget {
  static final String routeName = "/offer";
  @override
  _OfferViewScreenState createState() => _OfferViewScreenState();
}

class _OfferViewScreenState extends State<OfferViewScreen> {
  bool _isSeller;
  int _userId;
  bool _isProduct;
  double _TRANSACTION_CHARGE_PERCENTAGE;
  double _DELIVERY_CHARGE_PER_KM;

  // List<Product> _productsList;
  // List<Requirement> _requirementsList;
  // List<ProductBid> _productBidList;
  // List<RequirementBid> _requirementBidList;

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

  Future<List<ProductBid>> _getProductBids() async {
    var response = await http.post(
      Utils.URL + "getProdReqOffer.php",
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

    ///setting the charges
    _DELIVERY_CHARGE_PER_KM =
        double.tryParse(jsondata['DELIVERY_CHARGE_PER_KM']);
    _TRANSACTION_CHARGE_PERCENTAGE =
        double.tryParse(jsondata['TRANSACTION_CHARGE_PERCENTAGE']);

    List<ProductBid> productBid = [];
    for (var u in jsondata['list']) {
      Product product = Product(
        id: u['prod_id'],
        quantity: u['quantity'],
        price_expected: u['price_expected'],
        breed: u['breed'],
        category_id: u['category_id'],
        remainingQty: u['remaining_qty'],
        image: u['image'],
        //qualityCertificate: u['quality_certificate'],
        category: await _getCategory(u['category_id']),
      );
      ProductBid bid = ProductBid(
        prodBidId: int.parse(u['prod_bid_id']),
        userId: int.parse(u['user_id']),
        prodId: product,
        price: double.parse(u['bid_price']),
        quantity: int.parse(u['bid_quantity']),
        isAccepted: u['is_accepted'] == "1",
        buyer: await _getUser(
          int.parse(u['user_id']),
        ),
        bidDays: int.parse(u['delivery_days']),
        packagingCharges: double.parse(u['packaging_charges']),
      );
      productBid.add(bid);
    }
    //print(jsondata);
    return productBid;
  }

  Future<List<RequirementBid>> _getRequirementBids() async {
    var response = await http.post(
      Utils.URL + "getProdReqOffer.php",
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

    ///setting the charges
    _DELIVERY_CHARGE_PER_KM =
        double.tryParse(jsondata['DELIVERY_CHARGE_PER_KM']);
    _TRANSACTION_CHARGE_PERCENTAGE =
        double.tryParse(jsondata['TRANSACTION_CHARGE_PERCENTAGE']);
    print(jsondata['list']);

    List<RequirementBid> requirementBids = [];
    for (var u in jsondata['list']) {
      Requirement requirement = Requirement(
        id: u['req_id'],
        quantity: u['quantity'],
        price_expected: u['price_expected'],
        breed: u['breed'],
        category_id: u['category'],
        // city: u['city'],
        // state: u['state'],
        // latitude: u['latitude'],
        // longitude: u['longitude'],
        // postalCode: u['pincode'],
        remainingQty: u['remaining_qty'],
        //address: u['address'],
        category: await _getCategory(u['category']),
      );
      RequirementBid bid = RequirementBid(
        reqBidId: int.parse(u['req_bid_id']),
        userId: int.parse(u['user_id']),
        reqId: requirement,
        price: double.parse(u['bid_price']),
        quantity: int.parse(u['bid_quantity']),
        isAccepted: u['is_accepted'] == "1",
        seller: await _getUser(
          int.parse(u['user_id']),
        ),
        bidDays: int.parse(u['delivery_days']),
        packagingCharges: double.parse(u['packaging_charges']),
      );
      requirementBids.add(bid);
    }
    return requirementBids;
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

  Future<List<dynamic>> _getOfferList() async {
    _userId = await _getUserId();
    if (_userId == null) {
      return [];
    }
    _isSeller = await _checkIsSeller();
    print(_isSeller);
    _isProduct = _isSeller;

    print(_userId);
    List<dynamic> objectList;

    if (_isSeller) {
      objectList = await _getProductBids();
    } else {
      objectList = await _getRequirementBids();
    }
    //print(objectList);
    return objectList;
  }

  _deleteListItem(dynamic object) async {
    final ProgressDialog pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true, showLogs: true);
    pr.style(
      message: 'Deleting Please Wait...',
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
    //print(object.catgeory.name);
    //print(object.id);
    int id = -1;
    if (_isSeller) {
      id = object.prodBidId;
    } else {
      id = object.reqBidId;
    }
    var response = await http.post(
      Utils.URL + "deleteOffer.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'id': id.toString(),
          'isSeller': _isSeller.toString(),
        },
      ),
    );
    print(response.body);
    setState(() {});
    pr.hide();
  }

  _acceptListItem(dynamic object) async {
    //print(object.catgeory.name);
    //print(object.id);
    int id = -1;
    if (_isSeller) {
      id = object.prodBidId;
    } else {
      id = object.reqBidId;
    }
    var response = await http.post(
      Utils.URL + "acceptOffer.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'id': id.toString(),
          'isSeller': _isSeller.toString(),
        },
      ),
    );
    print(response.body);
    return response.body;
  }

  void _deleteItem(dynamic object) async {
    Alert(
      closeFunction: () {
        null;
      },

      context: context,
      type: AlertType.error,
      title: "Are you sure you want to delete this offer?",
      style: AlertStyle(
        titleStyle: Theme.of(context).textTheme.bodyText1,
        isCloseButton: false,
      ),
      //desc: "You won't be able to accept this later",
      image: null,
      buttons: [
        DialogButton(
          color: Theme.of(context).primaryColor,
          child: Text(
            "No",
            style: Theme.of(context).textTheme.bodyText2.apply(
                  color: Colors.white,
                ),
          ),
          radius: BorderRadius.circular(15),
          onPressed: () => Navigator.pop(context),
        ),
        DialogButton(
            color: Theme.of(context).primaryColor,
            child: Text(
              "Yes",
              style: Theme.of(context).textTheme.bodyText2.apply(
                    color: Colors.white,
                  ),
            ),
            radius: BorderRadius.circular(15),
            onPressed: () {
              Navigator.pop(context);
              _deleteListItem(object);
            }),
      ],
    ).show();
  }

  void _selectItem(dynamic object) {
    Alert(
      closeFunction: () {
        null;
      },
      style: AlertStyle(
          titleStyle: Theme.of(context).textTheme.bodyText1,
          isCloseButton: false),
      context: context,
      type: AlertType.success,
      title: "Are you sure you want to accept this offer?",
      desc: null,
      buttons: [
        DialogButton(
          color: Theme.of(context).primaryColor,
          child: Text(
            "No",
            style: Theme.of(context).textTheme.bodyText2.apply(
                  color: Colors.white,
                ),
          ),
          onPressed: () => Navigator.pop(context),
          radius: BorderRadius.circular(15),
        ),
        DialogButton(
          color: Theme.of(context).primaryColor,
          child: Text(
            "Yes",
            style: Theme.of(context).textTheme.bodyText2.apply(
                  color: Colors.white,
                ),
          ),
          radius: BorderRadius.circular(15),
          onPressed: () async {
            Navigator.pop(context);
            final ProgressDialog pr = ProgressDialog(context,
                type: ProgressDialogType.Normal,
                isDismissible: true,
                showLogs: true);
            pr.style(
              message: 'Accepting Offer...',
              borderRadius: 10.0,
              backgroundColor: Colors.white,
              progressWidget: CircularProgressIndicator(),
              elevation: 10.0,
              insetAnimCurve: Curves.easeInOut,
              progress: 0.0,
              maxProgress: 100.0,
              progressTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w400),
              messageTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 19.0,
                  fontWeight: FontWeight.w600),
            );
            await pr.show();
            var response = await _acceptListItem(object);
            var data = json.decode(response);
            pr.hide();
            print(data);
            print("acccepting");
            if (data['response_code'] == 404) {
              String text = "Sorry!!!";
              String dialogMesage = "Offer acceptance failed. Retry.....";
              String buttonMessage = "Ok!!";
              await CustomDialog.openDialog(
                  context: context,
                  title: text,
                  message: dialogMesage,
                  mainIcon: Icons.check,
                  subIcon: Icons.error);
              //Navigator.pop(context);
            } else if (data['response_code'] == 407) {
              String text = "Sorry!!!";
              String dialogMessage = "";
              if (_isProduct) {
                dialogMessage =
                    "You do not have sufficient remaining quantity of ${object.prodId.category.name} left";
              } else {
                dialogMessage =
                    "You do not have sufficient remaining quantity of ${object.reqId.category.name} left";
              }

              String buttonMessage = "Ok!!";
              await CustomDialog.openDialog(
                  context: context,
                  title: text,
                  message: dialogMessage,
                  mainIcon: Icons.check,
                  subIcon: Icons.error);
              //Navigator.pop(context);
            } else if (data['response_code'] == 405 ||
                data['response_code'] == 406) {
              String text = "Sorry!!!";
              String dialogMesage = "The seller is out of stock";
              String buttonMessage = "Ok!!";
              await CustomDialog.openDialog(
                  context: context,
                  title: text,
                  message: dialogMesage,
                  mainIcon: Icons.check,
                  subIcon: Icons.error);
              //Navigator.pop(context);
            } else if (data['response_code'] == 101 && _isSeller) {
              String text = "Congratulations!!!";
              String dialogMesage = "Offer Accepted";
              String buttonMessage = "Ok!!";

              await CustomDialog.openDialog(
                  context: context,
                  title: text,
                  message: dialogMesage,
                  mainIcon: Icons.check,
                  subIcon: HandShakeIcon.handshake);
              setState(() {});
            } else if (data['response_code'] == 101 && !_isSeller)
              //print(object);
              Navigator.of(context).pushNamed(
                PaymentScreen.routeName,
                arguments: {
                  'bid_object': object,
                  'transaction_id': data['transaction_id'],
                  'TRANSACTION_CHARGE_PERCENTAGE':
                      _TRANSACTION_CHARGE_PERCENTAGE,
                  'DELIVERY_CHARGE_PER_KM': _DELIVERY_CHARGE_PER_KM,
                  'end_date': DateTime.parse(data['end_date']),
                  'delivery_status': 0
                },
              ).then((value) => setState(() {}));
          },
        ),
      ],
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
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
        future: _getOfferList(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.data.length == 0) {
            return NoProduct("OFFER REQUEST");
          }
          return Container(
            height: height,
            width: width,
            margin: EdgeInsets.all(5.0),
            child: Card(
              color: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              child: ListView.builder(
                itemBuilder: (ctx, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        OfferDetailScreen.routeName,
                        arguments: {
                          'bid_object': snapshot.data[index],
                          'TRANSACTION_CHARGE_PERCENTAGE':
                              _TRANSACTION_CHARGE_PERCENTAGE,
                          'DELIVERY_CHARGE_PER_KM': _DELIVERY_CHARGE_PER_KM,
                          'accept_handler': _selectItem,
                          'delete_handler': _deleteItem,
                        },
                      );
                    },
                    child: Container(
                      width: data.size.width,
                      child: Card(
                        elevation: 5,
                        margin: EdgeInsets.all(8.0),
                        child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              backgroundImage: _isSeller
                                  ? NetworkImage(
                                      Utils.URL +
                                          "images/" +
                                          snapshot.data[index].prodId.category
                                              .imgPath,
                                    )
                                  : NetworkImage(
                                      Utils.URL +
                                          "images/" +
                                          snapshot.data[index].reqId.category
                                              .imgPath,
                                    ),
                              backgroundColor: Colors.white,
                              radius: 30.0,
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      _isProduct
                                          ? "${snapshot.data[index].prodId.breed}" +
                                              " | " +
                                              "${snapshot.data[index].prodId.category.name}"
                                          : "${snapshot.data[index].reqId.breed}" +
                                              " | " +
                                              "${snapshot.data[index].reqId.category.name}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText1
                                          .apply(
                                            fontSizeDelta: -4,
                                          ),
                                    ),
                                    _isSeller
                                        ? Text(
                                            "${snapshot.data[index].buyer.city},${snapshot.data[index].buyer.state}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2,
                                          )
                                        : Text(
                                            "${snapshot.data[index].seller.city},${snapshot.data[index].seller.state}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2,
                                          ),
                                    FittedBox(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Column(
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.gavel,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                    Text(
                                                      "${snapshot.data[index].price.toString()}/QTL",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headline2,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            children: <Widget>[
                                              Row(
                                                children: <Widget>[
                                                  Icon(
                                                    MYBaazar.balance,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                  Text(
                                                    "${snapshot.data[index].quantity.toString()}QTL",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline2,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  FittedBox(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: ClipOval(
                                            child: Material(
                                              color: Theme.of(context)
                                                  .primaryColor, // button color
                                              child: InkWell(
                                                splashColor: Colors
                                                    .grey, // inkwell color
                                                child: SizedBox(
                                                    width: 50,
                                                    height: 50,
                                                    child: Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 40,
                                                    )),
                                                onTap: () {
                                                  setState(() {
                                                    _selectItem(
                                                        snapshot.data[index]);
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        ClipOval(
                                          child: Material(
                                            color: Theme.of(context)
                                                .primaryColor, // button color
                                            child: InkWell(
                                              splashColor:
                                                  Colors.grey, // inkwell color
                                              child: SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 40,
                                                  )),
                                              onTap: () {
                                                _deleteItem(
                                                    snapshot.data[index]);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0)),
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
