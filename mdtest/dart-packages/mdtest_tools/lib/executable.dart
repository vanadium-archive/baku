// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/commands/doctor.dart';
import 'src/commands/create.dart';
import 'src/commands/run.dart';
import 'src/commands/auto.dart';
import 'src/commands/generate.dart';
import 'src/runner/mdtest_command_runner.dart';
import 'src/util.dart';

Future<Null> main(List<String> args) async {
  MDTestCommandRunner runner = new MDTestCommandRunner()
    ..addCommand(new DoctorCommand())
    ..addCommand(new CreateCommand())
    ..addCommand(new RunCommand())
    ..addCommand(new AutoCommand())
    ..addCommand(new GenerateCommand());

    return Chain.capture(() async {
      dynamic result = await runner.run(args);
      exit(result is int ? result : 0);
    }, onError: (dynamic error, Chain chain) {
      if (error is UsageException) {
        stderr.writeln(error.message);
        stderr.writeln();
        stderr.writeln(
          "Run 'mdtest -h' (or 'mdtest <command> -h') for available "
          "mdtest commands and options."
        );
        // Argument error exit code.
        exit(64);
      } else {
        stderr.writeln();
        stderr.writeln('Oops; mdtest has exit unexpectedly: "${error.toString()}".');

        File crashReport = _createCrashReport(args, error, chain);
        stderr.writeln(
          'Crash report written to ${crashReport.path};\n'
          'please let us know at https://github.com/vanadium/baku/issues.'
        );

        exit(1);
      }
    });
}

File _createCrashReport(List<String> args, dynamic error, Chain chain) {
  File crashFile = getUniqueFile(Directory.current, 'mdtest', 'log');

  StringBuffer buffer = new StringBuffer();

  buffer.writeln('MDTest crash report; please file at https://github.com/vanadium/baku/issues.\n');

  buffer.writeln('## command\n');
  buffer.writeln('mdtest ${args.join(' ')}\n');

  buffer.writeln('## exception\n');
  buffer.writeln('$error\n');
  buffer.writeln('```\n${chain.terse}```\n');

  crashFile.writeAsStringSync(buffer.toString());

  return crashFile;
}
