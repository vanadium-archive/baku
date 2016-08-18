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
      FlutterDriver alice = await driverMap['Alice'];
      FlutterDriver bob = await driverMap['Bob'];
      String textToSend = 'Hi, my name is Alice.  It\'s nice to meet you.';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      String textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      String textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));

      textToSend = 'I\'m Bob. It\'s a pleasure to meet you, Alice.';
      await bob.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bob.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));

      textToSend = 'What do you do for a living Bob?';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));

      textToSend = 'I work at the bank.';
      await bob.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bob.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));
    }, timeout: new Timeout(new Duration(seconds: 60)));

    test('Joking', () async {
      FlutterDriver alice = await driverMap['Alice'];
      FlutterDriver bob = await driverMap['Bob'];
      String textToSend = 'Name some countries?';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bob.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bob.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      String textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      String textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));

      textToSend = 'US.';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));

      textToSend = 'That is it?';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bob.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bob.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));

      textToSend = 'Yes.';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));

      textToSend = 'Aren\'t UK, India, Singapore, Europe countries?';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bob.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await bob.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));

      textToSend = 'Nope, they are not countries, they are Foreign countries...';
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.setInputText(find.byValueKey(inputKey), textToSend);
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      await alice.tap(find.byValueKey(buttonKey));
      await new Future<Null>.delayed(new Duration(milliseconds: waitingTime));
      textAlice = await alice.getText(find.text(textToSend));
      print('Alice: $textAlice');
      textBob = await bob.getText(find.text(textToSend));
      print('Bob: $textBob');
      expect(textAlice, equals(textBob));
    }, timeout: new Timeout(new Duration(seconds: 60)));
  });
}
