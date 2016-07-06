// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert' show JSON;

import 'package:flutter_driver/flutter_driver.dart';

import 'src/base/common.dart';
import 'src/globals.dart';

class DriverUtil {
  static Future<FlutterDriver> connectByName(String deviceNickname) async {
    // read the temp spec file to find the device nickname -> observatory port
    // mapping
    Directory systemTempDir = Directory.systemTemp;
    File tempFile = new File('${systemTempDir.path}/$defaultTempSpecsName');
    // if temp spec file is not found, report error and exit
    if(!await tempFile.exists()) {
      printError('Multi-Drive temporary specs file not found.');
      exit(1);
    }
    // decode specs
    dynamic configs = JSON.decode(await tempFile.readAsString());
    // report error if nickname is not found
    if(!configs.containsKey(deviceNickname)) {
      printError('Device nickname $deviceNickname not found.');
      exit(1);
    }
    // read device id and observatory port
    String deviceID = configs[deviceNickname]['device-id'];
    String observatoryUrl = configs[deviceNickname]['observatory-url'];
    printInfo('$deviceNickname refers to device $deviceID running on url $observatoryUrl');
    // delegate to flutter driver connect method
    return await FlutterDriver.connect(dartVmServiceUrl: '$observatoryUrl');
  }
}
