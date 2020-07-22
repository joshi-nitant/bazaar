import 'package:baazar/classes/app_localizations.dart';
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
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: widget.dropdownValue,
      icon: Icon(Icons.arrow_downward),
      iconSize: 24,
      elevation: 16,
      style: TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String newValue) {
        widget.categoryHandler(newValue);
      },
      items: widget.dropDownItems.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(AppLocalizations.of(context).translate(value)),
        );
      }).toList(),
    );
  }
}
