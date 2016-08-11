// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import '../mobile/device_spec.dart';
import '../mobile/device.dart';
import 'test_result.dart';
import '../globals.dart';
import '../util.dart';

class TAPReporter {
  int currentTestNum;
  int passingTestsNum;
  Map<int, TestMethodResult> testMethodResultMapping;
  Map<int, GroupResult> groupResultMapping;
  List<TestSuiteResult> suites;
  StringBuffer roundHighlight;

  TAPReporter(Map<DeviceSpec, Device> deviceMapping) {
    this.currentTestNum = 0;
    this.passingTestsNum = 0;
    this.testMethodResultMapping = <int, TestMethodResult>{};
    this.groupResultMapping = <int, GroupResult>{};
    this.suites = <TestSuiteResult>[];
    roundHighlight = new StringBuffer();
    int diffFrom = beginOfDiff(
      deviceMapping.keys.map((DeviceSpec spec) => spec.groupKey()).toList()
    );
    deviceMapping.forEach((DeviceSpec spec, Device device) {
      roundHighlight.writeln(
        '<Spec Group Key: ${spec.groupKey().substring(diffFrom)}>'
        ' -> '
        '<Device Group Key: ${device.groupKey()}> (${spec.nickName})'
      );
    });
  }

  void printHeader() {
    print(
      '\n'
      'TAP version 13'
    );
  }

  Future<bool> report(String testScriptPath, Stream jsonOutput) async {
    testMethodResultMapping.clear();
    groupResultMapping.clear();
    suites.add(new TestSuiteResult(testScriptPath));
    bool hasTestOutput = false;
    await for (var line in jsonOutput) {
      convertToTAPFormat(line.toString().trim());
      hasTestOutput = true;
    }
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

    TestSuiteResult lastSuite = suites.last;

    if (_isGroupEvent(event) && !_isGroupRootEvent(event)) {
      dynamic groupInfo = event['group'];
      String name = groupInfo['name'];
      bool skip = groupInfo['metadata']['skip'];
      String skipReason = groupInfo['metadata']['skipReason'] ?? '';
      if (skip) {
        print('# skip ${groupInfo['name']} $skipReason');
      } else {
        print('# ${groupInfo['name']}');
      }
      int groupID = groupInfo['id'];
      GroupResult groupEvent = new GroupResult(name, skip, skipReason);
      groupResultMapping[groupID] = groupEvent;
      lastSuite.addEvent(groupEvent);
    } else if (_isTestStartEvent(event)) {
      dynamic testInfo = event['test'];
      int testID = testInfo['id'];
      String name = testInfo['name'];
      List<int> groupIDs = testInfo['groupIDs'];
      int directParentGroupID;
      // Associate the test event to its parent group event if any
      if (groupIDs.isNotEmpty) {
        directParentGroupID = groupIDs.last;
        // Remove group name prefix if any
        GroupResult directParentGroup = groupResultMapping[directParentGroupID];
        String groupName = directParentGroup.name;
        if (name.startsWith(groupName)) {
          name = name.substring(groupName.length).trim();
        }
      }
      bool skip = testInfo['metadata']['skip'];
      String skipReason = testInfo['metadata']['skipReason'] ?? '';
      testMethodResultMapping[testID]
        = new TestMethodResult(name, directParentGroupID, skip, skipReason);
    } else if (_isErrorEvent(event)) {
      int testID = event['testID'];
      TestMethodResult testEvent = testMethodResultMapping[testID];
      String errorReason = event['error'];
      testEvent.fillError(errorReason);
    } else if (_isTestDoneEvent(event)) {
      int testID = event['testID'];
      TestMethodResult testEvent = testMethodResultMapping[testID];
      testEvent.hidden = event['hidden'];
      testEvent.result = event['result'];
      printTestResult(testEvent);
      if (testEvent.hidden) {
        return;
      }
      int directParentGroupID = testEvent.directParentGroupID;
      if (!groupResultMapping.containsKey(directParentGroupID)) {
        lastSuite.addEvent(testEvent);
      } else {
        GroupResult groupEvent = groupResultMapping[directParentGroupID];
        groupEvent.addTestEvent(testEvent);
      }
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

  void printTestResult(TestMethodResult event) {
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

  int skipNum() {
    return sum(suites.map((TestSuiteResult e) => e.skipNum()));
  }

  int failNum() {
    return sum(suites.map((TestSuiteResult e) => e.failNum()));
  }

  int passNum() {
    return sum(suites.map((TestSuiteResult e) => e.passNum()));
  }

  dynamic toJson() {
    int failures = failNum();
    return {
      'type': 'test-round',
      'highlight': roundHighlight.toString(),
      'skip-num': skipNum(),
      'fail-num': failures,
      'pass-num': passNum(),
      'status': failures > 0 ? 'fail' : 'pass',
      'suites-info': suites.map((TestSuiteResult suite) => suite.toJson()).toList()
    };
  }
}
