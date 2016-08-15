# mdtest: Multi-Device Applicatoin Testing Framework

`mdtest` is a command line tool built on top of [Flutter](https://flutter.io/)
for integration testing.  The tool wraps several Flutter commands and implements
algorithms to deliver a robust end to end testing experience for multi-device
applications.  `mdtest` targets at multi-device Flutter apps and provides a
public API that wraps Flutter driver API and allows testers to write portable
test scripts across platforms.

# Requirements:

* Supported Operating Systems
  - Linux (64 bit)
  - Mac OS X (64 bit)

* Tools
  - [Dart](https://www.dartlang.org/): must be installed and accessible from
   `PATH`.
  - PUB: comes with Dart and must be accessible from `PATH`.
  - [Flutter](https://flutter.io/): must be installed and accessible from
   `PATH`.  `flutter doctor` should report no error.  Please refer to the
   [next section](#installing-mdtest) for installation.
  - [ADB](http://developer.android.com/tools/help/adb.html): must be installed
   and accessible from `PATH`.
  - LCOV: `sudo apt-get install lcov` on Linux, `brew install lcov` on Mac OS.
    Must be installed and accessible from `PATH`.
  - [Homebrew](http://brew.sh/): must be installed on Mac OS and accessible from
    `PATH`.
  - [mobiledevice](https://github.com/imkira/mobiledevice): must be installed on
    Mac OS and accessible from `PATH`.

# Installing mdtest

## Clone baku repo

To get `mdtest`, use `git` to clone the [baku](https://github.com/vanadium/baku)
repository and then add the `mdtest` tool to `PATH`

```
$ git clone git@github.com:vanadium/baku.git
$ cd baku
baku$ export PATH="$(pwd)/mdtest/bin:$PATH"
```

## Install Flutter

Run `make` under the baku directory and it will `git clone` Flutter repo under
deps folder.  Add `flutter` to `PATH` by

```
baku$ make
baku$ export PATH="$(pwd)/deps/flutter/bin:$PATH"
```

`mdtest` will depends on the Flutter tool under deps folder by default.  To use
Flutter under another location, you need to add it into `PATH` and change the
pubspec.yaml under mdtest/dart-packages/mdtest_api folder.

Replace

```
flutter_driver:
  path: ../../../deps/flutter/packages/flutter_driver
```

with

```
flutter_driver:
  path: ${path/to/flutter}/packages/flutter_driver
```

The first time you run the `mdtest` command, it will build the tool itself.  If
you see Build Success, then `mdtest` is ready to go.  You can run `mdtest
doctor` to check if all dependent tools are installed before you run any test
script.

# Quick Start

This section introduces main features of `mdtest`.

## Test Spec

The test spec file is required to run `mdtest`.  In a nut shell, the test spec
is the way to tell `mdtest` what kind of devices you want your applications to
run on.  The spec file gives you the flexibility to choose your app device
either uniquely by specifying the device id, or roughly by specifying some
properties of the devices.  The device nickname refers to a Flutter driver
instance that will be used to automate the application and device that satisfiy
the test spec.  You can use the nickname to create a Flutter driver instance in
your test script.  The ability to roughly specify device requirements and refer
a driver instance by its nickname makes your test script portable to any
platform anywhere in the world, as long as sufficient available devices are
detected by `mdtest`.  The test scripts specified in the test spec should
contain Flutter driver tests for integration testing.

`mdtest` uses a test spec to find devices that each application can run on based
on the given device properties and initiate the test runs.  The test spec is in
JSON format and should follow the style below:

```json
{
  "devices": {
    "${device_nickname1}": {
      "platform": "${platform}",
      "device-id": "${device_id}",
      "model-name": "${device_model_name}",
      "os-version": "${os_version}",
      "screen-size": "${screen_size}",
      "app-root": "${path/to/flutter/app}",
      "app-path": "${path/to/instrumented/app.dart}"
    },
    "${device_nickname2}": {
      ...
    }
  }
}
```

### `devices` (required)

"devices" attribute is required in the test spec.  You can list a number of
device specs inside "devices" attribute.  Each device spec has a unique
"$device_nickname" mapping to several device/application properties.

 * `platform` (optional): The "platform" property is optional and should be
   either 'android' or 'ios'.

 * `device-id` (optional): The "device-id" property is optional and should be
   the device id obtained by `flutter devices` if set.

 * `model-name` (optional): The "model-name" property is optional and should be
   the device model name (e.g. Nexus 5, iPhone 6S Plus, etc.) if set.

 * `os-version` (optional): The "os-version" property is optional and should
   follow rules in [semantic versioning](http://semver.org/).  This property is
   platform specific and thus "platform" must be set to use this property.

 * `screen-size` (optional): The "screen-size" property is optional and values
   can only be one of
   ["small"(<3.6), "normal"(>=3.6 && <5), "large"(>=5 && <8), "xlarge"(>=8)]
   where the size is measured by screen diagonal in inches.  The screen size
   generally follows
   [Android Screen Support](https://developer.android.com/guide/practices/screens_support.html)
   and [iOS Device List](https://en.wikipedia.org/wiki/List_of_iOS_devices) with
   overlapping screen ranges resolved.

 * `app-root` (required): The "app-root" attribute specifies the path to the
   Flutter app which you want to run on the device.  The path should point to
   the app root directory.  If a relative path is used, it must be relative to
   the directory that contains the test spec file.

 * `app-path` (required): The "app-path" attribute points to the instrumented
   Flutter app that uses Flutter driver plugin.  The path should point to a dart
   file that contains an instrumented main function which invokes the actual app
   main function.  If a relative path is used, it must be relative to the path
   in the `app-root`. For more information, please refer to
   [Flutter integration testing](https://flutter.io/testing/#integration-testing).

You can add arbitraty number of device specs by repeatedly adding attributes
following the rules above.  `mdtest create` can be used to create a test spec
template.

## Commands

Currently, `mdtest` supports 5 commands: `doctor`, `create`, `run`, `auto` and
`generate`.  Run `mdtest -h` to list the supported commands and `mdtest command
-h` for more information for that command.  `mdtest` has a global verbose flag
`--verbose`, which reports trace information to the user during execution if set
to true.

### Doctor

`mdtest doctor` command checks if all required dependent tools are installed.
You can follow the installation instruction if any tool is not installed.  If
you see 'mdtest is ready to go.' after running this command, then you can start
to run test scripts.  This command does not provide any options except the
default help flag.

### Create

`mdtest create` command helps create test spec template or test script template.

* Arguments
  - `--spec-template` points to the target path that will be used to generate a
    test spec template.
  - `--test-template` points to the target path that will be used to generate a
    test script template.

### Run

`mdtest run` command is used to run test suites on devices that `mdtest` finds
according to the test spec.  The tool computes an app-device mapping based on
the device requirements in the test spec.  The app-device mapping is bijective
and is used to launch each application on the mapped device `mdtest` finds.  In
this mode, `mdtest` will use the first app-device mapping it finds, then install
and start the applications on devices to execute test scripts.  After test
execution finishes, mdtest will uninstall testing applications on all used
devices.

* Arguments
  - `--brief` disable logging and only print out test execution results if set.
  - `--spec` points to the path of the test spec file.  Must be specified.
  - `--coverage` collects code coverage and stores the coverage info in LCOV
   format for each application under ${application_root_folder/coverage/*.lcov}
   if set.
  - `--format` reports test output in TAP format if set to tap, default is none
   which uses the default dart-lang test output format.
  - `--save-report-data` points to the path to save test execution results.  The
    results will be saved in JSON format and can be used to generate test
    report.
  - The rest of the arguments would be either paths or glob patterns for the
    test scripts.

### Auto

`mdtest auto` command is used to run test suites in a small number of times to
cover all possible device settings for each unique application.  More
specifically, `mdtest` groups user specified applications based on the
uniqueness of the application app-path, and groups available devices based on
any of device-id (default), platform, model-name, os-version and screen-size.
Then, `mdtest` computes all possible app group to device group mappings based on
the test spec and available devices.  Finally, `mdtest` will try to compute a
small number of test runs to cover all possible app-device mappings.  The
heuristic here is to make sure at least one app in each application group runs
on at least one device in each device group with minimum test runs.  However,
since the problem is a set cover problem, it is NP-complete, `mdtest` uses a
[greedy approximation algorithm](https://en.wikipedia.org/wiki/Set_cover_problem#Greedy_algorithm)
that tries to compute a small number of test runs that achieve all app-device
paths.  The algorithm has a complexity of O(log(n)).

* Arguments
  - `--brief` disable logging and only print out test execution results if set.
  - `--spec` points to the path of the test spec file.  Must be specified.
  - `--coverage` collects code coverage and stores the coverage info in LCOV
   format for each application under ${application_root_folder/coverage/*.lcov}
   if set.
  - `--format` reports test output in TAP format if set to tap, default is none
   which uses the default dart-lang test output format.
  - `--save-report-data` points to the path to save test execution results.  The
    results will be saved in JSON format and can be used to generate test
    report.
  - `--groupby` is the device property that will be used to group all available
    devices.  The value can only be one of
    ['device-id'(default), 'platform', 'model-name', 'os-version', 'screen-size'].
  - The rest of the arguments would be either paths or glob patterns for the
    test scripts.

### Generate

`mdtest generate` command is used to load report data and generate either code
coverage or test execution output report.  The code coverage report only
contains statement coverage info and it uses genhtml internally, which comes
with lcov, to generate the web report.  The test execution output report
contains the app-device hitmap info as well as the status of test entities like
test round, test suite, test group and test method.  The HTML format report will
be stored under the given output directory users specify.

* Arguments
  - `--report-type` can be one of 'test' or 'coverage'.  If set to 'coverage',
    `mdtest` tries to generate a code coverage report.  If set to 'test',
    `mdtest` tries to generate a test execution output report.  Must be set.
  - `--load-report-data` points to the path to the report data that is used to
    generate HTML report.  If you want to generate a coverage report, you must
    provide a coverage data file in LCOV format.  If you want to generate a test
    report, you must provide a test data file in JSON format.  Must be set.
  - `--lib` points to the path to the Flutter application lib folder that your
    code coverage data refers to.  This option is only used if you want to
    generate a code coverage report.
  - `--output` points to the path of the directory where the HTML report will be
    stored.  Must be set.

## Writing Tests

`mdtest` provides a DriverMap class which maps every nickname to a Flutter
driver instance.  You can retrieve the corresponding Flutter driver instance by
providing the nickname, which is specified in the test spec.  DriverMap class
will lazy initialize the Flutter driver the first time you retrieve it.  Once
you get the Flutter driver instance, you can invoke any public methods that
the FlutterDriver class provides.  To use this wrapper, you should add the following
import statement in your test scripts:

```
import 'package:flutter_driver/flutter_driver.dart';
import 'package:mdtest/driver_util.dart';
```

Here is a full example test suite using DriverMap class:
```dart
import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:mdtest/driver_util.dart';

void main() {
  group('Multi-device application tests', () {
    DriverMap driverMap;

    setUpAll(() {
      driverMap = new DriverMap();
    });

    tearDownAll(() {
      if (driverMap != null) {
        driverMap.closeAll();
      }
    });

    test('Test 1', () async {
      // Lazy initialize driver
      FlutterDriver driver = await driverMap['nickname'];
      // Write normal flutter driver tests
      ...
    });

    test('Test 2', () async {
      // Get all flutter driver instances
      List<FlutterDriver> drivers = await Future.wait(driverMap.values);
      // Invoke tap() on all flutter drivers
      await Future.wait(
        drivers.map((driver) => driver.tap(...))
      );
      // Invoke getText() on all flutter drivers and check values
      await Future.forEach(drivers, (driver) async {
        String result = await driver.getText(...);
        expect(result, equals(...));
      });
    });
  });
}
```

`mdtest create` can be used to create a sample test script for you.  The way to
write integration tests for Flutter apps follows
[Flutter integration testing](https://flutter.io/testing/#integration-testing).

# Examples

`mdtest` comes with a [shared counter example](examples/shared-counter) and a
[chat example](examples/chat).  You can navigate to those examples and start
running `mdtest`.
