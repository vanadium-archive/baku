// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'report.dart';
import '../globals.dart';
import '../util.dart';
import '../report/locator.dart';

class TestReport extends Report {
  HitmapInfo hitmapInfo;
  List<RoundInfo> roundsInfo;

  TestReport(String reportDataPath, String outputPath)
    : super(reportDataPath, outputPath) {
    this.roundsInfo = <RoundInfo>[];
    _decodeData();
  }

  void _decodeData() {
    try {
      // Read report data file into json object
      dynamic reportData = JSON.decode(reportDataFile.readAsStringSync());
      dynamic hitmap = reportData['hitmap'];
      if (hitmap != null) {
        hitmapInfo = new HitmapInfo(
          hitmap['title'],
          hitmap['data'],
          hitmap['legend'],
          hitmap['reachable-score'],
          hitmap['covered-score']
        );
      }
      int roundNum = 1;
      for (dynamic roundInfo in reportData['rounds-info']) {
        roundsInfo.add(new RoundInfo(roundNum++, roundInfo));
      }
    } on FormatException {
      printError('File ${reportDataFile.absolute.path} is not in JSON format.');
      exit(1);
    } catch (exception, stackTrace) {
      print(exception);
      print(stackTrace);
      exit(1);
    }
  }

  @override
  void writeReport() {
    File indexHTML = createNewFile(
      normalizePath(outputDirectory.path, 'index.html')
    );
    indexHTML.writeAsStringSync(toHTML());
    relatedPaths.forEach(
      (String imagePath) => copyPathToDirectory(imagePath, outputDirectory.path)
    );
  }

  /// Generate the entire HTML report.
  /// TODO(kaiyuanw): Could use local css and js files so that this works
  /// without network connections
  String toHTML() {
    StringBuffer html = new StringBuffer();
    html.writeln(
      '''
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
      <html lang="en">
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
          <title>MDTest - ${fileBaseName(reportDataFile.path)}</title>
          <link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">
          <link rel="stylesheet" type="text/css" href="report.css">
          <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
          <script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
          <script>
            \$(function() {
              \$(\'.list-group-item\').on(\'click\', function() {
                \$(\'.glyphicon\', this)
                .toggleClass(\'glyphicon-chevron-right\')
                .toggleClass(\'glyphicon-chevron-down\');
              });
            });
          </script>
        </head>
        <body>
        <table width="100%" border=0 cellspacing=0 cellpadding=0>
          <tr><td class="title">MDTest - test report</td></tr>
          <tr><td class="ruler"><img width=3 height=3 alt=""></td></tr>
        </table>
      '''
    );
    if (hitmapInfo != null) {
      html.writeln(
        '''
        <div class="container">
          <div class="just-padding">
            ${hitmapInfo.toHTML()}
          </div>
        </div>
        <table width="100%" border=0 cellspacing=0 cellpadding=0>
          <tr><td class="ruler"><img width=3 height=3 alt=""></td></tr>
        </table>
        '''
      );
    }
    html.writeln(
      '''
      <div class="container">
        <div class="just-padding">
          ${roundsInfo.map((RoundInfo round) {
            return
            '''
            <h3>${round.name}<h3>
            <h4>${
              round.highlight.trim().split('\n').map(
                (String line) => HTML_ESCAPE.convert(line)
              ).join('</h4>\n<h4>')
            }</h4>
            ''';
          }).join('\n')}
        </div>
      </div>

      <table width="100%" border=0 cellspacing=0 cellpadding=0>
        <tr><td class="ruler"><img width=3 height=3 alt=""></td></tr>
      </table>

      <div class="container">
        <div class="just-padding">
          <div class="list-group list-group-root well">
            ${roundsInfo.map((RoundInfo round) => round.toHTML()).join('\n')}
          </div>
        </div>
      </div>
      <script>
        \$(document).ready(function(){
          \$('[data-toggle="tooltip"]').tooltip({
              html: true,
              container: 'body'
            });
        });
      </script>
    </body>
  </html>
      '''
    );
    return html.toString();
  }
}

class HitmapInfo {
  String title;
  List<List<String>> data;
  String legend;
  String reachableScore;
  String coveredScore;

  HitmapInfo(
    this.title,
    dynamic hitmapData,
    this.legend,
    this.reachableScore,
    this.coveredScore
  ) {
    this.data = <List<String>>[];
    for (Iterable<String> iterString in hitmapData) {
      data.add(iterString.toList());
    }
  }

