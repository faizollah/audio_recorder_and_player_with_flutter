import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:intl/intl.dart' show DateFormat;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterSoundRecorder _myRecorder;
  final audioPlayer = AssetsAudioPlayer();
  String filePath;
  bool _play = false;
  String _recorderTxt = '00:00:00';

  @override
  void initState() {
    super.initState();
    startIt();
  }

  void startIt() async {
    filePath = '/sdcard/Download/temp.wav';
    _myRecorder = FlutterSoundRecorder();

    await _myRecorder.openAudioSession(
        focus: AudioFocus.requestFocusAndStopOthers,
        category: SessionCategory.playAndRecord,
        mode: SessionMode.modeDefault,
        device: AudioDevice.speaker);
    await _myRecorder.setSubscriptionDuration(Duration(milliseconds: 10));
    await initializeDateFormatting();

    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 400.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(255, 2, 199, 226), Color.fromARGB(255, 6, 75, 210)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.elliptical(MediaQuery.of(context).size.width, 100.0),
                ),
              ),
              child: Center(
                child: Text(
                  _recorderTxt,
                  style: TextStyle(fontSize: 70),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                buildElevatedButton(
                  icon: Icons.mic,
                  iconColor: Colors.red,
                  f: record,
                ),
                SizedBox(
                  width: 30,
                ),
                buildElevatedButton(
                  icon: Icons.stop,
                  iconColor: Colors.black,
                  f: stopRecord,
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                buildElevatedButton(
                  icon: Icons.play_arrow,
                  iconColor: Colors.black,
                  f: startPlaying,
                ),
                SizedBox(
                  width: 30,
                ),
                buildElevatedButton(
                  icon: Icons.stop,
                  iconColor: Colors.black,
                  f: stopPlaying,
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 10.0,
              ),
              onPressed: () {
                setState(() {
                  _play = !_play;
                });
                if (_play) startPlaying();
                if (!_play) stopPlaying();
              },
              icon: _play
                  ? Icon(
                      Icons.stop,
                    )
                  : Icon(Icons.play_arrow),
              label: _play
                  ? Text(
                      "Stop Playing",
                      style: TextStyle(
                        fontSize: 25,
                      ),
                    )
                  : Text(
                      "Start Playing",
                      style: TextStyle(
                        fontSize: 25,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  ElevatedButton buildElevatedButton({IconData icon, Color iconColor, Function f}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(5.0),
        side: BorderSide(
          color: Colors.orange,
          width: 3.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        primary: Colors.white,
        elevation: 10.0,
      ),
      onPressed: f,
      icon: Icon(
        icon,
        color: iconColor,
        size: 35.0,
      ),
      label: Text(''),
    );
  }

  Future<void> record() async {
    Directory dir = Directory(path.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync();
    }
    _myRecorder.openAudioSession();
    await _myRecorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
    );

    StreamSubscription _recorderSubscription = _myRecorder.onProgress.listen((e) {
      var date = DateTime.fromMillisecondsSinceEpoch(e.duration.inMilliseconds, isUtc: true);
      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);

      setState(() {
        _recorderTxt = txt.substring(0, 8);
      });
    });
    _recorderSubscription.cancel();
  }

  Future<String> stopRecord() async {
    _myRecorder.closeAudioSession();
    return await _myRecorder.stopRecorder();
  }

  Future<void> startPlaying() async {
    audioPlayer.open(
      Audio.file(filePath),
      autoStart: true,
      showNotification: true,
    );
  }

  Future<void> stopPlaying() async {
    audioPlayer.stop();
  }
}
