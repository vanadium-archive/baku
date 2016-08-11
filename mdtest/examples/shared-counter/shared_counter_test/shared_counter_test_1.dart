// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:mdtest_api/driver_util.dart';

import 'keys.dart';
import 'utils.dart' as utils;

void main() {
  group('Count Test 1', () {
    DriverMap driverMap;

    setUpAll(() async {
      await utils.resetCounter();
      driverMap = new DriverMap();
    });

    tearDownAll(() async {
      if (driverMap != null) {
        driverMap.closeAll();
      }
    });

    test('all tap 1 time', () async {
      List<FlutterDriver> drivers = await Future.wait(driverMap.values);
      await new Future<Null>.delayed(new Duration(milliseconds: 5000));
      await Future.forEach(drivers, (FlutterDriver driver) {
        driver.tap(find.byValueKey(buttonKey));
      });

      await new Future<Null>.delayed(new Duration(milliseconds: 3000));
      await Future.forEach(drivers, (FlutterDriver driver) async {
        String result = await driver.getText(find.byValueKey(textKey));
        expect(result, equals('Button tapped 0 time.'));
      });
    });

    test('tap increase 2 times', () async {
      FlutterDriver alice = await driverMap['Alice'];
      FlutterDriver bob = await driverMap['Bob'];
      await new Future<Null>.delayed(new Duration(milliseconds: 3000));
      for(int i = 0; i < 2; i++) {
        await alice.tap(find.byValueKey(buttonKey));
        await new Future<Null>.delayed(new Duration(milliseconds: 2000));
        print('Driver 1: ${await alice.getText(find.byValueKey(textKey))}');
        print('Driver 2: ${await bob.getText(find.byValueKey(textKey))}');
      }
      String result1 = await alice.getText(find.byValueKey(textKey));
      expect(result1, equals('Button tapped 2 times.'));
      String result2 = await bob.getText(find.byValueKey(textKey));
      expect(result2, equals('Button tapped 2 times.'));
    });

    test('tap decrease 2 times', () async {
      FlutterDriver alice = await driverMap['Alice'];
      FlutterDriver bob = await driverMap['Bob'];
      await new Future<Null>.delayed(new Duration(milliseconds: 1000));
      for(int i = 0; i < 2; i++) {
        await bob.tap(find.byValueKey(buttonKey));
        await new Future<Null>.delayed(new Duration(milliseconds: 2000));
        print('Driver 2: ${await bob.getText(find.byValueKey(textKey))}');
        print('Driver 1: ${await alice.getText(find.byValueKey(textKey))}');
      }
      String result1 = await alice.getText(find.byValueKey(textKey));
      expect(result1, equals('Button tapped 0 time.'));
      String result2 = await bob.getText(find.byValueKey(textKey));
      expect(result2, equals('Button tapped 0 time.'));
      // fail('No reason failure.');
    });
  });

  group('Count Test 2', () {
    DriverMap driverMap;

    setUpAll(() async {
      await utils.resetCounter();
      driverMap = new DriverMap();
    });

    tearDownAll(() async {
      if (driverMap != null) {
        driverMap.closeAll();
      }
    });

    test('tap decrease 1 times', () async {
      FlutterDriver alice = await driverMap['Alice'];
      FlutterDriver bob = await driverMap['Bob'];
      await new Future<Null>.delayed(new Duration(milliseconds: 3000));
      for(int i = 0; i < 1; i++) {
        await bob.tap(find.byValueKey(buttonKey));
        await new Future<Null>.delayed(new Duration(milliseconds: 2000));
        print('Driver 2: ${await bob.getText(find.byValueKey(textKey))}');
        print('Driver 1: ${await alice.getText(find.byValueKey(textKey))}');
      }
      String result1 = await alice.getText(find.byValueKey(textKey));
      expect(result1, equals('Button tapped -1 time.'));
      String result2 = await bob.getText(find.byValueKey(textKey));
      expect(result2, equals('Button tapped -1 time.'));
    });

    test('tap increase 1 times', () async {
      FlutterDriver alice = await driverMap['Alice'];
      FlutterDriver bob = await driverMap['Bob'];
      await new Future<Null>.delayed(new Duration(milliseconds: 1000));
      for(int i = 0; i < 1; i++) {
        await alice.tap(find.byValueKey(buttonKey));
        await new Future<Null>.delayed(new Duration(milliseconds: 2000));
        print('Driver 1: ${await alice.getText(find.byValueKey(textKey))}');
        print('Driver 2: ${await bob.getText(find.byValueKey(textKey))}');
      }
      String result1 = await alice.getText(find.byValueKey(textKey));
      expect(result1, equals('Button tapped 0 time.'));
      String result2 = await bob.getText(find.byValueKey(textKey));
      expect(result2, equals('Button tapped 0 time.'));
    });
  });
}
