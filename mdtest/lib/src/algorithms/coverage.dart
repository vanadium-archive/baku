// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:dlog/dlog.dart' show Table;

import '../mobile/device.dart' show Device;
import '../mobile/device_spec.dart' show DeviceSpec;
import '../util.dart';

class GroupInfo {
  Map<String, List<Device>> _deviceClusters;
  Map<String, List<DeviceSpec>> _deviceSpecClusters;
  List<String> _deviceClustersOrder;
  List<String> _deviceSpecClustersOrder;

  GroupInfo(
    Map<String, List<Device>> deviceClusters,
    Map<String, List<DeviceSpec>> deviceSpecClusters
  ) {
    _deviceClusters = deviceClusters;
    _deviceSpecClusters = deviceSpecClusters;
    _deviceClustersOrder = new List.from(_deviceClusters.keys);
    _deviceSpecClustersOrder = new List.from(_deviceSpecClusters.keys);
  }

  Map<String, List<Device>> get deviceClusters => _deviceClusters;
  Map<String, List<DeviceSpec>> get deviceSpecClusters => _deviceSpecClusters;
  List<String> get deviceClustersOrder => _deviceClustersOrder;
  List<String> get deviceSpecClustersOrder => _deviceSpecClustersOrder;
}

class CoverageMatrix {

  CoverageMatrix(this.clusterInfo) {
    this.matrix = new List<List<int>>(clusterInfo.deviceSpecClusters.length);
    for (int i = 0; i < matrix.length; i++) {
      matrix[i] = new List<int>.filled(clusterInfo.deviceClusters.length, 0);
    }
  }

  GroupInfo clusterInfo;
  // Coverage matrix, where a row indicats an app cluster and a column
  // indicates a device cluster
  List<List<int>> matrix;

  void fill(Map<DeviceSpec, Device> match) {
    match.forEach((DeviceSpec spec, Device device) {
      int rowNum = clusterInfo.deviceSpecClustersOrder
                              .indexOf(spec.groupKey());
      int colNum = clusterInfo.deviceClustersOrder
                              .indexOf(device.groupKey());
      matrix[rowNum][colNum] = 1;
    });
  }

  void union(CoverageMatrix newCoverage) {
    for (int i = 0; i < matrix.length; i++) {
      List<int> row = matrix[i];
      for (int j = 0; j < row.length; j++) {
        matrix[i][j] |= newCoverage.matrix[i][j];
      }
    }
  }

  void printMatrix() {
    Table prettyMatrix = new Table(1);
    prettyMatrix.columns.add('app key \\ device key');
    prettyMatrix.columns.addAll(clusterInfo.deviceClustersOrder);
    int startIndx = beginOfDiff(clusterInfo.deviceSpecClustersOrder);
    for (int i = 0; i < matrix.length; i++) {
      prettyMatrix.data.add(clusterInfo.deviceSpecClustersOrder[i].substring(startIndx));
      prettyMatrix.data.addAll(matrix[i]);
    }
    print(prettyMatrix);
  }
}

Map<CoverageMatrix, Map<DeviceSpec, Device>> buildCoverage2MatchMapping(
  List<Map<DeviceSpec, Device>> allMatches,
  GroupInfo clusterInfo
) {
  Map<CoverageMatrix, Map<DeviceSpec, Device>> cov2match
    = <CoverageMatrix, Map<DeviceSpec, Device>>{};
  for (Map<DeviceSpec, Device> match in allMatches) {
    CoverageMatrix cov = new CoverageMatrix(clusterInfo);
    cov.fill(match);
    cov2match[cov] = match;
  }
  return cov2match;
}

/// Find a small number of mappings which cover the maximum app-device coverage
/// feasible in given the available devices and specs.  The problem can be
/// treated as a set cover problem which is NP-complete and the implementation
/// follow the spirit of greedy algorithm which is O(log(n)).
/// [ref link]: https://en.wikipedia.org/wiki/Set_cover_problem
Set<Map<DeviceSpec, Device>> findMinimumMappings(
  Map<CoverageMatrix, Map<DeviceSpec, Device>> cov2match,
  GroupInfo clusterInfo
) {
  Set<CoverageMatrix> minSet = new Set<CoverageMatrix>();
  CoverageMatrix base = new CoverageMatrix(clusterInfo);
  while (true) {
    CoverageMatrix currentBestCoverage = null;
    int maxReward = 0;
    for (CoverageMatrix coverage in cov2match.keys) {
      if (minSet.contains(coverage)) continue;
      int reward = computeReward(base, coverage);
      if (maxReward < reward) {
        maxReward = reward;
        currentBestCoverage = coverage;
      }
    }
    if (currentBestCoverage == null) break;
    minSet.add(currentBestCoverage);
    base.union(currentBestCoverage);
  }
  print('Best coverage matrix:');
  base.printMatrix();
  Set<Map<DeviceSpec, Device>> bestMatches = new Set<Map<DeviceSpec, Device>>();
  for (CoverageMatrix coverage in minSet) {
    bestMatches.add(cov2match[coverage]);
  }
  return bestMatches;
}

int computeReward(CoverageMatrix base, CoverageMatrix newCoverage) {
  int reward = 0;
  for (int i = 0; i < base.matrix.length; i++) {
    List<int> row = base.matrix[i];
    for (int j = 0; j < row.length; j++) {
      if (base.matrix[i][j] == 0 && newCoverage.matrix[i][j] == 1)
        reward++;
    }
  }
  return reward;
}
