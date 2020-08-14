import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/breed.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/product.dart';
import 'package:baazar/models/requirement.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/current_transaction_screen.dart';
import 'package:baazar/screens/error_screen.dart';
import 'package:baazar/screens/manage_offer_screen.dart';
import 'package:baazar/screens/prod_req_add_screen.dart';
import 'package:baazar/screens/prod_req_detail.dart';
import 'package:baazar/screens/prod_req_view_screen.dart';
import 'package:baazar/screens/transaction_histroy_scree.dart';
import 'package:baazar/widgets/filter_dialog_widget.dart';
import 'package:baazar/widgets/list_tile_widget.dart';
import 'package:baazar/screens/singup_screen.dart';
import 'package:baazar/widgets/m_y_baazar_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  var appBar;

  List<String> kilometerList = ["None", "50", "100", "150", "200", "300"];
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
      print(jsondata);
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
            buyer: await _getUser(int.parse(u['user_id'])),
          );
          int currPrice = double.parse(requirement.price_expected).toInt();
          if (currPrice < minPrice) {
            minPrice = currPrice;
          } else if (currPrice > maxPrice) {
            maxPrice = currPrice;
          }
          if (requirement.buyer != null) cityList.add(requirement.buyer.city);
          requirements.add(requirement);
        }
      }
      this.requirementList = requirements;
      if (userId != null) await _calculateDistanceRequirement(requirementList);
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
      print(requirementList[i].buyer.latitude);
      print(requirementList[i].buyer.longitude);

      LatLng endCordinate = LatLng(
        double.tryParse(requirementList[i].buyer.latitude),
        double.tryParse(requirementList[i].buyer.longitude),
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
    print(id);
    if (id != null) {
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
    return null;
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
      print(jsondata);
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
          print("Image = " + product.image);
          if (product.seller != null) cityList.add(product.seller.city);

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
      if (userId != null) await _calculateDistanceProduct(productList);
      return this.productList;
    }
    return this.productFilterList;
  }

  void _redirectToManageScreeen() async {
    Navigator.of(context).pushNamed(ProdReqViewScreen.routeName);
  }

  void _redirectToOfferScreeen() async {
    Navigator.of(context).pushNamed(OfferViewScreen.routeName);
  }

  void _redirectToCurrentTransaction() async {
    Navigator.of(context).pushNamed(CurrentTransaction.routeName);
  }

  void _redirectToTransactionHistory() async {
    Navigator.of(context).pushNamed(TransactionHistory.routeName);
  }

  void _checkUserIsLoggedIn() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE) == null) {
      Navigator.of(context).pushNamed(SingUpScreen.routeName);
    } else {
      Navigator.of(context).pushNamed(ProdReqAdd.routeName);
    }
  }

  void removeHandler() {
    setState(() {
      if (this.userType == "buyer") {
        this.productFilterList = this.productList;
      } else {
        this.requirementFilterList = this.requirementList;
      }
    });
  }

  void applyHandler(
      String kilometer, List<String> breed, int startPrice, int endPrice) {
    print(kilometer);
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
        if (kilometer != "None") {
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
        if (kilometer != "None") {
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

  String getCity(dynamic object) {
    if (userType != "seller") {
      return object.seller.city;
    } else {
      return object.buyer.city;
    }
  }

  String getPrice(dynamic object) {
    return "Rs.${object.price_expected}/QTL";
  }

  @override
  Widget build(BuildContext context) {
    //SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    var routeArgs =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    var data = MediaQuery.of(context);

    appBar = AppBar(
      title: Text(
        AppLocalizations.of(context).translate('app_title'),
        style: Theme.of(context).textTheme.headline1.apply(
              color: Colors.white,
            ),
      ),
      iconTheme: IconThemeData(color: Colors.white),
    );
    var height = (MediaQuery.of(context).size.height -
        appBar.preferredSize.height -
        MediaQuery.of(context).padding.top);
    var width = MediaQuery.of(context).size.width;

    category = routeArgs['category'];
    userType = routeArgs['userType'];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      appBar: appBar,
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: Column(
          children: <Widget>[
            Container(
              height: height * 0.8,
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: <Widget>[
                  DrawerHeader(
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage:
                                AssetImage('assests/images/logo.png'),
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
                    Icons.assignment,
                    'Transaction History',
                    _redirectToTransactionHistory,
                  ),
                  ListTileWidget(
                    Icons.people,
                    'Manage Request',
                    _redirectToOfferScreeen,
                  ),
                  ListTileWidget(
                    Icons.history,
                    'Current Transaction',
                    _redirectToCurrentTransaction,
                  ),
                  ListTileWidget(
                      Icons.list, 'Requirement List', _redirectToManageScreeen),
                ],
              ),
            ),
            Flexible(
              flex: 1,
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        backgroundImage: AssetImage('assests/images/logo.png'),
                        backgroundColor: Colors.white,
                        radius: 25.0,
                      ),
                      SizedBox(
                        width: 17.0,
                      ),
                      Text(
                        AppLocalizations.of(context).translate('app_title'),
                        style: Theme.of(context).textTheme.headline1.apply(
                              color: Theme.of(context).primaryColor,
                            ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                width: width,
                height: height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: height * 0.1,
                      width: data.size.width,
                      margin: EdgeInsets.all(5.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => Filter(
                                breedList: category.breed,
                                minPrice: minPrice,
                                maxPrice: maxPrice,
                                distanceList: kilometerList,
                                applyHandler: applyHandler,
                                removeHandler: removeHandler,
                              ),
                            );
                          });
                        },
                        child: Card(
                          color: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.filter_list,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate("Filter"),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .apply(
                                          color: Colors.white,
                                          fontSizeFactor: data.textScaleFactor,
                                        ),
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
                    NoProduct("DASHBOARD ERROR"),
                  ],
                ),
              );
            }
            return Container(
              width: width,
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: height * 0.1,
                    width: data.size.width,
                    margin: EdgeInsets.all(5.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => Filter(
                              breedList: category.breed,
                              minPrice: minPrice,
                              maxPrice: maxPrice,
                              distanceList: kilometerList,
                              applyHandler: applyHandler,
                              removeHandler: removeHandler,
                            ),
                          );
                        });
                      },
                      child: Card(
                        color: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.filter_list,
                                color: Colors.white,
                              ),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate("Filter"),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1
                                      .apply(
                                        color: Colors.white,
                                        fontSizeFactor: data.textScaleFactor,
                                      ),
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
                  Container(
                    height: height * 0.77,
                    width: width,
                    margin: EdgeInsets.all(5.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Theme.of(context).primaryColor,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: ListView.builder(
                          itemCount: snapshot.data.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              color: Colors.white,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          left: 10,
                                          top: 10,
                                          bottom: 10,
                                          right: 5),
                                      child: CircleAvatar(
                                          radius: 25,
                                          backgroundImage: NetworkImage(
                                              "${Utils.URL}images/${category.imgPath}")),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        Padding(
                                          padding: EdgeInsets.all(3),
                                          child: Text(
                                            snapshot.data[index].breed +
                                                " | " +
                                                "${AppLocalizations.of(context).translate(category.name)}" +
                                                " in " +
                                                getCity(snapshot.data[index]),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .apply(
                                                  fontSizeFactor:
                                                      MediaQuery.of(context)
                                                          .textScaleFactor,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        FittedBox(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              Row(
                                                children: <Widget>[
                                                  Icon(
                                                    Icons.gavel,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                  Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 3)),
                                                  Text(
                                                    getPrice(
                                                        snapshot.data[index]),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText1
                                                        .apply(
                                                          color: Colors.black,
                                                          fontSizeFactor:
                                                              MediaQuery.of(
                                                                      context)
                                                                  .textScaleFactor,
                                                          fontSizeDelta: -2,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(right: 10),
                                              ),
                                              Row(
                                                children: <Widget>[
                                                  Icon(
                                                    MYBaazar.balance,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                  Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 3)),
                                                  Text(
                                                    "${snapshot.data[index].quantity}QTL",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText1
                                                        .apply(
                                                          color: Colors.black,
                                                          fontSizeFactor:
                                                              MediaQuery.of(
                                                                      context)
                                                                  .textScaleFactor,
                                                          fontSizeDelta: -2,
                                                        ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Padding(
                                      padding: EdgeInsets.all(3),
                                      child: RaisedButton(
                                        color: Theme.of(context).primaryColor,
                                        onPressed: () {
                                          Navigator.of(context).pushNamed(
                                            ProdReqDetail.routeName,
                                            arguments: {
                                              "object": snapshot.data[index]
                                            },
                                          ).then((value) => setState(() {}));
                                        },
                                        child: Text("Bid",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline2
                                                .apply(
                                                  color: Colors.white,
                                                )),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30.0),
                                            side: BorderSide(
                                                color: Color(0xFF739b21))),
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
                  ),
                ],
              ),
            );
          }),
      floatingActionButton: Container(
        height: height * 0.1,
        width: width,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () {
              _checkUserIsLoggedIn();
            },
            child: Icon(Icons.add, size: 50),
            backgroundColor: Theme.of(context).primaryColorLight,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
