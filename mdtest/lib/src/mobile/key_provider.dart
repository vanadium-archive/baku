// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

abstract class ClusterKeyProvider {
  String clusterKey();
}

Map<String, List<dynamic>> buildCluster(List<dynamic> elements) {
  Map<String, List<dynamic>> clusters = <String, List<dynamic>>{};
  elements.forEach((dynamic element) {
    clusters.putIfAbsent(element.clusterKey(), () => <dynamic>[])
            .add(element);
  });
  return clusters;
}
