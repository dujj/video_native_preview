import 'package:flutter/material.dart';

import 'package:video_native_preview/video_native_preview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          constraints: const BoxConstraints.expand(),
          child: const VideoNativePreview(
            initialUrl:
                'https://user-images.githubusercontent.com/9443889/188844287-12bb7c20-0559-4247-8205-aaad31058a4a.mp4',
          ),
        ),
      ),
    );
  }
}
