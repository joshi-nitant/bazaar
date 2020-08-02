import 'package:baazar/models/user.dart';
import 'package:flutter/material.dart';

import 'category.dart';

class Requirement {
  String id;
  String quantity;
  String price_expected;
  String breed;
  String category_id;
  String remainingQty;
  // String state;
  // String city;
  // String latitude;
  // String longitude;
  Category category;
  // String address;
  // String postalCode;
  String userId;

  Requirement({
    @required this.id,
    @required this.quantity,
    @required this.price_expected,
    @required this.breed,
    @required this.category_id,
    // @required this.state,
    // @required this.city,
    // @required this.latitude,
    // @required this.longitude,
    @required this.remainingQty,
    this.category,
    //this.address,
    //this.postalCode,
    this.userId,
  });
}
