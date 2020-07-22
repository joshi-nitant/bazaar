import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class Language {
  final String code;
  final String name;
  final String dialect;
  final String path;

  Language({
    @required this.code,
    @required this.name,
    @required this.dialect,
    @required this.path,
  });
}
