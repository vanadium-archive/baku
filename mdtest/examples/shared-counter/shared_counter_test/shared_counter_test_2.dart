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
  group('Count Test 3', () {
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

    test('tap increase 3 times', () async {
      FlutterDriver alice = await driverMap['Alice'];
      FlutterDriver bob = await driverMap['Bob'];
      await new Future<Null>.delayed(new Duration(milliseconds: 3000));
      for(int i = 0; i < 3; i++) {
        await alice.tap(find.byValueKey(buttonKey));
        await new Future<Null>.delayed(new Duration(milliseconds: 2000));
        print('Driver 1: ${await alice.getText(find.byValueKey(textKey))}');
        print('Driver 2: ${await bob.getText(find.byValueKey(textKey))}');
      }
      String result1 = await alice.getText(find.byValueKey(textKey));
      expect(result1, equals('Button tapped 3 times.'));
      String result2 = await bob.getText(find.byValueKey(textKey));
      expect(result2, equals('Button tapped 3 times.'));
    });

    test('tap decrese 3 times', () async {
      FlutterDriver alice = await driverMap['Alice'];
      FlutterDriver bob = await driverMap['Bob'];
      await new Future<Null>.delayed(new Duration(milliseconds: 1000));
      for(int i = 0; i < 3; i++) {
        await bob.tap(find.byValueKey(buttonKey));
        await new Future<Null>.delayed(new Duration(milliseconds: 2000));
        print('Driver 2: ${await bob.getText(find.byValueKey(textKey))}');
        print('Driver 1: ${await alice.getText(find.byValueKey(textKey))}');
      }
      String result1 = await alice.getText(find.byValueKey(textKey));
      expect(result1, equals('Button tapped 0 time.'));
      String result2 = await bob.getText(find.byValueKey(textKey));
      expect(result2, equals('Button tapped 0 time.'));
    });
  });
}
