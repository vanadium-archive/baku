// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'base/logger.dart';
import 'util.dart';

OperatingSystemUtil os = new OperatingSystemUtil();

Logger defaultLogger = new StdoutLogger();
Logger get logger => defaultLogger;

void printInfo(String message) => logger.info(message);

void printError(String message) => logger.error(message);

void printTrace(String message) => logger.trace(message);

bool briefMode = false;
