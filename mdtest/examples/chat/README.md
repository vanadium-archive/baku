Assume your current directory is the chat folder.  To run `mdtest` for this chat
app, first plugin two Android/iOS devices and just run

```
mdtest auto --format tap \
            --coverage \
            --save-report-data chat-test-report.json \
            --groupby os-version \
            --spec mdtest/chat.spec \
            mdtest/chat_test.dart
```

The above command tells `mdtest` to run in auto mode, print test output in TAP
format, collect coverage information, save report data to chat-test-report.json,
group all devices by their OS version, use the test spec located at
mdtest/chat.spec and run the test script mdtest/chat_test.dart.

The above command will produce the coverage information in
coverage/cov_auto_01.lcov, you can generate the code coverage report by running

```
mdtest generate --report-type coverage \
                --load-report-data coverage/cov_auto_01.lcov \
                --lib lib \
                --output coverage_report
```

and mdtest will invoke lcov to generate a coverage report under coverage_report
folder.

To generate a test report, you can run

```
mdtest generate --report-type test \
                --load-report-data chat-test-report.json \
                --output test_report
```

and mdtest will generate the test report using the data in chat-test-report.json
and write the HTML report under test_report folder.
