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
  double appBarHeight = 44;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black12,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          centerTitle: false,
          title: const Text(
            '123',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black12,
          toolbarHeight: appBarHeight,
          toolbarOpacity: 0.5,
        ),
        body: Container(
          constraints: const BoxConstraints.expand(),
          color: Colors.black12,
          child: VideoNativePreview(
            // type: 'audio',
            initialUrl:
                'https://user-images.githubusercontent.com/9443889/188844287-12bb7c20-0559-4247-8205-aaad31058a4a.mp4',
            onChangeAppBar: (status) {
              debugPrint('onChangeAppBar : $status');
              if (status == 'true') {
                setState(() {
                  appBarHeight = 0;
                });
              } else {
                setState(() {
                  appBarHeight = 44;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}
