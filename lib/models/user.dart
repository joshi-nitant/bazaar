import 'package:flutter/cupertino.dart';

class User {
  static final String USER_ID_SHARED_PREFERNCE = "user_id";
  static final String USER_NAME_SHARED_PREFERNCE = "user_password";
  static final String USER_PASSWORD_SHARED_PREFERNCE = "user_name";

  String id;
  String latitude;
  String longitude;
  String name;
  String contactNumber;
  String state;
  String city;
  String pincode;
  String panCard;
  String address;

  User({
    this.id,
    this.latitude,
    this.longitude,
    this.address,
    this.state,
    this.city,
    this.pincode,
    this.contactNumber,
  });
}
