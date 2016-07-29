// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import '../globals.dart';

class TAPReporter {
  int currentTestNum;
  int passingTestsNum;
  Map<int, TestEvent> testEventMapping;

  TAPReporter() {
    this.currentTestNum = 0;
    this.passingTestsNum = 0;
    this.testEventMapping = <int, TestEvent>{};
  }

  void printHeader() {
    print(
      '\n'
      'TAP version 13'
    );
  }

  Future<bool> report(Stream jsonOutput) async {
    bool hasTestOutput = false;
    await for (var line in jsonOutput) {
      convertToTAPFormat(line.toString().trim());
      hasTestOutput = true;
    }
    testEventMapping.clear();
    return hasTestOutput;
  }

  void printSummary() {
    print(
      '\n'
      '1..$currentTestNum\n'
      '# tests $currentTestNum\n'
      '# pass $passingTestsNum\n'
    );
  }

  void convertToTAPFormat(var jsonLine) {
    if (jsonLine == null)
      return;
    dynamic event;
    try {
      event = JSON.decode(jsonLine);
    } on FormatException {
      printError('File ${jsonLine.toString()} is not in JSON format.');
      return;
    }

    if (_isGroupEvent(event) && !_isGroupRootEvent(event)) {
      dynamic groupInfo = event['group'];
      bool skip = groupInfo['metadata']['skip'];
      if (skip) {
        String skipReason = groupInfo['metadata']['skipReason'] ?? '';
        print('# skip ${groupInfo['name']} $skipReason');
      }
      print('# ${groupInfo['name']}');
    } else if (_isTestStartEvent(event)) {
      dynamic testInfo = event['test'];
      int testID = testInfo['id'];
      String name = testInfo['name'];
      bool skip = testInfo['metadata']['skip'];
      String skipReason = testInfo['metadata']['skipReason'] ?? '';
      testEventMapping[testID] = new TestEvent(name, skip, skipReason);
    } else if (_isErrorEvent(event)) {
      int testID = event['testID'];
      TestEvent testEvent = testEventMapping[testID];
      String errorReason = event['error'];
      testEvent.fillError(errorReason);
    } else if (_isTestDoneEvent(event)) {
      int testID = event['testID'];
      TestEvent testEvent = testEventMapping[testID];
      testEvent.hidden = event['hidden'];
      testEvent.result = event['result'];
      printTestResult(testEvent);
    }
  }

  bool _isGroupEvent(dynamic event) {
    return event['type'] == 'group';
  }

  bool _isGroupRootEvent(dynamic event) {
    dynamic groupInfo = event['group'];
    return _isGroupEvent(event)
           &&
           groupInfo['name'] == null
           &&
           groupInfo['parentID'] == null;
  }

  bool _isTestStartEvent(dynamic event) {
    return event['type'] == 'testStart';
  }

  bool _isErrorEvent(dynamic event) {
    return event['type'] == 'error';
  }

  bool _isTestDoneEvent(dynamic event) {
    return event['type'] == 'testDone';
  }

  void printTestResult(TestEvent event) {
    if (event.hidden)
      return;
    if (event.result != 'success') {
      if (event.error) {
        print('not ok ${++currentTestNum} - ${event.name}');
        String tab = '${' ' * 2}';
        // Print error message
        event.errorReason.split('\n').forEach((String line) {
          print('$tab$line');
        });
        return;
      }
      print('not ok ${++currentTestNum} - ${event.name}');
      return;
    }
    if (event.skip) {
      print('ok ${++currentTestNum} - # SKIP ${event.skipReason}');
    }
    print('ok ${++currentTestNum} - ${event.name}');
    passingTestsNum++;
  }
}

class TestEvent {
  // Known at TestStartEvent
  String name;
  bool skip;
  String skipReason;
  // Known at ErrorEvent
  bool error;
  String errorReason;
  // Known at TestDoneEvents
  String result;
  bool hidden;

  TestEvent(String name, bool skip, String skipReason) {
    this.name = name;
    this.skip = skip;
    this.skipReason = skipReason;
    this.error = false;
  }

  void fillError(String errorReason) {
    this.error = true;
    this.errorReason = errorReason;
  }
}
