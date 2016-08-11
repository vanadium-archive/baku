// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import '../util.dart';


abstract class Result {
  String name;


  Result(this.name);

  Map toJson();

  int skipNum();
  int failNum();
  int passNum();

  @override
  String toString() {
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}

class TestMethodResult extends Result {
  // // Known at TestStartEvent
  int directParentGroupID;
  bool skip;
  String skipReason;
  // Known at ErrorEvent
  bool error;
  String errorReason;
  // Known at TestDoneEvents
  String result;
  bool hidden;

  TestMethodResult(String name, this.directParentGroupID, this.skip, this.skipReason)
    : super(name) {
    this.error = false;
  }

  void fillError(String errorReason) {
    this.error = true;
    this.errorReason = errorReason;
  }

  @override
  int skipNum() {
    return skip ? 1 : 0;
  }

  @override
  int failNum() {
    if (skip) {
      return 0;
    }
    return error ? 1 : 0;
  }

  @override
  int passNum() {
    if (skip) {
      return 0;
    }
    return error ? 0 : 1;
  }

  @override
  Map<String, String> toJson() {
    Map<String, String> map = <String, String>{};
    map['name'] = name;
    map['type'] = 'test-method';
    if (skip) {
      map['status'] = 'skip';
      map['reason'] = skipReason;
    } else {
      if (error) {
        map['status'] = 'fail';
        map['reason'] = errorReason;
      } else {
        map['status'] = 'pass';
      }
    }
    map['result'] = result;
    return map;
  }
}


class GroupResult extends Result {
  bool skip;
  String skipReason;
  List<TestMethodResult> testsInGroup;

  GroupResult(String name, this.skip, this.skipReason) : super(name) {
    this.testsInGroup = <TestMethodResult>[];
  }

  void addTestEvent(TestMethodResult testEvent) {
    testsInGroup.add(testEvent);
  }

  @override
  int skipNum() {
    return skip ? 0 : sum(testsInGroup.map((TestMethodResult e) => e.skipNum()));
  }

  @override
  int failNum() {
    return skip ? 0 : sum(testsInGroup.map((TestMethodResult e) => e.failNum()));
  }

  @override
  int passNum() {
    return skip ? 0 : sum(testsInGroup.map((TestMethodResult e) => e.passNum()));
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = 'test-group';
    if (skip) {
      map['status'] = 'skip';
      map['reason'] = skipReason;
      return map;
    }
    int failures = failNum();
    if (failures > 0) {
      map['status'] = 'fail';
    } else {
      map['status'] = 'pass';
    }
    map['skip-num'] = skipNum();
    map['fail-num'] = failures;
    map['pass-num'] = passNum();
    map['methods-info'] = testsInGroup.map(
      (TestMethodResult e) => e.toJson()
    ).toList();
    return map;
  }
}

class TestSuiteResult extends Result {
  List<Result> events;

  TestSuiteResult(String name) : super(name) {
    this.events = <Result>[];
  }

  int skipNum() {
    return sum(events.map((Result e) => e.skipNum()));
  }

  int failNum() {
    return sum(events.map((Result e) => e.failNum()));
  }

  int passNum() {
    return sum(events.map((Result e) => e.passNum()));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = 'test-suite';
    map['skip-num'] = skipNum();
    map['fail-num'] = failNum();
    map['pass-num'] = passNum();
    map['status'] = map['fail-num'] > 0 ? 'fail' : 'pass';
    map['children-info'] = events.map((Result e) => e.toJson()).toList();
    return map;
  }

  void addEvent(Result event) {
    events.add(event);
  }

  @override
  String toString() {
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}
