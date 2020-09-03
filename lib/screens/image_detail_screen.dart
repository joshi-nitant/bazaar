import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baazar/classes/app_localizations.dart';

class DetailScreen extends StatefulWidget {
  final String tag;
  final String url;
  bool isNetworkImage;
  File imageFile;
  DetailScreen(
      {Key key,
      @required this.tag,
      @required this.url,
      @required this.isNetworkImage,
      this.imageFile})
      : assert(tag != null),
        assert(url != null),
        super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
  }

  @override
  void dispose() {
    //SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.imageFile);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('Trade Details'),
          style: Theme.of(context).textTheme.headline1.apply(
                color: Colors.white,
              ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        child: Center(
          child: Hero(
            tag: widget.tag,
            child: widget.isNetworkImage
                ? CachedNetworkImage(
                    imageUrl: widget.url,
                    placeholder: (context, url) => Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        child: new CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => new Icon(Icons.error),
                  )
                : Image.file(widget.imageFile),
          ),
        ),
      ),
    );
  }
}
