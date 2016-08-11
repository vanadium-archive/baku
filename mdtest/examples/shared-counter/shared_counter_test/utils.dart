// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'dart:io';

const String resetCounterUrl = 'http://baku-shared-counter.appspot.com/cleanup_count';

Future<Null> resetCounter() async {
  HttpClient client = new HttpClient();
  HttpClientRequest request = await client.getUrl(Uri.parse(resetCounterUrl));
  await request.close();
}
