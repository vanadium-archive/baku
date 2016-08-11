Assume your current directory is the shared_counter_test folder.  To run
`mdtest` for this shared-counter example, first plugin at least two Android/iOS devices and just run

```
mdtest run --brief \
           --format none \
           --coverage \
           --spec shared_counter.spec \
           shared_counter_test_1.dart shared_counter_test_2.dart
```

The above command tells `mdtest` to run in run mode, only spit out test result
and print test output using the dart test default format, collect coverage
information, use the test spec located at shared_counter.spec and run the test
scripts shared_counter_test_1.dart and shared_counter_test_2.dart.

The above command will produce the coverage information in both
plus/coverage/cov_run_01.lcov and minus/coverage/cov_run_01.lcov, you can
generate the code coverage report by running (assuming your current directory is
either plus or minus folder)

```
mdtest generate --report-type coverage \
                --load-report-data coverage/cov_run_01.lcov \
                --lib lib \
                --output coverage_report
```

and mdtest will invoke lcov to generate a coverage report under coverage_report
folder.
