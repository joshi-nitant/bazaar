import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CategoryScreen extends StatefulWidget {
  static final String routeName = "/category";
  static final String CATEGORY_LIST_SHARED_PREFERENCE = "category_list";

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String userType;

  // List<Category> categoryList = [
  //   Category(id: 1, name: "Castor", imgPath: "assests/images/rice.png"),
  //   Category(id: 2, name: "GroundNut", imgPath: "assests/images/rice.png"),
  //   Category(id: 3, name: "Maize", imgPath: "assests/images/rice.png"),
  //   Category(id: 4, name: "Cotton", imgPath: "assests/images/rice.png"),
  // ];

  void _saveToPreference(var jsonData) async {
    SharedPreferences sharedPreference = await SharedPreferences.getInstance();
    sharedPreference.setString(
        CategoryScreen.CATEGORY_LIST_SHARED_PREFERENCE, json.encode(jsonData));
    print("Data stored ${json.encode(jsonData)}");
  }

  Future<List<Category>> _getCategory() async {
    var response = await http.get(
      Utils.URL + "getData.php",
    );
    var jsonData = json.decode(response.body);
    List<Category> categories = [];
    for (var u in jsonData) {
      Category category = Category(
          id: u['cat_id'],
          name: u['category_name'],
          imgPath: u['category_image']);
      categories.add(category);
    }
    _saveToPreference(jsonData);
    //print(jsonData.toString());
    return categories;
  }

  void openDashboard(Category category) {
    Navigator.of(context).pushNamed(Dashboard.routeName, arguments: {
      'category': category,
      'userType': userType,
    });
  }

  GestureDetector categoryButton(AssetImage image) {
    return GestureDetector(
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(55.0)),
        child: CircleAvatar(
          backgroundImage: image,
          backgroundColor: Colors.white,
          radius: 55.0,
        ),
      ),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    var routeArgs =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    userType = routeArgs['userType'];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('app_title')),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder(
        future: _getCategory(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(25.0),
              child: Container(
                height: data.size.height,
                width: data.size.width,
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: snapshot.data.map<Widget>(
                        (category) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                Dashboard.routeName,
                                arguments: {
                                  'category': category,
                                  'userType': userType,
                                },
                              );
                            },
                            child: Column(
                              children: <Widget>[
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(55.0)),
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      Utils.URL + "images/" + category.imgPath,
                                    ),
                                    backgroundColor: Colors.white,
                                    radius: 55.0,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate(category.name),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 20.0,
                                  ),
                                ),
                                SizedBox(height: 15.0),
                              ],
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
          // return SingleChildScrollView(
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     crossAxisAlignment: CrossAxisAlignment.center,
          //     children: snapshot.data.map<Widget>(
          //       (category) {
          //         return GestureDetector(
          //           onTap: () {
          //             Navigator.of(context)
          //                 .pushNamed(Dashboard.routeName, arguments: {
          //               'category': category,
          //               'userType': userType,
          //             });
          //           },
          //           child: Column(
          //             children: <Widget>[
          //               Container(
          //                 width: 150,
          //                 height: 150,
          //                 decoration: BoxDecoration(
          //                     shape: BoxShape.circle,
          //                     image: DecorationImage(
          //                       fit: BoxFit.fill,
          //                       image: NetworkImage(
          //                         Utils.URL + "images/" + category.imgPath,
          //                       ),
          //                     )),
          //               ),
          //               Padding(
          //                 padding: EdgeInsets.all(8),
          //                 child: Text(
          //                   AppLocalizations.of(context)
          //                       .translate(category.name),
          //                   style: TextStyle(
          //                       fontSize: 22,
          //                       color: Color(0xFF739b21),
          //                       fontWeight: FontWeight.bold),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         );
          //       },
          //     ).toList(),
          //   ),
          // );
          // return GridView.builder(
          //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: 2,
          //       childAspectRatio:
          //           (snapshot.data.length / (snapshot.data.length + 1))),
          //   itemCount: snapshot.data.length,
          //   itemBuilder: (BuildContext context, int index) {
          //     return GestureDetector(
          //       onTap: () {
          //         Navigator.of(context)
          //             .pushNamed(Dashboard.routeName, arguments: {
          //           'category': snapshot.data[index],
          //           'userType': userType,
          //         });
          //       },
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         children: <Widget>[
          //           Container(
          //             width: 150,
          //             height: 150,
          //             decoration: BoxDecoration(
          //                 shape: BoxShape.circle,
          //                 image: DecorationImage(
          //                   fit: BoxFit.fill,
          //                   image: NetworkImage(
          //                     Utils.URL +
          //                         "images/" +
          //                         snapshot.data[index].imgPath,
          //                   ),
          //                 )),
          //           ),
          //           Padding(
          //             padding: EdgeInsets.all(8),
          //             child: Text(
          //               AppLocalizations.of(context)
          //                   .translate(snapshot.data[index].name),
          //               style: TextStyle(
          //                   fontSize: 22,
          //                   color: Color(0xFF739b21),
          //                   fontWeight: FontWeight.bold),
          //             ),
          //           ),
          //         ],
          //       ),
          //     );
          //   },
          // );
        },
      ),
    );
  }
}
