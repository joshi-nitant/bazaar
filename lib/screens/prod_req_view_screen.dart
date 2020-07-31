import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:baazar/screens/prod_req_update_screen.dart';

class ProdReqViewScreen extends StatefulWidget {
  static final String routeName = "/view";
  @override
  _ProdReqViewScreenState createState() => _ProdReqViewScreenState();
}

class _ProdReqViewScreenState extends State<ProdReqViewScreen> {
  bool _isSeller;
  int _userId;
  bool _isProduct;

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

  Future<List<Product>> _getProducts() async {
    var response = await http.post(
      Utils.URL + "getSpecificProduct.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'user_id': _userId.toString(),
        },
      ),
    );
    print(response.body);
    var jsondata = json.decode(response.body);
    List<Product> products = [];
    for (var u in jsondata) {
      Product product = Product(
        id: u['prod_id'],
        quantity: u['quantity'],
        price_expected: u['price_expected'],
        breed: u['breed'],
        category_id: u['category_id'],
        city: u['city'],
        state: u['state'],
        latitude: u['latitude'],
        longitude: u['longitude'],
        postalCode: u['pincode'],
        remainingQty: u['remaining_qty'],
        image: u['image'],
        address: u['address'],
        qualityCertificate: u['quality_certificate'],
        category: await _getCategory(u['category_id']),
      );
      products.add(product);
    }
    print(jsondata);
    return products;
  }

  Future<List<Requirement>> _getRequirements() async {
    var response = await http.post(
      Utils.URL + "getSpecificRequirement.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'user_id': _userId.toString(),
        },
      ),
    );

    var jsondata = json.decode(response.body);

    List<Requirement> requirements = [];
    for (var u in jsondata) {
      Requirement requirement = Requirement(
        id: u['req_id'],
        quantity: u['quantity'],
        price_expected: u['price_expected'],
        breed: u['breed'],
        category_id: u['category'],
        city: u['city'],
        state: u['state'],
        latitude: u['latitude'],
        longitude: u['longitude'],
        postalCode: u['pincode'],
        remainingQty: u['remaining_qty'],
        address: u['address'],
        category: await _getCategory(u['category']),
      );
      requirements.add(requirement);
    }
    return requirements;
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

  Future<List<dynamic>> _getList() async {
    _isSeller = await _checkIsSeller();
    print(_isSeller);
    _isProduct = _isSeller;
    _userId = await _getUserId();
    print(_userId);
    List<dynamic> objectList;

    if (_isSeller) {
      objectList = await _getProducts();
    } else {
      objectList = await _getRequirements();
    }
    print(objectList);
    return objectList;
  }

  _deleteListItem(dynamic object) async {
    //print(object.catgeory.name);
    print(object.id);
    var response = await http.post(
      Utils.URL + "deleteProdReq.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'id': object.id,
          'isProduct': _isProduct.toString(),
        },
      ),
    );
    print(response.body);
    setState(() {});
  }

  void _deleteItem(dynamic object) {
    Alert(
      closeFunction: () {
        null;
      },
      context: context,
      type: AlertType.warning,
      title: "Are you sure you want to delete?",
      desc: "All the information about the product and its bid will be deleted",
      buttons: [
        DialogButton(
          color: Theme.of(context).primaryColor,
          child: Text(
            "No",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        DialogButton(
            color: Theme.of(context).primaryColor,
            child: Text(
              "Yes",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () {
              _deleteListItem(object);
              Navigator.pop(context);
            }),
      ],
    ).show();
  }

  void _updateScreen(dynamic object) {
    Navigator.of(context).pushNamed(
      ProdReqUpdate.routeName,
      arguments: {
        'selected_object': object,
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
        future: _getList(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Container(
            height: 450,
            child: snapshot.data.length == 0
                ? Column(
                    children: <Widget>[
                      Text(
                        'Nothing added yet!',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                          height: 200,
                          child: Image.asset(
                            'assests/images/logo.png',
                            fit: BoxFit.cover,
                          )),
                    ],
                  )
                : ListView.builder(
                    itemBuilder: (ctx, index) {
                      return GestureDetector(
                        onTap: () {
                          _updateScreen(snapshot.data[index]);
                        },
                        child: Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 5,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: _isProduct
                                  ? NetworkImage(
                                      Utils.URL +
                                          "productImage/" +
                                          snapshot.data[index].image,
                                    )
                                  : NetworkImage(
                                      Utils.URL +
                                          "images/" +
                                          snapshot.data[index].category.imgPath,
                                    ),
                              radius: 30,
                            ),
                            title: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                snapshot.data[index].category.name,
                                style: Theme.of(context).textTheme.headline6,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.attach_money,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    Text(
                                      "${snapshot.data[index].price_expected}",
                                    ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.line_weight,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    Text(
                                      "Quantity = ${snapshot.data[index].quantity}",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                                icon: Icon(Icons.delete),
                                color: Theme.of(context).errorColor,
                                onPressed: () {
                                  _deleteItem(snapshot.data[index]);
                                }),
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
