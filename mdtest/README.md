# mdtest: Multi-Device Applicatoin Testing Framework

`mdtest` is a command line tool built on top of [flutter](https://flutter.io/)
for integration testing.  The tool wraps several flutter commands and implements
algorithms to deliver a robust end to end testing experience for multi-device
applications.  `mdtest` is targeted at flutter apps and provides a public
wrapper of flutter driver API and allows testers to write portable test scripts
across platforms.

# Requirements:

* Supported Operating Systems
  - Linux (64 bit)
  - Mac OS X (64 bit)

* Tools
  - [Dart](https://www.dartlang.org/): must be installed and accessible from
   `PATH`
  - PUB: comes with Dart
  - [Flutter](https://flutter.io/): must be installed and accessible from `PATH`.
   `flutter doctor` should report no error
  - [ADB](http://developer.android.com/tools/help/adb.html): must be installed
   and accessible from `PATH`

# Installing mdtest

## Clone from Github

To get `mdtest`, use `git` to clone the [baku](https://github.com/vanadium/baku)
repository and then add the `mdtest` tool to `PATH`

```
$ git clone git@github.com:vanadium/baku.git
$ export PATH="$(pwd)/mdtest/bin:$PATH"
```
Open mdtest/pubspec.yaml file and make the following change:

replace
 ```
 dlog:
   path: ../../../../third_party/dart/dlog
 ```
with
 ```
 dlog:
 ```
replace
 ```
 flutter_driver:
   path: ../deps/flutter/packages/flutter_driver
 ```
with
 ```
 flutter_driver:
   path: ${path/to/flutter}/packages/flutter_driver
 ```

The first time you run the `mdtest` command, it will build the tool ifself.  If
you see Build Success, then `mdtest` is ready to go.

# Quick Start

This section introduces main features of `mdtest`.

## Test Spec

The test spec file is required to run `mdtest`.  In a nut shell, the test spec
is the way to tell `mdtest` what kind of devices you want your applications to
run on.  The spec file gives you the flexibility to choose your app device
either uniquely by specifying the device id, or roughly by specifying some
properties of the devices.  The device nickname refers to a device that
satisfies your specification.  You can use the nickname to create a flutter
driver in your test script.  The ability to roughly specify device requirements
and refer a device by its nickname makes your test script portable to any
platform anywhere in the world, as long as sufficient available devices are
detected by `mdtest`.  The test scripts specified in the test spec should
contain flutter driver tests for integration testing.

`mdtest` uses a test spec to initialize the test runs.  The test spec is in JSON
format and should follow the style below:
```json
{
  "test-paths": [
    "${path/to/test_script1.dart}",
    "${path/to/test_script2.dart}",
    "${path/to/*_test.dart}"
    ...
  ],
  "devices": {
    "${device_nickname1}": {
      "device-id": "${device_id}",
      "model-name": "${device_model_name}",
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

### `test-paths` (optional)

All paths in the test spec should either be absolute paths or paths relative to
the test spec file.  You can also specify test paths using glob patterns.  The
"test-paths" attribute is optional if you specify the test script path(s) from
the command line when invoking `mdtest`.  But you should at least specify a test
path from either the test spec or the command line, otherwise `mdtest` will
complain.

### `devices` (required)

"devices" attribute is required in the test spec.  You can list a number of
device specs inside "devices" attribute.  Each device spec has a unique
"$device_nickname" mapping to several device/application properties.

 * `device-id` (optional): The "device-id" property is optional and should be
   the device id obtained by `flutter devices` if set.

 * `model-name` (optional): The"model-name" property is optional and should be
   the device model name (e.g. Nexus 5) if set.

 * `screen-size` (optional): The "screen-size" property is optional and values
   can only be one of
   ["small"(<3.5), "normal"(>=3.5 && <5), "large"(>=5 && <8), "xlarge"(>=8)]
   where the size is measured by screen diagonal in inches.  The screen size
   generally follows
   [Android Screen Support](https://developer.android.com/guide/practices/screens_support.html)
   with overlapping screen ranges resolved.

 * `app-root` (required): The "app-root" attribute specifies the path to the
   flutter app which you want to run on the device.

 * `app-path` (required): The "app-path" attribute points to the instrumented
   flutter app that uses flutter driver plugin.  For more information, please
   refer to
   [flutter integration testing](https://flutter.io/testing/#integration-testing).

You can add arbitraty number of device specs by repeatedly adding attributes
following the rules above.

## Commands

Currently, `mdtest` supports two commands: `run` and `auto`.  You can run
`mdtest run args...` or `mdtest auto args...` to invoke the commands.  Run
`mdtest -h` to list the supported commands and `mdtest command -h` for more
information for that command.  `mdtest` has a global verbose flag `--verbose`,
which will report more information to the user during execution if set to true.

### Run

`mdtest run` command is used to run test suite(s) on devices that `mdtest` finds
according to the test spec.  The tool computes an app-device mapping based on
the device requirements in the test spec.  The app-device mapping is bijective
and is used to launch each application on the mapped device `mdtest` finds.  In
this mode, `mdtest` will use the first app-device mapping it finds, and install
and start the applications on devices to execute test scripts.

* Arguments
  - `--spec` points to the path of the spec file
  - `--coverage` collects code coverage and stores the coverage info for each
   application under ${application_folder/coverage/code_coverage} if set
  - `--format` report test output in TAP format if set to tap, default is none
   which uses the default dart-lang test output format
  - The rest of the arguments would be either paths or glob patterns for the
    test scripts

### Auto

`mdtest auto` command is used to run test suite(s) in a small number of times to
cover as many device settings for each unique application as possible.  More
specifically, `mdtest` groups user specified applications based on the
uniqueness of the application root path, and groups available devices based on
model name (will support more grouping rules later).  Then, `mdtest` computes
the maximum number of possible app group to device group mappings.  Finally,
`mdtest` will try to compute the smallest number of test runs to cover those
maximum possible mappings.  The heuristic here is to make sure at least one app
in each application group runs on at least one device in each device group
possibly according to the test spec in some test run.  However, since the
problem is a set cover problem and is NP-complete, `mdtest` uses a approximation
algorithm that has a complexity of O(log(n)).

* Arguments
  - `--spec` points to the path of the spec file
  - `--coverage` collects code coverage and stores the coverage info for each
   application under ${application_folder/coverage/code_coverage} if set
  - `--format` report test output in TAP format if set to tap, default is none
   which uses the default dart-lang test output format
  - The rest of the arguments would be either paths or glob patterns for the
    test scripts

## Writing Tests

`mdtest` provides a wrapper of flutter driver API and allows users to create a
driver instance by a device nickname specified in the test spec.  To use this
wrapper, you should add the following import statement in your test scripts:

```
import 'package:flutter_driver/flutter_driver.dart';
import 'package:mdtest/driver_util.dart';
```

Then you can create a flutter driver instance like this:
```
FlutterDriver driver = await DriverUtil.connectByName('${device_nickname}');
```

The way to write integration tests for flutter apps follows
[flutter integration testing](https://flutter.io/testing/#integration-testing).
