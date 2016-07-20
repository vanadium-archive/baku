// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

abstract class GroupKeyProvider {
  /// key to group devices or specs
  String groupKey();
}

Map<String, List<dynamic>> buildCluster(List<dynamic> elements) {
  Map<String, List<dynamic>> clusters = <String, List<dynamic>>{};
  elements.forEach((dynamic element) {
    clusters.putIfAbsent(element.groupKey(), () => <dynamic>[])
            .add(element);
  });
  return clusters;
}
