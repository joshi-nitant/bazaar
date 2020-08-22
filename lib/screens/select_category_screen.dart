import 'dart:convert';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/classes/utils.dart';
import 'package:baazar/models/breed.dart';
import 'package:baazar/models/category.dart';
import 'package:baazar/models/user.dart';
import 'package:baazar/screens/dashboard_screen.dart';
import 'package:baazar/screens/error_screen.dart';
import 'package:baazar/widgets/footer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int userId;
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
    //print("Data stored ${json.encode(jsonData)}");
  }

  Future<int> _getUserId() async {
    SharedPreferences sharedPreference = await SharedPreferences.getInstance();
    if (sharedPreference.getInt(User.USER_ID_SHARED_PREFERNCE) == null) {
      return -1;
    } else {
      return sharedPreference.getInt(User.USER_ID_SHARED_PREFERNCE);
    }
  }

  Future<List<Breed>> _getCategoryBreed(String categoryId) async {
    List<Breed> breedList = [];
    //print("here1");
    var response = await http.post(
      Utils.URL + "getBreed.php",
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'cat_id': categoryId,
        },
      ),
    );

    var jsondata = json.decode(response.body);

    if (jsondata['response_code'] == 101) {
      for (var breed in jsondata['breed_list']) {
        breedList.add(new Breed(
          id: int.parse(breed['breed_id']),
          catId: int.parse(breed['cat_id']),
          breed: breed['breed'],
        ));
      }
    }

    return breedList;
  }

  Future<List<Category>> _getCategory() async {
    var response = await http.get(
      Utils.URL + "getCategory.php",
    );
    this.userId = await _getUserId();
    print(userId);
    var jsonData = json.decode(response.body);
    List<Category> categories = [];
    for (var u in jsonData) {
      List<Breed> breedList = await _getCategoryBreed(u['cat_id']);

      Category category = Category(
        id: u['cat_id'],
        name: u['category_name'],
        imgPath: u['category_image'],
        breed: breedList,
      );

      categories.add(category);
    }
    _saveToPreference(jsonData);

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
    //SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);

    final data = MediaQuery.of(context);
    var routeArgs =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    userType = routeArgs['userType'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('app_title'),
          style: Theme.of(context).textTheme.headline1.apply(
                color: Colors.white,
              ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
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
          if (snapshot.data.length == 0) {
            return NoProduct("CATEGORY ERROR");
          }
          return SafeArea(
            child: Container(
              height: data.size.height,
              width: data.size.width,
              child: Column(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Container(
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
                                        'userId': userId,
                                      },
                                    );
                                  },
                                  child: Column(
                                    children: <Widget>[
                                      Card(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50.0)),
                                        child: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            Utils.URL +
                                                "images/" +
                                                category.imgPath,
                                          ),
                                          radius: 50.0,
                                        ),
                                      ),
                                      Text(
                                          AppLocalizations.of(context)
                                              .translate(category.name),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1
                                              .apply(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              )),
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
                  Container(
                    child: FooterWidget(),
                  )
                ],
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
