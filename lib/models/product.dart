import 'package:flutter/foundation.dart';

class Product {
  String prod_id;
  String quantity;
  String price_expected;
  String location;
  String breed;
  String category_id;

  Product(
      {@required this.prod_id,
      @required this.quantity,
      @required this.price_expected,
      @required this.location,
      @required this.breed,
      @required this.category_id});
}
