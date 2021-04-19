import 'dart:async';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ocr/pin.dart';
import 'package:flutter_ocr/cam.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: NumberScreen(camera: firstCamera,),
      //   home: TakePictureScreen(
      // Pass the appropriate camera to the TakePictureScreen widget.
      //    camera: firstCamera,
      //  ),
    ),
  );
}

// A screen that allows users to key in the 6 numbers.
class NumberScreen extends StatefulWidget {
  final CameraDescription camera;

  const NumberScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  NumberScreenState createState() => NumberScreenState();
}

class NumberScreenState extends State<NumberScreen> {

  final BoxDecoration pinPutDecoration = BoxDecoration(
    color: const Color.fromRGBO(43, 46, 66, 1),
    borderRadius: BorderRadius.circular(10.0),
    border: Border.all(
      color: const Color.fromRGBO(126, 203, 224, 1),
    ),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TOTO SCANNER : Winning Numbers')),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'Enter the Winning Numbers into the Text Area',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: PinEntryTextField(
              fields: 7,
              fieldWidth: 50.0,
              fontSize: 20.0,
              showFieldAsBox: true,
              onSubmit: (String pin){
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => TakePictureScreen(
                        // Pass the appropriate camera to the TakePictureScreen widget.
                            camera: widget.camera,
                          ),
                    ));
               /* showDialog(
                    context: context,
                    builder: (context){
                      return AlertDialog(
                        title: Text("Pin"),
                        content: Text('Pin entered is $pin'),
                      );
                    }
                );*/ //end showDialog()
              }, // end onSubmit
            ), // end PinEntryTextField()
          ), // end Padding()
        ],
      ),

    );
  }
}


