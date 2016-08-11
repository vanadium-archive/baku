// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

abstract class GroupKeyProvider {
  /// key to group devices or specs
  String groupKey();
}

Map<String, List<dynamic>> buildGroups(List<dynamic> elements) {
  Map<String, List<dynamic>> groups = <String, List<dynamic>>{};
  elements.forEach((dynamic element) {
    groups.putIfAbsent(element.groupKey(), () => <dynamic>[])
            .add(element);
  });
  return groups;
}
