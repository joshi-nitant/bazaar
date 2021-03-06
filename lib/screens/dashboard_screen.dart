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
import 'package:baazar/screens/update_profile_screen.dart';
import 'package:baazar/widgets/dialog_widget.dart';
import 'package:baazar/widgets/filter_dialog_widget.dart';
import 'package:baazar/widgets/hand_shake_icon_icons.dart';
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
  double _TRANSACTION_CHARGE_PERCENTAGE;
  double _DELIVERY_CHARGE_PER_KM;

  List<String> kilometerList = ["None", "50", "100", "150", "200", "300"];

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
    this.userId = await _getUserId();
    if (_isInitialLoad) {
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
      if (jsondata['response_code'] != "404") {
        _DELIVERY_CHARGE_PER_KM =
            double.tryParse(jsondata['DELIVERY_CHARGE_PER_KM']);
        _TRANSACTION_CHARGE_PERCENTAGE =
            double.tryParse(jsondata['TRANSACTION_CHARGE_PERCENTAGE']);
        for (var u in jsondata['requirements']) {
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
      if (userId != null) {
        await _calculateDistanceRequirement(requirementList);
      }
      return this.requirementList;
    }
    return this.requirementFilterList;
  }

  Future<List<Product>> _calculateDistanceProduct(
      List<Product> productList) async {
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
    return productList;
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
    this.userId = await _getUserId();
    if (_isInitialLoad) {
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
      print(response.body);
      var jsondata = json.decode(response.body);
      print(jsondata);
      List<Product> products = [];
      if (jsondata['response_code'] != "404") {
        _DELIVERY_CHARGE_PER_KM =
            double.tryParse(jsondata['DELIVERY_CHARGE_PER_KM']);
        _TRANSACTION_CHARGE_PERCENTAGE =
            double.tryParse(jsondata['TRANSACTION_CHARGE_PERCENTAGE']);
        for (var u in jsondata['products']) {
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
      print("before distance");
      if (userId != null) {
        this.productList = await _calculateDistanceProduct(productList);
        for (Product prod in productList) {
          print(prod.distance);
        }
      }
      print("returnng");
      return this.productList;
    }
    return this.productFilterList;
  }

  void _redirectToManageProfile() async {
    Navigator.of(context).pushNamed(UpdateProfileScreen.routeName);
  }

  void _redirectToManageScreeen() async {
    Navigator.of(context).pushNamed(ProdReqViewScreen.routeName,
        arguments: {'category': this.category});
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
      await Navigator.of(context).pushNamed(SingUpScreen.routeName,
          arguments: {'category': this.category});
      print("poped");
      setState(() {
        userId = sharedPreferences.getInt(User.USER_ID_SHARED_PREFERNCE);
      });
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
        // for (Product req in productFilterList) {
        //   print(req.distance);
        // }
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

        for (Requirement req in requirementFilterList) {
          print(req.distance);
        }

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
    return "\u20B9${double.parse(object.price_expected).toInt()}/QTL";
  }

  @override
  void initState() {
    super.initState();
    print("init");
    SharedPreferences.getInstance().then((prefs) {
      setState(() => userId = prefs.getInt(User.USER_ID_SHARED_PREFERNCE));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("didChangeDependencies");
    cusSearchBar = Text(
      AppLocalizations.of(context).translate('app_title'),
      style: TextStyle(
        color: Colors.white,
        fontSize: 25,
      ),
    );
    SharedPreferences.getInstance().then((prefs) {
      setState(() => userId = prefs.getInt(User.USER_ID_SHARED_PREFERNCE));
    });
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
    // userId = routeArgs['userId'];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      appBar: appBar,
      drawer: userId != null
          ? Drawer(
              // Add a ListView to the drawer. This ensures the user can scroll
              // through the options in the drawer if there isn't enough vertical
              // space to fit everything.
              child: Column(
                children: <Widget>[
                  Container(
                    height: height,
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
                          Icons.person,
                          'Manage Profile',
                          _redirectToManageProfile,
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
                          Icons.assignment,
                          'Transaction History',
                          _redirectToTransactionHistory,
                        ),
                        ListTileWidget(
                          Icons.list,
                          'Requirement List',
                          _redirectToManageScreeen,
                        ),
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
                              backgroundImage:
                                  AssetImage('assests/images/logo.png'),
                              backgroundColor: Colors.white,
                              radius: 25.0,
                            ),
                            SizedBox(
                              width: 17.0,
                            ),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('app_title'),
                              style:
                                  Theme.of(context).textTheme.headline1.apply(
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
            )
          : null,
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
                      margin:
                          EdgeInsets.symmetric(horizontal: 7.0, vertical: 5.0),
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
                          color: Theme.of(context).primaryColorLight,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(Utils.BORDER_RADIUS)),
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
                    margin:
                        EdgeInsets.symmetric(horizontal: 7.0, vertical: 5.0),
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
                        color: Theme.of(context).primaryColorLight,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Utils.BORDER_RADIUS)),
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
                    height: height * 0.75,
                    width: width,
                    margin:
                        EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Utils.BORDER_RADIUS_CARD),
                      ),
                      color: Theme.of(context).primaryColor,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: ListView.builder(
                          itemCount: snapshot.data.length,
                          itemBuilder: (BuildContext context, int index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  ProdReqDetail.routeName,
                                  arguments: {
                                    "object": snapshot.data[index],
                                    'TRANSACTION_CHARGE_PERCENTAGE':
                                        _TRANSACTION_CHARGE_PERCENTAGE,
                                    'DELIVERY_CHARGE_PER_KM':
                                        _DELIVERY_CHARGE_PER_KM,
                                    'checkUserIsLoggedIn': _checkUserIsLoggedIn
                                  },
                                ).then((value) => setState(() {}));
                              },
                              child: Container(
                                height: height * 0.14,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        Utils.BORDER_RADIUS_CARD),
                                  ),
                                  color: Colors.white,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              left: 10,
                                              top: 10,
                                              bottom: 10,
                                              right: 5),
                                          child: CircleAvatar(
                                            radius: 25,
                                            backgroundImage: NetworkImage(
                                                "${Utils.URL}images/${category.imgPath}"),
                                            backgroundColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.only(
                                              left: width * 0.03),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              //First column
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                  height: height * 0.15,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: <Widget>[
                                                      //breed + price
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: <Widget>[
                                                          //Breed
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    top: 5.0),
                                                            child: Text(
                                                              snapshot
                                                                  .data[index]
                                                                  .breed,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyText2
                                                                  .apply(
                                                                    fontSizeFactor:
                                                                        MediaQuery.of(context)
                                                                            .textScaleFactor,
                                                                    fontSizeDelta:
                                                                        -2,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                            ),
                                                          ),

                                                          //Name
                                                          Text(
                                                            "${AppLocalizations.of(context).translate(category.name)}",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyText2
                                                                .apply(
                                                                    fontSizeFactor:
                                                                        MediaQuery.of(context)
                                                                            .textScaleFactor,
                                                                    fontSizeDelta:
                                                                        3,
                                                                    color: Colors
                                                                        .black),
                                                            textAlign:
                                                                TextAlign.start,
                                                            softWrap: true,
                                                          ),
                                                        ],
                                                      ),

                                                      //Price
                                                      Row(
                                                        children: <Widget>[
                                                          Icon(
                                                            Icons.gavel,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            size: 20,
                                                          ),
                                                          Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      right:
                                                                          3)),
                                                          Text(
                                                            getPrice(snapshot
                                                                .data[index]),
                                                            // "1234567 /QTL",
                                                            style:
                                                                Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyText2
                                                                    .apply(
                                                                      fontSizeFactor:
                                                                          MediaQuery.of(context)
                                                                              .textScaleFactor,
                                                                      fontSizeDelta:
                                                                          -4,
                                                                    ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              //Second Column
                                              // Container(
                                              //   height: height * 0.1,
                                              //   width: width * 0.2,
                                              //   child: Column(
                                              //     crossAxisAlignment:
                                              //         CrossAxisAlignment.start,
                                              //     mainAxisAlignment:
                                              //         MainAxisAlignment.start,
                                              //     children: <Widget>[
                                              //       Text(
                                              //         "${AppLocalizations.of(context).translate(category.name)}",
                                              //         style: Theme.of(context)
                                              //             .textTheme
                                              //             .bodyText2
                                              //             .apply(
                                              //                 fontSizeFactor:
                                              //                     MediaQuery.of(
                                              //                             context)
                                              //                         .textScaleFactor,
                                              //                 fontSizeDelta: 3,
                                              //                 color:
                                              //                     Colors.black),
                                              //         textAlign: TextAlign.center,
                                              //         softWrap: true,
                                              //       ),
                                              //     ],
                                              //   ),
                                              // ),
                                              //Third Column
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                    height: height * 0.15,
                                                    margin: EdgeInsets.only(
                                                        left: 12.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: <Widget>[
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  top: 5.0),
                                                          child: Text(
                                                            getCity(snapshot
                                                                .data[index]),
                                                            //"abcdefghijklmn",
                                                            style:
                                                                Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyText2
                                                                    .apply(
                                                                      fontSizeFactor:
                                                                          MediaQuery.of(context)
                                                                              .textScaleFactor,
                                                                      fontSizeDelta:
                                                                          -4,
                                                                      color: Colors
                                                                          .grey,
                                                                    ),
                                                            textAlign:
                                                                TextAlign.start,

                                                            maxLines: 2,

                                                            overflow:
                                                                TextOverflow
                                                                    .visible,
                                                          ),
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Icon(
                                                              MYBaazar.balance,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                              size: 20,
                                                            ),
                                                            Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        right:
                                                                            3)),
                                                            Text(
                                                              "${snapshot.data[index].remainingQty} QTL",

                                                              // "12345 QTL",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyText2
                                                                  .apply(
                                                                    fontSizeFactor:
                                                                        MediaQuery.of(context)
                                                                            .textScaleFactor,
                                                                    fontSizeDelta:
                                                                        -4,
                                                                  ),
                                                              maxLines: 2,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    )),
                                              ),
                                            ],
                                          ),
                                          // child: Column(
                                          //   crossAxisAlignment:
                                          //       CrossAxisAlignment.start,
                                          //   children: <Widget>[
                                          //     Padding(
                                          //       padding: EdgeInsets.all(3),
                                          //       child: Row(
                                          //         mainAxisAlignment:
                                          //             MainAxisAlignment.start,
                                          //         children: <Widget>[
                                          //           Expanded(
                                          //             flex: 1,
                                          //             child: Container(
                                          //               width: width * 0.15,
                                          //               child: Text(
                                          //                   snapshot.data[index]
                                          //                       .breed,
                                          //                   style:
                                          //                       Theme.of(
                                          //                               context)
                                          //                           .textTheme
                                          //                           .bodyText2
                                          //                           .apply(
                                          //                             fontSizeFactor:
                                          //                                 MediaQuery.of(context)
                                          //                                     .textScaleFactor,
                                          //                             fontSizeDelta:
                                          //                                 -2,
                                          //                           ),
                                          //                   textAlign: TextAlign
                                          //                       .start),
                                          //             ),
                                          //           ),
                                          //           Container(
                                          //             width: width * 0.25,
                                          //             child: Text(
                                          //               "${AppLocalizations.of(context).translate(category.name)}",
                                          //               style: Theme.of(context)
                                          //                   .textTheme
                                          //                   .bodyText2
                                          //                   .apply(
                                          //                       fontSizeFactor:
                                          //                           MediaQuery.of(
                                          //                                   context)
                                          //                               .textScaleFactor,
                                          //                       fontSizeDelta:
                                          //                           3,
                                          //                       color: Colors
                                          //                           .black),
                                          //               textAlign:
                                          //                   TextAlign.center,
                                          //               softWrap: true,
                                          //             ),
                                          //           ),
                                          //           Expanded(
                                          //             flex: 2,
                                          //             child: Container(
                                          //               width: width * 0.25,
                                          //               //height: height * 0.1,
                                          //               child: Text(
                                          //                 getCity(snapshot
                                          //                     .data[index]),
                                          //                 //"abcdefghijklmn",
                                          //                 style:
                                          //                     Theme.of(context)
                                          //                         .textTheme
                                          //                         .bodyText2
                                          //                         .apply(
                                          //                           fontSizeFactor:
                                          //                               MediaQuery.of(context)
                                          //                                   .textScaleFactor,
                                          //                           fontSizeDelta:
                                          //                               -4,
                                          //                           color: Colors
                                          //                               .grey,
                                          //                         ),
                                          //                 textAlign:
                                          //                     TextAlign.start,

                                          //                 maxLines: 2,
                                          //                 // softWrap: true,
                                          //                 overflow: TextOverflow
                                          //                     .visible,
                                          //               ),
                                          //             ),
                                          //           ),
                                          //         ],
                                          //       ),
                                          //     ),
                                          //     Padding(
                                          //       padding: const EdgeInsets.only(
                                          //           top: 8.0),
                                          //       child: Row(
                                          //         mainAxisAlignment:
                                          //             MainAxisAlignment.end,
                                          //         children: <Widget>[
                                          //           Expanded(
                                          //             flex: 1,
                                          //             child: Container(
                                          //               width: width * 0.40,
                                          //               child: Row(
                                          //                 children: <Widget>[
                                          //                   Icon(
                                          //                     Icons.gavel,
                                          //                     color: Theme.of(
                                          //                             context)
                                          //                         .primaryColor,
                                          //                   ),
                                          //                   Padding(
                                          //                       padding: EdgeInsets
                                          //                           .only(
                                          //                               right:
                                          //                                   3)),
                                          //                   Text(
                                          //                     getPrice(snapshot
                                          //                         .data[index]),
                                          //                     style: Theme.of(
                                          //                             context)
                                          //                         .textTheme
                                          //                         .bodyText2
                                          //                         .apply(
                                          //                           fontSizeFactor:
                                          //                               MediaQuery.of(context)
                                          //                                   .textScaleFactor,
                                          //                           fontSizeDelta:
                                          //                               -4,
                                          //                         ),
                                          //                     overflow:
                                          //                         TextOverflow
                                          //                             .ellipsis,
                                          //                   ),
                                          //                 ],
                                          //               ),
                                          //             ),
                                          //           ),
                                          //           Expanded(
                                          //             flex: 1,
                                          //             child: Container(
                                          //               width: width * 0.25,
                                          //               child: Row(
                                          //                 mainAxisAlignment:
                                          //                     MainAxisAlignment
                                          //                         .start,
                                          //                 children: <Widget>[
                                          //                   Icon(
                                          //                     MYBaazar.balance,
                                          //                     color: Theme.of(
                                          //                             context)
                                          //                         .primaryColor,
                                          //                   ),
                                          //                   Padding(
                                          //                       padding: EdgeInsets
                                          //                           .only(
                                          //                               right:
                                          //                                   3)),
                                          //                   Wrap(
                                          //                     children: <
                                          //                         Widget>[
                                          //                       Text(
                                          //                         "${snapshot.data[index].remainingQty} QTL",
                                          //                         style: Theme.of(
                                          //                                 context)
                                          //                             .textTheme
                                          //                             .bodyText2
                                          //                             .apply(
                                          //                               fontSizeFactor:
                                          //                                   MediaQuery.of(context).textScaleFactor,
                                          //                               fontSizeDelta:
                                          //                                   -4,
                                          //                             ),
                                          //                         maxLines: 2,
                                          //                       ),
                                          //                     ],
                                          //                   )
                                          //                 ],
                                          //               ),
                                          //             ),
                                          //           ),
                                          //         ],
                                          //       ),
                                          //     ),
                                          //   ],
                                          // ),
                                        ),
                                      ),
                                      // Align(
                                      //   alignment: AlignmentDirectional.centerEnd,
                                      //   child: Padding(
                                      //     padding: EdgeInsets.all(3),
                                      //     child: RaisedButton(
                                      //       color: Theme.of(context).primaryColor,
                                      //       onPressed: () {
                                      //         Navigator.of(context).pushNamed(
                                      //           ProdReqDetail.routeName,
                                      //           arguments: {
                                      //             "object": snapshot.data[index]
                                      //           },
                                      //         ).then((value) => setState(() {}));
                                      //       },
                                      //       child: Text("Bid",
                                      //           style: Theme.of(context)
                                      //               .textTheme
                                      //               .headline2
                                      //               .apply(
                                      //                 color: Colors.white,
                                      //               )),
                                      //       shape: RoundedRectangleBorder(
                                      //           borderRadius:
                                      //               BorderRadius.circular(30.0),
                                      //           side: BorderSide(
                                      //               color: Color(0xFF739b21))),
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
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
