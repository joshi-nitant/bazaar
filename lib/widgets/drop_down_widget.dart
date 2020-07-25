import 'package:baazar/classes/app_localizations.dart';
import 'package:baazar/models/category.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:flutter/material.dart';

class CategoryDropDown extends StatefulWidget {
  String dropdownValue = 'One';
  List<String> dropDownItems;
  Function categoryHandler;

  CategoryDropDown(
    this.dropdownValue,
    this.dropDownItems,
    this.categoryHandler,
  );
  @override
  _CategoryDropDownState createState() => _CategoryDropDownState();
}

class _CategoryDropDownState extends State<CategoryDropDown> {
  String _myActivity = '';
  String _myActivityResult = '';

  List<Map<String, String>> getItemsAsMap() {
    List<Map<String, String>> itemList = [];
    for (String cat in widget.dropDownItems) {
      Map<String, String> map = {"display": cat, "value": cat};
      itemList.add(map);
    }
    return itemList;
  }

  @override
  Widget build(BuildContext context) {
    final mdata = MediaQuery.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      child: DropDownFormField(
        titleText: 'Category',
        hintText: 'Please choose one',
        value: widget.dropdownValue,
        // onSaved: (value) {
        //   setState(() {
        //     _myActivity = value;
        //   });
        // },
        onChanged: (value) {
          widget.categoryHandler(value);
        },
        dataSource: getItemsAsMap(),
        textField: 'display',
        valueField: 'value',
      ),
    );
    //       child: DropdownButtonFormField<String>(
    //         decoration: InputDecoration(
    //           enabledBorder: UnderlineInputBorder(
    //             borderSide: BorderSide(color: Colors.white),
    //           ),
    //         ),
    //         onChanged: (value) {
    //           widget.categoryHandler(value);
    //         },
    //         items: widget.dropDownItems
    //             .map(
    //               (category) => DropdownMenuItem<String>(
    //                 value: category,
    //                 child: Padding(
    //                   padding: const EdgeInsets.all(8.0),
    //                   child: Text(
    //                       AppLocalizations.of(context).translate(category)),
    //                 ),
    //               ),
    //             )
    //             .toList(),
    //       ),
    //     ),
    //   ),
    // );

    // //       child: DropdownButton<String>(

    // //         value: widget.dropdownValue,
    // //         icon: Icon(Icons.arrow_downward),
    // //         iconSize: 24,
    // //         elevation: 16,
    // //         style: TextStyle(color: Theme.of(context).primaryColor),
    // //         underline: Container(
    // //           height: 2,
    // //           color: Theme.of(context).primaryColor,
    // //         ),
    // //         onChanged: (String newValue) {
    // //           widget.categoryHandler(newValue);
    // //         },
    // //         items: widget.dropDownItems
    // //             .map<DropdownMenuItem<String>>((String value) {
    // //           return DropdownMenuItem<String>(
    // //             value: value,
    // //             child: Text(AppLocalizations.of(context).translate(value)),
    // //           );
    // //         }).toList(),
    // //       ),
    // //     ),
    // //   ),
    // // );
    // // return DropdownButton<String>(
    // //   value: widget.dropdownValue,
    // //   icon: Icon(Icons.arrow_downward),
    // //   iconSize: 24,
    // //   elevation: 16,
    // //   style: TextStyle(color: Colors.deepPurple),
    // //   underline: Container(
    // //     height: 2,
    // //     color: Colors.deepPurpleAccent,
    // //   ),
    // //   onChanged: (String newValue) {
    // //     widget.categoryHandler(newValue);
    // //   },
    // //   items: widget.dropDownItems.map<DropdownMenuItem<String>>((String value) {
    // //     return DropdownMenuItem<String>(
    // //       value: value,
    // //       child: Text(AppLocalizations.of(context).translate(value)),
    // //     );
    // //   }).toList(),
    // );
  }
}
