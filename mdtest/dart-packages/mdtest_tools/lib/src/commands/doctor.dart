// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../runner/mdtest_command.dart';
import '../globals.dart';

class DoctorCommand extends MDTestCommand {

  @override
  final String name = 'doctor';

  @override
  final String description = 'Check if all dependent tools are installed.';

  @override
  Future<int> runCore() async {
    printInfo('Running "mdtest doctor command" ...');
    if (os.isWindows) {
      print('Windows platform is not supported.');
      return 1;
    }
    int result = 0;
    result += printDiagnoseMessage(
      'dart',
      'Please install dart following the link https://www.dartlang.org/install '
      'and add dart/bin to your environment variable PATH.'
    );
    result += printDiagnoseMessage(
      'pub',
      'Please install dart following the link https://www.dartlang.org/install '
      'and add dart/bin to your environment variable PATH.'
    );
    result += printDiagnoseMessage(
      'flutter',
      'Please install flutter following the link https://flutter.io/setup/ '
      'and add flutter/bin to your environment variable PATH.  Ideally '
      '`flutter doctor` should not report any problem.'
    );
    result += printDiagnoseMessage(
      'adb',
      'Please install Android SDK following the link '
      'https://developer.android.com/studio/intro/update.html '
      'and add Android/Sdk/platform-tools to your environment variable PATH.'
    );

    if (os.isMacOS) {
      result += printDiagnoseMessage(
        'brew',
        'Please install homebrew following the link http://brew.sh/.'
      );
      result += printDiagnoseMessage(
        'lcov',
        'Please install lcov using `brew install lcov`.'
      );
      result += printDiagnoseMessage(
        'mobiledevice',
        'Please install mobiledevice following the link '
        'https://github.com/imkira/mobiledevice.'
      );
    }

    if (os.isLinux) {
      result += printDiagnoseMessage(
        'lcov',
        'Please install lcov using `sudo apt-get lcov`.'
      );
    }

    if (result > 0) {
      bool singleSyntax = result == 1;
      printError(
        'Some tool${singleSyntax ? '' : 's'} that mdtest '
        'depend${singleSyntax ? 's' : ''} on ${singleSyntax ? 'is' : 'are'} '
        'not installed.  Please follow the instructions above and resolve '
        'all problems before using mdtest.'
      );
      return 1;
    }
    printInfo(
      'All required tools are installed correctly.  mdtest is ready to go.'
    );
    return 0;
  }
}

/// Print diagnose message for the given executable and instructions on how
/// to install the tool if it is not detected or installed.  Returns 0 if
/// the tool is installed and properly configured, 1 otherwise.
int printDiagnoseMessage(String exec, String instructions) {
  File execFile = os.which(exec);
  if (execFile == null) {
    print('[x] $exec is not found.  $instructions');
    return 1;
  }
  print('[✓] $exec found in ${execFile.path}.');
  return 0;
}
