// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:mdtest_api/driver_util.dart';

import '../lib/keys.dart';

const String clearHistoryUrl = 'http://baku-flutter-chat.appspot.com/clear_history';

Future<Null> clearChatHistory() async {
  HttpClient client = new HttpClient();
  HttpClientRequest request = await client.getUrl(Uri.parse(clearHistoryUrl));
  await request.close();
}

int waitingTime = 2000;

void main() {
  group('Chat App Test 1', () {
    DriverMap driverMap;

    setUpAll(() async {
      driverMap = new DriverMap();
    });

    setUp(() async {
      await clearChatHistory();
    });

    tearDownAll(() async {
      if (driverMap != null) {
        driverMap.closeAll();
      }
    });

    test('Greeting', () async {
      FlutterDriver bot1 = await driverMap['Bot1'];
      FlutterDriver bot2 = await driverMap['Bot2'];
      String textToSend = 'Hi, my name is Steve.  It\'s nice to meet you.';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      String textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      String textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));

      textToSend = 'I\'m Jack. It\'s a pleasure to meet you, Steve.';
      await bot2.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot2.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));

      textToSend = 'What do you do for a living Jack?';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));

      textToSend = 'I work at the bank.';
      await bot2.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot2.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));
    }, timeout: new Timeout(new Duration(seconds: 60)));

    test('Joking', () async {
      FlutterDriver bot1 = await driverMap['Bot1'];
      FlutterDriver bot2 = await driverMap['Bot2'];
      String textToSend = 'Name some countries?';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot2.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot2.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      String textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      String textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));

      textToSend = 'US.';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));

      textToSend = 'That is it?';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot2.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot2.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));

      textToSend = 'Yes.';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));

      textToSend = 'Aren\'t UK, India, Singapore, Europe countries?';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot2.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot2.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));

      textToSend = 'Nope, they are not countries, they are Foreign countries...';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bot1.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textBot1 = await bot1.getText(find.text(textToSend));
      print('Bot 1: $textBot1');
      textBot2 = await bot2.getText(find.text(textToSend));
      print('Bot 2: $textBot2');
      expect(textBot1, equals(textBot2));
    }, timeout: new Timeout(new Duration(seconds: 60)));
  });
}
