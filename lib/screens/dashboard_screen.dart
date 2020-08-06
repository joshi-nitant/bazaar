import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/breed.dart';
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
import 'package:baazar/widgets/filter_dialog_widget.dart';
import 'package:baazar/widgets/list_tile_widget.dart';
import 'package:baazar/screens/singup_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  List<Product> productList = [];
  List<Requirement> requirementList = [];
  List<Product> productFilterList = [];
  List<Requirement> requirementFilterList = [];
  Icon cusIcon = Icon(Icons.filter_list);
  Widget cusSearchBar;
  int minPrice = 0;
  int maxPrice = 0;
  User user;
  int userId;
  Set<String> cityList = Set();
  Function kiloHandler;
  Function breedHandler;
  bool _isInitialLoad = true;

  List<String> kilometerList = ["50", "100", "150", "200", "300"];
  @override
  void didChangeDependencies() {
    cusSearchBar = Text(
      AppLocalizations.of(context).translate('app_title'),
      style: TextStyle(
        color: Colors.white,
        fontSize: 25,
      ),
    );
    super.didChangeDependencies();
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

  Future<List<Requirement>> _getRequirements() async {
    if (_isInitialLoad) {
      this.userId = await _getUserId();
      this.user = await _getUser(this.userId);
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
            buyer: _getUser(int.parse(u['user_id'])),
          );
          int currPrice = double.parse(requirement.price_expected).toInt();
          if (currPrice < minPrice) {
            minPrice = currPrice;
          } else if (currPrice > maxPrice) {
            maxPrice = currPrice;
          }
          cityList.add(requirement.buyer.city);
          requirements.add(requirement);
        }
      }
      this.requirementList = requirements;
      await _calculateDistanceRequirement(requirementList);
      return this.requirementList;
    }
    return this.requirementFilterList;
  }

  Future<void> _calculateDistanceProduct(List<Product> productList) async {
    LatLng startCordinate = LatLng(
      double.parse(this.user.latitude),
      double.parse(this.user.longitude),
    );

    for (int i = 0; i < productList.length; i++) {
      print(productList[i].seller.latitude);
      LatLng endCordinate = LatLng(
        double.parse(productList[i].seller.latitude),
        double.parse(productList[i].seller.longitude),
      );

      productList[i].distance =
          (await _getDistance(startCordinate, endCordinate)).toInt();
    }
  }

  Future<void> _calculateDistanceRequirement(
      List<Requirement> requirementList) async {
    LatLng startCordinate = LatLng(
      double.parse(this.user.latitude),
      double.parse(this.user.longitude),
    );

    for (int i = 0; i < requirementList.length; i++) {
      LatLng endCordinate = LatLng(
        double.parse(requirementList[i].buyer.latitude),
        double.parse(requirementList[i].buyer.longitude),
      );

      requirementList[i].distance =
          (await _getDistance(startCordinate, endCordinate)).toInt();
    }
  }

  Future<int> _getUserId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE);
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

  Future<List<Product>> _getProducts() async {
    if (_isInitialLoad) {
      this.userId = await _getUserId();
      this.user = await _getUser(this.userId);
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
            seller: await _getUser(int.parse(u['user_id'])),
          );
          cityList.add(product.seller.city);
          print(product.price_expected);
          int currPrice = double.parse(product.price_expected).toInt();
          if (currPrice < minPrice) {
            minPrice = currPrice;
          } else if (currPrice > maxPrice) {
            maxPrice = currPrice;
          }
          products.add(product);
        }
      }

      this.productList = products;
      await _calculateDistanceProduct(productList);
      return this.productList;
    }
    return this.productFilterList;
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

  void _removeHadnler() {
    if (this.userType == "buyer") {
      this.productFilterList = this.productList;
    } else {
      this.requirementFilterList = this.requirementList;
    }
  }

  void _filterHandler(
      String kilometer, List<String> breed, int startPrice, int endPrice) {
    //this.cusIcon = Icon(Icons.search);
    print(kilometer);
//print("Kilometer = " + kilometer);
    print("Breed = " + breed.toString());
    print("Start Price = " + startPrice.toString());
    print("End Price = " + endPrice.toString());
    this.cusSearchBar = Text(
      AppLocalizations.of(context).translate('app_title'),
      style: TextStyle(
        color: Colors.white,
        fontSize: 25,
      ),
    );
    setState(() {
      _isInitialLoad = false;

      if (userType == "buyer") {
        productFilterList = this.productList;
        if (breed.length != 0) {
          productFilterList = (productFilterList
              .where((product) => breed.contains(product.breed))
              .toList());
        }
        if (kilometer != null) {
          int distance = int.parse(kilometer);
          productFilterList = productFilterList
              .where((product) => product.distance <= distance)
              .toList();
        }

        productFilterList = productFilterList
            .where((product) =>
                startPrice <= double.parse(product.price_expected).toInt() &&
                double.parse(product.price_expected).toInt() <= endPrice)
            .toList();
      } else {
        requirementFilterList = this.requirementList;
        if (kilometer != null) {
          int distance = int.parse(kilometer);
          requirementFilterList = (requirementFilterList
              .where((requirement) => requirement.distance <= distance)
              .toList());
        }
        if (breed.length != 0) {
          requirementFilterList = (requirementFilterList
              .where((requirement) => breed.contains(requirement.breed))
              .toList());
        }
        requirementFilterList = (requirementFilterList
            .where((requirement) =>
                startPrice <=
                    double.parse(requirement.price_expected).toInt() &&
                double.parse(requirement.price_expected).toInt() <= endPrice)
            .toList());
      }
    });
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
        title: this.cusSearchBar,
        actions: <Widget>[
          IconButton(
            onPressed: () {
              setState(() {
                if (this.cusIcon.icon == Icons.filter_list) {
                  //this.cusIcon = Icon(Icons.close);
                  this.cusSearchBar = Text(
                    "Filter",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                    ),
                  );
                  showFilterDialog(
                      context: context,
                      breedList: category.breed,
                      //breedHandler: breedHandler,
                      buttonMessage: "Apply",
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                      dropdownItems: kilometerList,
                      // dropDownHandler: kiloHandler,
                      buttonHandler: _filterHandler,
                      title: "Filter");
                }
                // else {
                //   this.cusIcon = Icon(Icons.search);
                //   this.cusSearchBar = Text(
                //     AppLocalizations.of(context).translate('app_title'),
                //     style: TextStyle(
                //       color: Colors.white,
                //       fontSize: 25,
                //     ),
                //   );
                // }
              });
            },
            icon: cusIcon,
          )
        ],
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
