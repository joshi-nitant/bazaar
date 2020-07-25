import 'package:flutter/foundation.dart';

class Product {
  String id;
  String quantity;
  String price_expected;
  String breed;
  String category_id;
  String latitude;
  String longitude;
  String state;
  String city;
  String image;
  String remaining_qty;

  Product({
    @required this.id,
    @required this.quantity,
    @required this.price_expected,
    @required this.breed,
    @required this.category_id,
    @required this.state,
    @required this.city,
    @required this.latitude,
    @required this.longitude,
    @required this.remaining_qty,
  });
}
