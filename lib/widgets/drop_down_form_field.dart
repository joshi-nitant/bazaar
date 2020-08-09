import 'package:baazar/classes/app_localizations.dart';
import 'package:flutter/material.dart';

class DropDownFormField extends StatefulWidget {
  final String titleText;
  final String hintText;
  final String errorText;
  final dynamic value;
  final List dataSource;
  final String textField;
  final String valueField;
  final Function onChanged;

  DropDownFormField({
    this.titleText,
    this.hintText,
    this.errorText,
    this.value,
    this.dataSource,
    this.textField,
    this.valueField,
    this.onChanged,
  });
  @override
  _DropDownFormFieldState createState() => _DropDownFormFieldState();
}

class _DropDownFormFieldState extends State<DropDownFormField> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      borderOnForeground: false,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 18.0),
        child: InputDecorator(
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.fromLTRB(14, 12, 8, 0),
            labelText: widget.titleText,
            labelStyle: Theme.of(context).textTheme.bodyText2.apply(
                  color: Theme.of(context).primaryColor,
                  fontSizeDelta: 4.0,
                ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              hint: Text(
                widget.hintText,
                style: Theme.of(context).textTheme.bodyText2.apply(
                    color: widget.errorText == null
                        ? Theme.of(context).primaryColor
                        : Colors.red),
              ),
              value: widget.value == '' ? null : widget.value,
              onChanged: (dynamic newValue) {
                widget.onChanged(newValue);
              },
              items: widget.dataSource.map((item) {
                return DropdownMenuItem<dynamic>(
                  value: item[widget.valueField],
                  child: Text(
                    item[widget.textField],
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
