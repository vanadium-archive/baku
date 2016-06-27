// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class Device {
  Device({
    this.id,
    this.modelName
  });

  final String id;
  final String modelName;

  @override
  String toString() => '<id: $id, model-name: $modelName>';
}
