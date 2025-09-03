import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server/gmail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QRViewExample(),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  final String employeeName = "Jean Mark Arellano";
  String? lastResult;

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      final qrCodeText = scanData.code;
      if (qrCodeText == "EMPLOYEE_TIME_IN_QR_2025" && lastResult == null) {
        setState(() {
          lastResult = "Employee: $employeeName";
        });

        try {
          await _sendEmailDirect(); // send email
        } catch (e) {
          print("Error sending email: $e");
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to send email")),
          );
        }
      }
    });
  }

  Future<void> _sendEmailDirect() async {
    // ⚠️ Use a dedicated Gmail account for sending
    String username = 'dbro.iro@gmail.com'; // replace with your Gmail
    String password = 'ilfw qjqw zcco etov'; // Gmail App Password

    final smtpServer = gmail(username, password);

    final String today =
    DateFormat("yyyy-MM-dd – HH:mm:ss").format(DateTime.now());

    final message = mailer.Message()
      ..from = mailer.Address(username, 'DBro - Time Logger')
      ..recipients.add('jl.g.hapa@gmail.com') // manager email
      ..subject =
          'Time IN ~ $employeeName / ${DateFormat("yyyy-MM-dd").format(DateTime.now())}'
      ..text = '''
        Attached here is my time in for today, thanks!
        
        Employee: $employeeName
        Time IN: $today
        QR Code: EMPLOYEE_TIME_IN_QR_2025
      ''';

    try {
      final sendReport = await mailer.send(message, smtpServer);
      print('Message sent: $sendReport');

      if (!mounted) return;

      // SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Time IN recorded successfully!")),
      );

      // Local notification
      await flutterLocalNotificationsPlugin.show(
        0,
        'Time IN Recorded',
        'Email sent successfully for $employeeName',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'time_in_channel',
            'Time IN Notifications',
            channelDescription: 'Notifications for employee time in',
            importance: Importance.max,
            priority: Priority.max,
            ticker: 'ticker',
          ),
        ),
      );
    } on mailer.MailerException catch (e) {
      print('Message not sent. \n$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send email.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Time IN - $employeeName")),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (lastResult != null)
                  ? Text("Scanned: $lastResult")
                  : const Text("Scan the Time IN QR"),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