  String toHTML() {
    if (data == null || data.isEmpty || data.isNotEmpty && data[0].isEmpty) {
      printError('No hitmap data is found.');
      return '<h3>No hitmap data is found.  '
             'Please rerun `mdtest auto` to collect app-device hitmap.</h3>';
    }
    int rowNum = data.length;
    int colNum = data[0].length ?? 0;
    StringBuffer html = new StringBuffer();
    html.writeln('<h3>$title</h3>');
    html.writeln('<table class="table table-striped">');
    html.writeln('<thead>');
    html.writeln('<tr>${'<td></td>' * colNum}</tr>');
    html.writeln('<tr><th>${data[0].join('</th>\n<th>')}</th></tr>');
    html.writeln('</thead>');
    html.writeln('<tbody>');
    for (int i = 1; i < rowNum; i++) {
      html.writeln('<tr>');
      html.writeln('<th>${data[i][0]}</th>');
      for (int j = 1; j < colNum; j++) {
        String value = data[i][j];
        html.writeln('<td class=\"${tdColorClass(value)}\">$value</td>');
      }
      html.writeln('</tr>');
    }
    html.writeln('</tbody>');
    html.writeln('</table>');
    List<String> legendLines = legend.trim().split('\n');
    html.writeln('<h4>${legendLines.join('</h4>\n<h4>')}</h4>');
    html.writeln(
      '<br>\n'
      '<h4>App-Device Path Coverage (ADPC) score:</h4>\n'
      '<h4>Reachable ADPC score: $reachableScore, '
      'defined by #reachable / #total.</h4>\n'
      '<h4>Covered ADPC score: $coveredScore, '
      'defined by #covered / #reachable.</h4>\n'
    );
    return html.toString();
  }

  String tdColorClass(String value) {
    int val = int.parse(value);
    if (val == -1) {
      return 'warning';
    }
    if (val == 0) {
      return 'danger';
    }
    if (val > 0) {
      return 'success';
    }
    return 'unknown';
  }
}

abstract class Info {
  String id;
  String name;
  String status;

  String toHTML();
}

class RoundInfo extends Info {
  String highlight;
  int skipNum;
  int passNum;
  int failNum;
  List<TestSuiteInfo> testSuitesInfo;

  RoundInfo(int roundNum, dynamic roundInfo) {
    this.id = 'round-$roundNum';
    this.name = 'Round #$roundNum';
    this.highlight = roundInfo['highlight'];
    this.skipNum = roundInfo['skip-num'];
    this.passNum = roundInfo['pass-num'];
    this.failNum = roundInfo['fail-num'];
    this.status = roundInfo['status'];
    this.testSuitesInfo = <TestSuiteInfo>[];
    int suiteNum = 1;
    for (dynamic suiteInfo in roundInfo['suites-info']) {
      testSuitesInfo.add(
        new TestSuiteInfo('$id-suite-${suiteNum++}', suiteInfo)
      );
    }
  }

  @override
  String toHTML() {
    StringBuffer html = new StringBuffer();
    String imgUrl = status == 'fail' ? 'ruby.png' : 'emerald.png';
    html.writeln(
      '''
      <a href="#$id" class="list-group-item" data-toggle="collapse">
        <div class="row">
          <div class="col-sm-3">
            <i class="glyphicon glyphicon-chevron-right"></i>$name
          </div>
          <div class="col-sm-2">Status: $status</div>
          <div class="col-sm-2">#Passed: $passNum</div>
          <div class="col-sm-2">#Failed: $failNum</div>
          <div class="col-sm-2">#Skipped: $skipNum</div>
          <div class="col-sm-1"><img src="$imgUrl" height=20></div>
        </div>
      </a>
      <div class="list-group collapse" id="$id">
        ${
          testSuitesInfo.map(
            (TestSuiteInfo suite) => suite.toHTML()
          ).join('\n')
        }
      </div>
      '''
    );
    return html.toString();
  }
}

class TestSuiteInfo extends Info {
  int skipNum;
  int passNum;
  int failNum;
  List<Info> testSuiteChildrenInfo;

  TestSuiteInfo(String id, dynamic suiteInfo) {
    this.id = id;
    this.name = suiteInfo['name'];
    this.skipNum = suiteInfo['skip-num'];
    this.passNum = suiteInfo['pass-num'];
    this.failNum = suiteInfo['fail-num'];
    this.status = suiteInfo['status'];
    this.testSuiteChildrenInfo = <Info>[];
    int childNum = 1;
    for (dynamic childInfo in suiteInfo['children-info']) {
      String type = childInfo['type'];
      if (type == 'test-group') {
        testSuiteChildrenInfo.add(
          new TestGroupInfo('$id-child-${childNum++}', childInfo)
        );
      } else if (type == 'test-method') {
        testSuiteChildrenInfo.add(
          new TestMethodInfo('$id-child-${childNum++}', childInfo)
        );
      }
    }
  }

