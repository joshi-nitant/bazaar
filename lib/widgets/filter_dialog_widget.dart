import 'dart:collection';

import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/models/breed.dart';
import 'package:baazar/widgets/drop_down_widget.dart';
import 'package:flutter/material.dart';

Container buildBreedButton(BuildContext context, Breed breed,
    Function buttonHandler, Color backgroundColor) {
  return Container(
    width: 75.0,
    child: RaisedButton(
      color: backgroundColor,
      child: Text(
        breed.breed,
        style: TextStyle(
          color: backgroundColor == Colors.white
              ? Theme.of(context).primaryColor
              : Colors.white,
        ),
      ),
      onPressed: () {
        buttonHandler(breed);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
    ),
  );
}

Text normalText(String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 18.0,
    ),
  );
}

Text largeText(String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
  );
}

class Filter extends StatefulWidget {
  Function applyHandler;
  Function removeHandler;
  List<Breed> breedList;
  List<String> distanceList;
  int minPrice;
  int maxPrice;

  Filter({
    this.breedList,
    this.minPrice,
    this.maxPrice,
    this.distanceList,
    this.applyHandler,
    this.removeHandler,
  });

  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  RangeValues _values;
  RangeLabels _labels;
  static final Color primarycolor = Color(0xFF739b21);
  static final Color lightprimary = Color(0xFFc4d5a1);
  String selectedDistance;
  List<String> selectedBreed;
  int selectedMinPrice;
  int selectedMaxPrice;
  Color color;
  HashMap<Breed, Color> breedButtonColor;

  List<String> getBreedListAsString() {
    List<String> breedStringList = [];

    for (Breed breed in widget.breedList) {
      breedStringList.add(breed.breed);
    }
    return breedStringList;
  }

  @override
  void didChangeDependencies() {
    selectedBreed = [];
    selectedDistance = widget.distanceList[0];
    selectedMinPrice = widget.minPrice;
    selectedMaxPrice = widget.maxPrice;
    breedButtonColor = new HashMap();

    widget.breedList.forEach((breed) {
      breedButtonColor[breed] = Theme.of(context).primaryColor;
    });
    super.didChangeDependencies();
  }

  void setBreedList(Breed breed) {
    if (breedButtonColor[breed] == Theme.of(context).primaryColor) {
      setState(() {
        this.selectedBreed.add(breed.breed);
        breedButtonColor[breed] = Colors.white;
      });
    } else {
      setState(() {
        this.selectedBreed.remove(breed.breed);
        breedButtonColor[breed] = Theme.of(context).primaryColor;
      });
    }
  }

  void setDistance(String distance) {
    setState(() {
      this.selectedDistance = distance;
    });
  }

  @override
  Widget build(BuildContext context) {
    //print("building filter");
    _values =
        RangeValues(selectedMinPrice.toDouble(), selectedMaxPrice.toDouble());
    _labels =
        RangeLabels(selectedMinPrice.toString(), selectedMaxPrice.toString());
    final data = MediaQuery.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      child: Container(
        width: data.size.width,
        height: data.size.height * 0.73,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                'FILTER',
                style: TextStyle(
                    color: primarycolor,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                width: data.size.width * 0.97,
                //height: 65.0,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Select Breed',
                            style: TextStyle(
                              color: primarycolor,
                              fontSize: 17.0,
                            ),
                            textAlign: TextAlign.left,
                            //overflow: TextOverflow.clip,
                            //maxLines: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 10.0,
                children: widget.breedList
                    .map<Widget>(
                      (breed) => buildBreedButton(context, breed, setBreedList,
                          breedButtonColor[breed]),
                    )
                    .toList(),
              ),
              Container(
                width: data.size.width * 0.97,
                //height: 65.0,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Price Range',
                            style: TextStyle(
                              color: primarycolor,
                              fontSize: 17.0,
                            ),
                            textAlign: TextAlign.left,
                            //overflow: TextOverflow.clip,
                            //maxLines: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 35),
                child: RangeSlider(
                    min: widget.minPrice.toDouble(),
                    max: widget.maxPrice.toDouble(),
                    divisions: 10,
                    labels: _labels,
                    activeColor: primarycolor,
                    values: _values,
                    onChanged: (RangeValues values) {
                      setState(() {
                        this.selectedMinPrice = values.start.toInt();
                        this.selectedMaxPrice = values.end.toInt();
                        _values = values;
                        _labels = RangeLabels('${values.start.toString()}\ Rs',
                            '${values.end.toString()}\Rs');
                      });
                    }),
              ),
              Container(
                width: data.size.width * 0.97,
                //height: 65.0,
                // child: Card(
                //   shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(32.0)),
                //   child: Padding(
                //     padding: const EdgeInsets.all(8.0),
                //     child:
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: CategoryDropDown(
                        dropDownItems: widget.distanceList,
                        dropdownValue: this.selectedDistance,
                        categoryHandler: setDistance,
                        titleText: AppLocalizations.of(context)
                            .translate("Filter Km Drop"),
                        errorText: null,
                        hintText: AppLocalizations.of(context)
                            .translate("Drop Down Hint"),
                      ),
                      // child: Text(
                      //   'Select Region',
                      //   style: TextStyle(
                      //     color: primarycolor,
                      //     fontSize: 17.0,
                      //   ),
                      //   textAlign: TextAlign.left,
                      //   //overflow: TextOverflow.clip,
                      //   //maxLines: 5,
                      // ),
                    ),
                  ],
                  //   ),
                  // ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Container(
                    height: 50,
                    width: 100,
                    child: FlatButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            side: BorderSide(color: primarycolor)),
                        color: primarycolor,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(8.0),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.applyHandler(
                              this.selectedDistance,
                              this.selectedBreed,
                              this.selectedMinPrice,
                              this.selectedMaxPrice);
                        },
                        child: largeText('Apply')),
                  ),
                  Container(
                    height: 50,
                    width: 100,
                    child: FlatButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            side: BorderSide(color: primarycolor)),
                        color: primarycolor,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(8.0),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.removeHandler();
                        },
                        child: largeText('Remove')),
                  ),
                ],
              ),
            ],
          ),
          color: lightprimary,
        ),
      ),
    );
  }
}

