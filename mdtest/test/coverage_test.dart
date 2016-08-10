// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:mdtest/src/mobile/device_spec.dart';
import 'package:mdtest/src/mobile/device.dart';
import 'package:mdtest/src/mobile/key_provider.dart';
import 'package:mdtest/src/algorithms/coverage.dart';
import 'package:mdtest/src/algorithms/matching.dart';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import 'src/mocks.dart';

void main() {
  group('coverage matrix', () {
    test('0 reachable paths', () {
      MockCoverageMatrix baseMatrix = new MockCoverageMatrix();
      when(baseMatrix.matrix).thenReturn(
        [
          [cannotBeCovered, cannotBeCovered, cannotBeCovered],
          [cannotBeCovered, cannotBeCovered, cannotBeCovered],
          [cannotBeCovered, cannotBeCovered, cannotBeCovered]
        ]
      );
      MockCoverageMatrix newMatrix = new MockCoverageMatrix();
      when(newMatrix.matrix).thenReturn(
        [
          [cannotBeCovered, cannotBeCovered, cannotBeCovered],
          [cannotBeCovered, cannotBeCovered, cannotBeCovered],
          [cannotBeCovered, cannotBeCovered, cannotBeCovered]
        ]
      );
      int reward = computeReward(baseMatrix, newMatrix);
      expect(reward, equals(0));
    });

    test('3 reachable paths', () {
      MockCoverageMatrix baseMatrix = new MockCoverageMatrix();
      when(baseMatrix.matrix).thenReturn(
        [
          [cannotBeCovered, cannotBeCovered, cannotBeCovered],
          [cannotBeCovered, cannotBeCovered, cannotBeCovered],
          [cannotBeCovered, cannotBeCovered, cannotBeCovered]
        ]
      );
      MockCoverageMatrix newMatrix = new MockCoverageMatrix();
      when(newMatrix.matrix).thenReturn(
        [
          [cannotBeCovered, cannotBeCovered, isNotCovered],
          [cannotBeCovered, isNotCovered, cannotBeCovered],
          [cannotBeCovered, isNotCovered, cannotBeCovered]
        ]
      );
      int reward = computeReward(baseMatrix, newMatrix);
      expect(reward, equals(3));
    });

    test('all reachable paths', () {
      MockCoverageMatrix baseMatrix = new MockCoverageMatrix();
      when(baseMatrix.matrix).thenReturn(
        [
          [cannotBeCovered, cannotBeCovered, cannotBeCovered],
          [cannotBeCovered, cannotBeCovered, cannotBeCovered],
          [cannotBeCovered, cannotBeCovered, cannotBeCovered]
        ]
      );
      MockCoverageMatrix newMatrix = new MockCoverageMatrix();
      when(newMatrix.matrix).thenReturn(
        [
          [isNotCovered, isNotCovered, isNotCovered],
          [isNotCovered, isNotCovered, isNotCovered],
          [isNotCovered, isNotCovered, isNotCovered]
        ]
      );
      int reward = computeReward(baseMatrix, newMatrix);
      expect(reward, equals(9));
    });
  });

  group('coverage algorithm', () {
    test('with device id as device key', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: {
            'app-root': 'xxx',
            'app-path': 'yyy'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: {
            'app-root': 'xxx',
            'app-path': 'zzz'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'device-id'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S',
            'os-version': '9.3.2',
            'screen-size': 'large'
          },
          groupKey: 'device-id'
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      List<Map<DeviceSpec, Device>> allDeviceMappings
        = findAllMatchingDeviceMappings(specs, individualMatches);
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      Map<String, List<DeviceSpec>> specGroups = buildGroups(specs);
      GroupInfo groupInfo = new GroupInfo(deviceGroups, specGroups);
      Map<CoverageMatrix, Map<DeviceSpec, Device>> cov2match
        = buildCoverage2MatchMapping(allDeviceMappings, groupInfo);
      CoverageMatrix appDeviceCoverageMatrix = new CoverageMatrix(groupInfo);
      findMinimumMappings(cov2match, appDeviceCoverageMatrix);
      List<List<int>> matrix = appDeviceCoverageMatrix.matrix;
      for (List<int> row in matrix) {
        for (int e in row) {
          expect(e, equals(0));
        }
      }
    });

    test('with platform as device key', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: {
            'platform': 'android',
            'app-root': 'xxx',
            'app-path': 'yyy'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: {
            'app-root': 'xxx',
            'app-path': 'zzz'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'platform'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S',
            'os-version': '9.3.2',
            'screen-size': 'large'
          },
          groupKey: 'platform'
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      List<Map<DeviceSpec, Device>> allDeviceMappings
        = findAllMatchingDeviceMappings(specs, individualMatches);
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      Map<String, List<DeviceSpec>> specGroups = buildGroups(specs);
      GroupInfo groupInfo = new GroupInfo(deviceGroups, specGroups);
      Map<CoverageMatrix, Map<DeviceSpec, Device>> cov2match
        = buildCoverage2MatchMapping(allDeviceMappings, groupInfo);
      CoverageMatrix appDeviceCoverageMatrix = new CoverageMatrix(groupInfo);
      findMinimumMappings(cov2match, appDeviceCoverageMatrix);
      List<List<int>> matrix = appDeviceCoverageMatrix.matrix;
      expect(matrix[0][0], equals(0));
      expect(matrix[0][1], equals(-1));
      expect(matrix[1][0], equals(-1));
      expect(matrix[1][1], equals(0));
    });

    test('with model name as device key', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: {
            'app-root': 'xxx',
            'app-path': 'yyy'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: {
            'model-name': 'Nexus 9',
            'app-root': 'xxx',
            'app-path': 'zzz'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'model-name'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S',
            'os-version': '9.3.2',
            'screen-size': 'large'
          },
          groupKey: 'model-name'
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      List<Map<DeviceSpec, Device>> allDeviceMappings
        = findAllMatchingDeviceMappings(specs, individualMatches);
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      Map<String, List<DeviceSpec>> specGroups = buildGroups(specs);
      GroupInfo groupInfo = new GroupInfo(deviceGroups, specGroups);
      Map<CoverageMatrix, Map<DeviceSpec, Device>> cov2match
        = buildCoverage2MatchMapping(allDeviceMappings, groupInfo);
      CoverageMatrix appDeviceCoverageMatrix = new CoverageMatrix(groupInfo);
      findMinimumMappings(cov2match, appDeviceCoverageMatrix);
      List<List<int>> matrix = appDeviceCoverageMatrix.matrix;
      expect(matrix[0][0], equals(-1));
      expect(matrix[0][1], equals(0));
      expect(matrix[1][0], equals(0));
      expect(matrix[1][1], equals(-1));
    });

    test('with OS version as device key', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: {
            'app-root': 'xxx',
            'app-path': 'yyy'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: {
            'platform': 'ios',
            'os-version': '^9.0.0',
            'app-root': 'xxx',
            'app-path': 'zzz'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'os-version'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S',
            'os-version': '9.3.2',
            'screen-size': 'large'
          },
          groupKey: 'os-version'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 5',
            'os-version': '8.4.2',
            'screen-size': 'normal'
          },
          groupKey: 'os-version'
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      List<Map<DeviceSpec, Device>> allDeviceMappings
        = findAllMatchingDeviceMappings(specs, individualMatches);
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      Map<String, List<DeviceSpec>> specGroups = buildGroups(specs);
      GroupInfo groupInfo = new GroupInfo(deviceGroups, specGroups);
      Map<CoverageMatrix, Map<DeviceSpec, Device>> cov2match
        = buildCoverage2MatchMapping(allDeviceMappings, groupInfo);
      CoverageMatrix appDeviceCoverageMatrix = new CoverageMatrix(groupInfo);
      findMinimumMappings(cov2match, appDeviceCoverageMatrix);
      List<List<int>> matrix = appDeviceCoverageMatrix.matrix;
      expect(matrix[0][0], equals(0));
      expect(matrix[0][1], equals(-1));
      expect(matrix[0][2], equals(0));
      expect(matrix[1][0], equals(-1));
      expect(matrix[1][1], equals(0));
      expect(matrix[1][2], equals(-1));
    });

    test('with screen size as device key', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: {
            'screen-size': 'normal',
            'app-root': 'xxx',
            'app-path': 'yyy'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: {
            'screen-size': 'large',
            'app-root': 'xxx',
            'app-path': 'zzz'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'os-version'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S',
            'os-version': '9.3.2',
            'screen-size': 'large'
          },
          groupKey: 'os-version'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 5',
            'os-version': '8.4.2',
            'screen-size': 'normal'
          },
          groupKey: 'os-version'
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      List<Map<DeviceSpec, Device>> allDeviceMappings
        = findAllMatchingDeviceMappings(specs, individualMatches);
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      Map<String, List<DeviceSpec>> specGroups = buildGroups(specs);
      GroupInfo groupInfo = new GroupInfo(deviceGroups, specGroups);
      Map<CoverageMatrix, Map<DeviceSpec, Device>> cov2match
        = buildCoverage2MatchMapping(allDeviceMappings, groupInfo);
      CoverageMatrix appDeviceCoverageMatrix = new CoverageMatrix(groupInfo);
      findMinimumMappings(cov2match, appDeviceCoverageMatrix);
      List<List<int>> matrix = appDeviceCoverageMatrix.matrix;
      expect(matrix[0][0], equals(-1));
      expect(matrix[0][1], equals(-1));
      expect(matrix[0][2], equals(0));
      expect(matrix[1][0], equals(-1));
      expect(matrix[1][1], equals(0));
      expect(matrix[1][2], equals(-1));
    });
  });
}
