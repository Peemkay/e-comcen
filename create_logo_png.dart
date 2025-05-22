import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Define paths
  final svgPath = 'assets/images/nas_logo.svg';
  final pngLogoPath = 'assets/images/nas_logo.png';
  final pngIconPath = 'assets/images/nas_icon.png';

  // Ensure the directory exists
  final directory = Directory('assets/images');
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
    print('Created directory: assets/images');
  }

  // Check if SVG file exists
  if (!File(svgPath).existsSync()) {
    print('Error: SVG file not found at $svgPath');
    exit(1);
  }

  try {
    // Load the SVG file
    final svgString = File(svgPath).readAsStringSync();
    final svgDrawableRoot = await svg.fromSvgString(svgString, 'nas_logo');

    // Create a picture from the SVG
    final picture = svgDrawableRoot.toPicture(size: const Size(200, 200));

    // Convert the picture to an image
    final img = await picture.toImage(200, 200);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    // Save the image as PNG
    if (byteData != null) {
      final buffer = byteData.buffer.asUint8List();
      File(pngLogoPath).writeAsBytesSync(buffer);
      File(pngIconPath).writeAsBytesSync(buffer);
      print('PNG files created successfully!');
      print('Logo saved to: $pngLogoPath');
      print('Icon saved to: $pngIconPath');
    } else {
      print('Failed to create PNG files: ByteData is null');
    }
  } catch (e) {
    print('Error converting SVG to PNG: $e');
  }

  exit(0);
}
