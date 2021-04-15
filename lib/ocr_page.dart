import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobile_vision/flutter_mobile_vision.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

List<CameraDescription> cameras;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    try {
      // initialize cameras.
      cameras = await availableCameras();
      // initialize camera controllers.
      _controller = new CameraController(cameras[0], ResolutionPreset.medium);
      await _controller.initialize();
    } on CameraException catch (_) {
      // do something on error.
    }
    if (!mounted) return;
    setState(() {
      _isReady = true;
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _takePicturePressed() {
    _takePicture().then((String filePath) {
      if (mounted) {
         }
    });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String> _takePicture() async {
    if (!_isReady) {
     // print("Controller is not initialized");
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String photoDir = '${extDir.path}/Photos/image_test';
    await Directory(photoDir).create(recursive: true);
    final String filePath = '$photoDir/${timestamp()}.jpg';

    if (_controller.value.isTakingPicture) {
      print("Currently already taking a picture");
      return null;
    }

    try {
      await _controller.takePicture();
    } on CameraException catch (e) {
      print("camera exception occured: $e");
      return null;
    }

    return filePath;
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("TOTO SCANNER"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CameraPreview(_controller),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: RaisedButton.icon(
                  icon: Icon(Icons.camera),
                  label: Text("Take Picture"),
                  onPressed: _takePicturePressed,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class OCRPage extends StatefulWidget {
  @override
  _OCRPageState createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {

  int _ocrCamera = FlutterMobileVision.CAMERA_BACK;
  String _text = "TEXT";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white70,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('OCR In Flutter'),
            centerTitle: true,
          ),
          body: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_text,style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                ),
                Center(
                  child: RaisedButton(
                   onPressed: _read,
                   child: Text('Scanning',
                     style: TextStyle(fontSize: 16),
                   ),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }

  Future<Null> _read() async {
    List<OcrText> texts = [];
    try {
      texts = await FlutterMobileVision.read(
        camera: _ocrCamera,
        waitTap: true,
      );

      setState(() {
        _text = texts[0].value;
      });
    } on Exception {
      texts.add( OcrText('Failed to recognize text'));
    }
  }
}