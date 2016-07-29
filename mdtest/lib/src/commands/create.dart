// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../runner/mdtest_command.dart';
import '../globals.dart';
import '../util.dart';

const String specTemplate =
'''
{
  "devices": {
    "{nickname}": {
      "device-id": "{optional}",
      "model-name": "{optional}",
      "os-version": "{optional}",
      "api-level": "{optional}",
      "screen-size": "{optional}",
      "app-root": "{required}",
      "app-path": "{required}"
    },
    "{nickname}": {
      "app-root": "{required}",
      "app-path": "{required}"
    }
  }
}
''';

const String specGuide =
'Everything in the curly braces can be replaced with your own value.\n'
'"device-id", "model-name", "os-version", "api-level" and "screem-size" '
'are optional.\n'
'"app-root" and "app-path" are required.\n'
'An example spec would be\n'
'''
{
  "devices": {
    "Alice": {
      "device-id": "HT4CWJT03204",
      "model-name": "Nexus 9",
      "os-version": "6.0",
      "api-level": "23",
      "screen-size": "xlarge",
      "app-root": "/path/to/flutter-app",
      "app-path": "/path/to/main.dart"
    },
    "Bob": {
      ...
    }
    ...
  }
}
'''
'"nickname" will be used as the identifier of the device that matches '
'the corresponding properties in the test spec.  You will use nicknames '
'to establish connections between flutter drivers and devices in your '
'test scripts.\n'
'"device-id" is the unique id of your device.\n'
'"model-name" is the device model name.\n'
'"os-version" is the operating system version of your device.\n'
'"api-level" is Android specific and refers to the API level of your device.\n'
'"screen-size" is the screen diagonal size measured in inches.  The candidate '
'values are "small"(<3.5"), "normal"(>=3.5" && <5"), "large"(>=5" && <8") '
'and "xlarge"(>=8").\n'
'"app-root" is the path of your flutter application directory.\n'
'"app-path" is the path of the instrumented version of your app main function.\n'
;

const String testTemplate =
'''
import 'dart:async';

// add flutter_driver, test, mdtest to your pubspec/yaml
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:mdtest/driver_util.dart';

void main() {
  group('Group 1', () {
    // Create a flutter driver map that maps each nickname with a flutter driver
    DriverMap driverMap;

    setUpAll(() async {
      driverMap = new DriverMap();
      // Other setup functions
      // ...
    });

    tearDownAll(() async {
      if (driverMap != null) {
        driverMap.closeAll();
      }
      // Other tear down functions
      // ...
    });

    test('test 1', () async {
      // Send tap request to each connected driver
      List<FlutterDriver> drivers = await Future.wait(driverMap.values);
      await Future.forEach(drivers, (FlutterDriver driver) async {
        await driver.tap(find.byValueKey(...));
      });

      // Get text from each connected driver and compare the result
      await Future.forEach(drivers, (FlutterDriver driver) async {
        String result = await driver.getText(find.byValueKey(textKey));
        expect(result, equals('...'));
      });

      // An alternative to send tap request to each connected driver
      await Future.wait(
        drivers.map(
          (FlutterDriver driver) => driver.tap(find.byValueKey(buttonKey))
        )
      );
    });

    test('test 2', () async {
      FlutterDriver driver1 = await driverMap['nickname1'];
      FlutterDriver driver2 = await driverMap['nickname2'];
      await driver1.tap(find.byValueKey(...));
      await driver2.tap(find.byValueKey(...));
      String result1 = await driver1.getText(find.byValueKey(...));
      expect(result1, equals('...'));
      String result2 = await driver2.getText(find.byValueKey(...));
      expect(result2, equals('...'));
    });

    // More tests go here
    // ...
  });

  // More groups go here
  // ...
}
''';

const String testGuide =
'mdtest provide a DriverMap class which maps each nickname in the test spec '
'to a flutter driver.  Users can get a flutter driver instance by saying `'
'FlutterDriver driver = await driverMap[nickname];`  '
'DriverMap will lazy initialize a flutter driver instance the first time '
'you invoke the [] operator.\n'
'Once you get access to a flutter driver, you can use it to automate your '
'flutter app.  For more detailed usage, please refer to the generated test '
'template.'
;

class CreateCommand extends MDTestCommand {

  @override
  final String name = 'create';

  @override
  final String description = 'create a test spec/script template for the user to fill in';

  @override
  Future<int> runCore() async {
    printInfo('Running "mdtest create command" ...');
    String specTemplatePath = argResults['spec-template'];
    String testTemplatePath = argResults['test-template'];
    if (specTemplatePath == null && testTemplatePath == null) {
      printError('You must provide a path for either spec or test template.');
      return 1;
    }

    if (specTemplatePath != null) {
      File file = createNewFile('$specTemplatePath');
      file.writeAsStringSync(specTemplate);
      String absolutePath = normalizePath(Directory.current.path, specTemplatePath);
      printInfo('Template test spec written to $absolutePath');
      printGuide(specGuide);
    }

    if (testTemplatePath != null) {
      File file = createNewFile('$testTemplatePath');
      file.writeAsStringSync(testTemplate);
      String absolutePath = normalizePath(Directory.current.path, testTemplatePath);
      printInfo('Template test written to $absolutePath');
      printGuide(testGuide);
    }
    return 0;
  }

  void printGuide(String guide) {
    guide.split('\n').forEach((String line) => printInfo(line));
  }

  CreateCommand() {
    usesSpecTemplateOption();
    usesTestTemplateOption();
  }
}