  @override
  String toHTML() {
    StringBuffer html = new StringBuffer();
    String imgUrl = status == 'fail' ? 'ruby.png' : 'emerald.png';
    html.writeln(
      '''
      <a href="#$id" class="list-group-item" data-toggle="collapse">
        <div class="row">
          <div class="col-sm-3">
            <i class="glyphicon glyphicon-chevron-right"></i>$name
          </div>
          <div class="col-sm-2">Status: $status</div>
          <div class="col-sm-2">#Passed: $passNum</div>
          <div class="col-sm-2">#Failed: $failNum</div>
          <div class="col-sm-2">#Skipped: $skipNum</div>
          <div class="col-sm-1"><img src="$imgUrl" height=20></div>
        </div>
      </a>
      <div class="list-group collapse" id="$id">
        ${testSuiteChildrenInfo.map((Info child) => child.toHTML()).join('\n')}
      </div>
      '''
    );
    return html.toString();
  }
}

class TestGroupInfo extends Info {
  int skipNum;
  int passNum;
  int failNum;
  // Only for skip reason
  String reason;
  List<TestMethodInfo> testMethodsInfo;

  TestGroupInfo(String id, dynamic groupInfo) {
    this.id = id;
    this.name = groupInfo['name'];
    this.skipNum = groupInfo['skip-num'];
    this.passNum = groupInfo['pass-num'];
    this.failNum = groupInfo['fail-num'];
    this.status = groupInfo['status'];
    this.reason = groupInfo['reason'];
    if (reason != null) {
      reason = reason.replaceAll(new RegExp(r'\n'), '<br>');
    }
    this.testMethodsInfo = <TestMethodInfo>[];
    int methodNum = 1;
    for (dynamic testMethodInfo in groupInfo['methods-info']) {
      String type = testMethodInfo['type'];
      // Ignore nested group.  Nested test groups are not supported yet
      if (type == 'test-method') {
        testMethodsInfo.add(
          new TestMethodInfo('$id-method-${methodNum++}', testMethodInfo)
        );
      } else if (type == 'test-group') {
        throw new UnsupportedError('Nested test groups are not supported yet.');
      }
    }
  }

  @override
  String toHTML() {
    StringBuffer html = new StringBuffer();
    String imgUrl = status == 'fail' ? 'ruby.png' : 'emerald.png';
    html.writeln(
      '<a href="#$id" class="list-group-item" data-toggle="collapse">'
    );
    if (reason != null) {
      html.writeln(
        '<span data-toggle="tooltip" data-placement="right" title="$reason"/>'
      );
    }
    html.writeln(
      '''
        <div class="row">
          <div class="col-sm-3">
            <i class="glyphicon glyphicon-chevron-right"></i>$name
          </div>
          <div class="col-sm-2">Status: $status</div>
          <div class="col-sm-2">#Passed: $passNum</div>
          <div class="col-sm-2">#Failed: $failNum</div>
          <div class="col-sm-2">#Skipped: $skipNum</div>
          <div class="col-sm-1"><img src="$imgUrl" height=20></div>
        </div>
      </a>
      <div class="list-group collapse" id="$id">
        ${
          testMethodsInfo.map(
            (TestMethodInfo method) => method.toHTML()
          ).join('\n')
        }
      </div>
      '''
    );
    return html.toString();
  }
}

class TestMethodInfo extends Info {
  String reason;
  TestMethodInfo(String id, dynamic testMethodInfo) {
    this.id = id;
    this.name = testMethodInfo['name'];
    this.status = testMethodInfo['status'];
    this.reason = testMethodInfo['reason'];
    if (reason != null) {
      reason = reason.replaceAll(new RegExp(r'\n'), '<br>');
    }
  }

  @override
  String toHTML() {
    StringBuffer html = new StringBuffer();
    String imgUrl = status == 'fail' ? 'ruby.png' : 'emerald.png';
    if (reason == null) {
      html.writeln('<a class="list-group-item">');
    } else {
      html.writeln(
        '<a class="list-group-item" data-toggle="tooltip" '
        'data-placement="right" title="$reason">'
      );
    }
    html.writeln(
      '''
        <div class="row">
          <div class="col-sm-3">
            <i class="glyphicon glyphicon-chevron-right"></i>$name
          </div>
          <div class="col-sm-2">Status: $status</div>
          <div class="col-sm-2"></div>
          <div class="col-sm-2"></div>
          <div class="col-sm-2"></div>
          <div class="col-sm-1"><img src="$imgUrl" height=20></div>
        </div>
      </a>
      '''
    );
    return html.toString();
  }
}
