import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/select_category_screen.dart';
import 'package:baazar/screens/select_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _loadCatAndUserType() async {
    var routeArgs =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    Object _detailObject = routeArgs['object'];

    if (_detailObject is Product) {
      product = _detailObject;
    } else {
      requirement = _detailObject;
    }
    String jsonString = await _getCategoryList();
    this.isSeller = await _getUserType();
    this.userId = await _getUserId();
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
    if (_detailObject is Product) {
      category =
          categoryList.firstWhere((element) => category.id == product.id);
    } else {
      category =
          categoryList.firstWhere((element) => category.id == requirement.id);
    }
    print(category.id);
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
          future: _loadCatAndUserType(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return Text('hello');
          }),
    );
  }
}
