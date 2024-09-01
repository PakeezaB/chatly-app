import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

Widget displayImage(File? imageFile, String? imageUrl) {
  if (kIsWeb) {
    return imageUrl != null && imageUrl.isNotEmpty
        ? Image.network(imageUrl)
        : const Icon(Icons.image, size: 50);
  } else {
    return imageFile != null
        ? Image.file(imageFile)
        : imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(imageUrl)
            : const Icon(Icons.image, size: 50);
  }
}
