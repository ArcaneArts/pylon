import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

class UriPylonCodecUtils {
  static void setUri(Uri uri) {
    if (kIsWeb) {
      html.window.history.pushState(null, "", uri.toString());
    }
  }

  static Uri getUri() {
    if (kIsWeb) {
      return Uri.parse(html.window.location.href);
    }
    return Uri.base;
  }

  static String toUrlValue(dynamic value) {
    String out = "xENCODE_ERROR";

    if (value is String) {
      out = "s$value";
    } else if (value is int) {
      out = "i$value";
    } else if (value is double) {
      out = "d$value";
    } else if (value is bool) {
      out = "b${value ? "y" : "n"}";
    } else if (value is DateTime) {
      out = "t${value.toIso8601String()}";
    } else {
      out = "j${jsonEncode(value)}";
    }

    out = "*$out";

    return out;
  }

  static dynamic fromUrlValue(String value) {
    assert(value.startsWith("*"));
    String t = value.substring(1, 2);
    String v = value.substring(2);

    if (t == "s") {
      return v;
    } else if (t == "i") {
      return int.parse(v);
    } else if (t == "d") {
      return double.parse(v);
    } else if (t == "b") {
      return v == "1";
    } else if (t == "t") {
      return DateTime.parse(v);
    } else if (t == "j") {
      return jsonDecode(v);
    } else {
      throw "Unknown type: $t";
    }
  }

  static String doubleToBase36String(double value, {int decimalPlaces = 6}) {
    final integerPart = value.floor();
    final fraction = value - integerPart;
    final fractionAsInt = (fraction * pow(10, decimalPlaces)).round();
    final encodedInt = integerPart.toRadixString(36);
    final encodedFrac = fractionAsInt.toRadixString(36);

    return '$encodedInt.$encodedFrac';
  }

  static double base36StringToDouble(String base36String,
      {int decimalPlaces = 6}) {
    final parts = base36String.split('.');
    if (parts.length != 2) {
      throw const FormatException('Expected format "int.frac" in base36');
    }

    final intPart = int.parse(parts[0], radix: 36);
    final fracPart = int.parse(parts[1], radix: 36);
    final fracString = fracPart.toString().padLeft(decimalPlaces, '0');
    final doubleString = '$intPart.$fracString';

    return double.parse(doubleString);
  }

  static void updateUri(BuildContext context) {
    if (kIsWeb) {
      Future.delayed(
          const Duration(milliseconds: 1000),
          () => UriPylonCodecUtils.setUri(Pylon.visibleBroadcastToUri(
              context, UriPylonCodecUtils.getUri())));
    }
  }
}
