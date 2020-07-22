import 'package:flutter/foundation.dart';

class Requirement {
  String req_id, quantity, price_expected, location, breed, category_id;

  Requirement(
      {@required this.req_id,
      @required this.quantity,
      @required this.price_expected,
      @required this.location,
      @required this.breed,
      @required this.category_id});
}
