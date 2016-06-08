# Example for UI distribution (casting)

This project demonstrates simple UI distribution across multiple
devices. At this time, only unidirectional unicast is supported.

## Building

To build this project:

* Create a `local.properties` file with these entries:
  * `sdk.dir=[path to the Android SDK]`
  * `flutter.sdk=[path to the Flutter SDK]`

TODO(rosswang): Finalize build instructions after VDL generation works
properly.

## Technologies

This example uses [Vanadium RPC]
(https://vanadium.github.io/concepts/rpc.html) for communication and
[global mount table globbing]
(https://vanadium.github.io/concepts/naming.html) for discovery.

Vanadium has a global discovery facility, but that is not currently
surfaced in Java or Flutter/Dart. At present, all Vanadium usage is
surfaced through Java, to Flutter as `HostMessages`.

This is based on the [hello_services]
(https://github.com/flutter/flutter/tree/master/examples/hello_services)
Flutter example.

## Known issues

* [v.io/i/1356](https://github.com/vanadium/issues/issues/1356) - To
generate VDL, you must uncomment the pertinent sections of the app
`build.gradle`. The build will fail, but it will generate the needed
VDL. Then, recomment them and the normal build will succeed.
* The app crashes after a while; seems to be in the Flutter internals.
* The app will not start properly after first seeking blessings; restart
the app.