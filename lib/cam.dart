import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as VImage;
import 'package:path_provider/path_provider.dart';

import 'main.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  final String pin;

  const TakePictureScreen({
    Key key,
    @required this.camera,
    @required this.pin,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  var result = "";
  List<TextSpan> resultTextSpan = [];

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  recogniseText(_userImageFile) async {

    VImage.Image image = VImage.decodeImage(_userImageFile.readAsBytesSync());
    VImage.grayscale(image);
    // Assuming the source image is a PNG image
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    File imgFile = await File(tempPath + '/tempimage.png').create(recursive: true);
    imgFile.writeAsBytesSync(VImage.encodePng(image));
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(imgFile);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();

    VisionText readText = await recognizeText.processImage(myImage);
    result = "";
    resultTextSpan = [];
    String winningNumber = widget.pin;
    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        var lineArray = (line.text).split(" ");
        lineArray.forEach((element) {
          bool hasLetters = (element).contains(new RegExp(r'[A-Z]'));
          if(!hasLetters){
            if (winningNumber.contains(element)){
              if(lineArray.last == element){
                resultTextSpan.add(new TextSpan(
                    text: element + "\n",
                    style: TextStyle(color: Colors.red, fontSize: 45)));
              }else{
                resultTextSpan.add(new TextSpan(
                    text: element + " ",
                    style: TextStyle(color: Colors.red, fontSize: 45)));
              }
            } else {
              if(lineArray.last == element){
                resultTextSpan.add(new TextSpan(
                    text: element + "\n",
                    style: TextStyle(color: Colors.white, fontSize: 45)));
              }else{
                resultTextSpan.add(new TextSpan(
                    text: element + " ",
                    style: TextStyle(color: Colors.white, fontSize: 45)));
              }
            }
          }

        });
      /*  setState(() {
          result = result + ' ' + line.text + '\n';
        });*/
      }
    }
    debugPrint(result);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => new DisplayPictureScreen(
          // Pass the automatically generated path to
          // the DisplayPictureScreen widget.
          imagePath: result,
          pin: widget.pin,
          resultTextSpan: resultTextSpan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TOTO SCANNER : Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            //return CameraPreview(_controller);
            return new Stack(
              alignment: FractionalOffset.center,
              children: <Widget>[
                CameraPreview(_controller),
              ],
            );
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        mini: false,
        child: Icon(Icons.camera_alt),
        backgroundColor: Colors.cyanAccent,
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();
            // File imageFile = File(image.path);
            File croppedFile = await ImageCropper.cropImage(
                sourcePath: image.path,
                aspectRatioPresets: [
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9
                ],
                androidUiSettings: AndroidUiSettings(
                    toolbarTitle: 'Cropper',
                    toolbarColor: Colors.deepOrange,
                    toolbarWidgetColor: Colors.white,
                    initAspectRatio: CropAspectRatioPreset.ratio16x9,
                    lockAspectRatio: false),
                iosUiSettings: IOSUiSettings(
                  minimumAspectRatio: 1.0,
                ));


            recogniseText((croppedFile));

            // If the picture was taken, display it on a new screen.

          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final List<TextSpan> resultTextSpan;
  final String pin;

  const DisplayPictureScreen(
      {Key key, this.imagePath, this.pin, this.resultTextSpan})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display Result')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
          child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: resultTextSpan),
      )),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FloatingActionButton(
                heroTag: "back",
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.navigate_before),
              ),
              FloatingActionButton(
                heroTag: "home",
                onPressed: () async {
                  final cameras = await availableCameras();
                  // Get a specific camera from the list of available cameras.
                  final firstCamera = cameras.first;

                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => NumberScreen(camera: firstCamera)),
                      ModalRoute.withName("/Home"));
                },
                child: Icon(Icons.home),
              )
            ],
          ),
        ),

      //body: Image.file(File(imagePath)),
    );
  }
}

