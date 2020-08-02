import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/current_transaction_screen.dart';
import 'package:baazar/screens/manage_offer_screen.dart';
import 'package:baazar/screens/prod_req_add_screen.dart';
import 'package:baazar/screens/prod_req_detail.dart';
import 'package:baazar/screens/prod_req_view_screen.dart';
import 'package:baazar/screens/transaction_histroy_scree.dart';
import 'package:baazar/widgets/list_tile_widget.dart';
import 'package:baazar/screens/singup_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  static final String routeName = "/dashboard";
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String userType;
  Category category;

  Future<List<Requirement>> _getRequirements() async {
    var response = await http.post(
      Utils.URL + "getRequirements.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'cat_id': category.id,
        },
      ),
    );
    var jsondata = json.decode(response.body);
    List<Requirement> requirements = [];
    if (jsondata != 404) {
      for (var u in jsondata) {
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
          remainingQty: u['remaining_qty'],
          userId: u['user_id'],
        );
        requirements.add(requirement);
      }
    }
    print(jsondata);
    return requirements;
  }

  Future<List<Product>> _getProducts() async {
    var response = await http.post(
      Utils.URL + "getProduct.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'cat_id': category.id,
        },
      ),
    );
    var jsondata = json.decode(response.body);
    List<Product> products = [];
    if (jsondata != 404) {
      for (var u in jsondata) {
        Product product = Product(
          id: u['prod_id'],
          quantity: u['quantity'],
          price_expected: u['price_expected'],
          breed: u['breed'],
          category_id: u['category_id'],
          // city: u['city'],
          // state: u['state'],
          // latitude: u['latitude'],
          // longitude: u['longitude'],
          remainingQty: u['remaining_qty'],
          image: u['image'],
          qualityCertificate: u['quality_certificate'],
          userId: u['user_id'],
        );
        products.add(product);
      }
    }
    print(jsondata);
    return products;
  }

  void _redirectToManageScreeen() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE) == null) {
      //Navigator.of(context).pushNamed(ProdRedUpdate.routeName);
    } else {
      print('redirecting');
      Navigator.of(context).pushNamed(ProdReqViewScreen.routeName).then(
            (value) => Navigator.pop(context),
          );
    }
  }

  void _redirectToOfferScreeen() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE) == null) {
      //Navigator.of(context).pushNamed(ProdRedUpdate.routeName);
    } else {
      print('redirecting');
      Navigator.of(context).pushNamed(OfferViewScreen.routeName).then(
            (value) => Navigator.pop(context),
          );
    }
  }

  void _redirectToCurrentTransaction() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE) == null) {
      //Navigator.of(context).pushNamed(ProdRedUpdate.routeName);
    } else {
      print('redirecting');
      Navigator.of(context).pushNamed(CurrentTransaction.routeName).then(
            (value) => Navigator.pop(context),
          );
    }
  }

  void _redirectToTransactionHistory() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE) == null) {
      //Navigator.of(context).pushNamed(ProdRedUpdate.routeName);
    } else {
      print('redirecting');
      Navigator.of(context).pushNamed(TransactionHistory.routeName).then(
            (value) => Navigator.pop(context),
          );
    }
  }

  void _checkUserIsLoggedIn() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE) == null) {
      Navigator.of(context).pushNamed(SingUpScreen.routeName);
    } else {
      Navigator.of(context).pushNamed(ProdReqAdd.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    var routeArgs =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;

    category = routeArgs['category'];
    userType = routeArgs['userType'];

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
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assests/images/logo.png'),
                      radius: 45.0,
                    ),
                  ],
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
            ListTileWidget(
              Icons.insert_drive_file,
              'Transaction History',
              _redirectToTransactionHistory,
            ),
            ListTileWidget(
              Icons.people,
              'Manage Request',
              _redirectToOfferScreeen,
            ),
            ListTileWidget(
              Icons.monetization_on,
              'Current Transaction',
              _redirectToCurrentTransaction,
            ),
            ListTileWidget(
                Icons.list, 'Requirement List', _redirectToManageScreeen),
          ],
        ),
      ),
      // drawer: Drawer(
      //   child: ListView(
      //     children: <Widget>[
      //       UserAccountsDrawerHeader(
      //         accountName: Text("Baazar"),
      //         accountEmail: Text("baazar0@gmail.com"),
      //         currentAccountPicture: CircleAvatar(
      //           backgroundImage: NetworkImage("https://i.pravatar.cc/"),
      //         ),
      //       ),
      //       ListTile(
      //         title: Text("Register"),
      //         // onTap: () {
      //         //   Navigator.of(context).push(
      //         //       MaterialPageRoute(builder: (context) => Registration()));
      //         // },
      //       ),
      //       ListTile(
      //         title: Text("Manage your items"),
      //         onTap: () {
      //           _redirectToManageScreeen();
      //         },
      //       ),
      //       ListTile(
      //         title: Text("Settings"),
      //         onTap: () {
      //           //
      //         },
      //       ),
      //     ],
      //   ),
      // ),
      body: FutureBuilder(
          future: userType == "buyer" ? _getProducts() : _getRequirements(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.data.length == 0) {
              return Container(
                child: Center(
                  child: Text(
                    "There are no ${category.name} available.",
                    style: TextStyle(
                        fontSize: 18 * MediaQuery.of(context).textScaleFactor),
                  ),
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.all(10),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Color(0xFF739b21),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 10, top: 10, bottom: 10, right: 5),
                                child: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        "${Utils.URL}images/${category.imgPath}")),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional.center,
                              child: Column(
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.all(3),
                                    child: Text(
                                      snapshot.data[index].breed +
                                          " |" +
                                          "${AppLocalizations.of(context).translate(category.name)}",
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.attach_money,
                                            color: Color(0xFF739b21),
                                          ),
                                          Padding(
                                              padding:
                                                  EdgeInsets.only(right: 3)),
                                          Text(snapshot
                                              .data[index].price_expected)
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(right: 10),
                                      ),
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.assessment,
                                            color: Color(0xFF739b21),
                                          ),
                                          Padding(
                                              padding:
                                                  EdgeInsets.only(right: 3)),
                                          Text(snapshot.data[index].quantity)
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: RaisedButton(
                                  color: Color(0xFF739b21),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      ProdReqDetail.routeName,
                                      arguments: {
                                        "object": snapshot.data[index]
                                      },
                                    );
                                  },
                                  child: Text(
                                    "Bid",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      side:
                                          BorderSide(color: Color(0xFF739b21))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _checkUserIsLoggedIn();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