// import 'package:baazar/models/breed.dart';
// import 'package:flutter/material.dart';

// import 'drop_down_widget.dart';

// List<String> selectedBreed;
// int minPriceSelecet;
// int maxPriceSelect;
// String selectedKilo;
// String displayBreed;
// String displayKilo;

// Container buildBreedButton(String text){
//   return Container(
//     width: 75.0,
//     child: RaisedButton(
//       color: primarycolor,
//       child: Text(
//         text,
//         style: TextStyle(
//           color: Colors.white,
//         ),
//       ),
//       onPressed: (){
//       },
//       shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(32.0)
//       ),
//     ),
//   );
// }

// List<String> getBreedList(List<Breed> breeList) {
//   List<String> breedStringList = [];

//   for (Breed breed in breeList) {
//     breedStringList.add(breed.breed);
//   }
//   return breedStringList;
// }

// void breedHandler(String value) {
//   selectedBreed.add(value);
//   displayBreed = value;
// }

// String kilometerHandler(String value) {
//   selectedKilo = value;
//   displayKilo = value;
// }

// Future<void> showFilterDialog({
//   BuildContext context,
//   String title,
//   String buttonMessage,
//   Function buttonHandler,
//   List<String> dropdownItems,
//   List<Breed> breedList,
//   int minPrice,
//   int maxPrice,
// }) async {
//   displayBreed = getBreedList(breedList)[0];
//   selectedBreed = [];
//   minPriceSelecet = minPrice;
//   maxPriceSelect = maxPrice;
//   displayKilo = dropdownItems[0];
//   selectedKilo = null;
//   final data = MediaQuery.of(context);
//   const Color primarycolor = Color(0xFF739b21);
//   const Color lightprimary = Color(0xFFc4d5a1);
//   // minPrice = minPrice % 10;
//   // maxPrice = maxPrice % 10;

//   RangeValues _values = RangeValues(minPrice.toDouble(), maxPrice.toDouble());
//   RangeLabels _labels = RangeLabels(minPrice.toString(), maxPrice.toString());
//   print(breedList);
//   return showDialog<void>(
//     context: context,
//     barrierDismissible: false, // user must tap button!
//     builder: (BuildContext context) {
//       return AlertDialog(
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
//         title: Text(title),
//         content: StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             return SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(4.0),
//                 child: Container(
//                   //width: data.size.width,
//                   height: data.size.height * 0.5,
//                   child: Card(
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(32.0)),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         Container(
//                           width: data.size.width * 0.97,
//                           //height: 65.0,
//                           child: Card(
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(32.0)),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: <Widget>[
//                                   Expanded(
//                                     child: CategoryDropDown(
//                                         displayBreed, getBreedList(breedList),
//                                         (value) {
//                                       setState(() {
//                                         breedHandler(value);
//                                       });
//                                     }, "Select Breed"),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                         Container(
//                           width: data.size.width * 0.97,
//                           //height: 65.0,
//                           child: Card(
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(32.0)),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: <Widget>[
//                                   Expanded(
//                                     child: Text(
//                                       'Price Range',
//                                       style: TextStyle(
//                                         color: primarycolor,
//                                         fontSize: 17.0,
//                                       ),
//                                       textAlign: TextAlign.left,
//                                       //overflow: TextOverflow.clip,
//                                       //maxLines: 5,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.only(top: 35),
//                           child: RangeSlider(
//                               min: minPrice.toDouble(),
//                               max: maxPrice.toDouble(),
//                               divisions: 10,
//                               labels: _labels,
//                               activeColor: primarycolor,
//                               values: _values,
//                               onChanged: (RangeValues values) {
//                                 setState(() {
//                                   minPriceSelecet = values.start.toInt();
//                                   maxPriceSelect = values.end.toInt();
//                                   _values = values;
//                                   _labels = RangeLabels(
//                                       '${values.start.toString()}\ Rs',
//                                       '${values.end.toString()}\Rs');
//                                 });
//                               }),
//                         ),
//                         Container(
//                           width: data.size.width * 0.97,
//                           //height: 65.0,
//                           child: Card(
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(32.0)),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: <Widget>[
//                                   Expanded(
//                                     child: CategoryDropDown(
//                                         displayKilo, dropdownItems, (value) {
//                                       setState(() {
//                                         kilometerHandler(value);
//                                       });
//                                     }, "Select Region"),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     color: lightprimary,
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//         actions: <Widget>[
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: FlatButton(
//               child: Text(buttonMessage),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(32.0)),
//               color: Theme.of(context).primaryColor,
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 buttonHandler(selectedKilo, selectedBreed, minPriceSelecet,
//                     maxPriceSelect);
//               },
//             ),
//           ),
//         ],
//       );
//     },
//   );
// }
