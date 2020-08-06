import 'package:baazar/models/breed.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/foundation.dart';

class Category {
  String id;
  String name;
  String imgPath;
  List<Breed> breed;

  Category({
    @required this.id,
    @required this.name,
    @required this.imgPath,
    this.breed,
  });
}
