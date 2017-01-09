# Running Flutter apps (ie. Armadillo) in the Fuchsia tree on both Android and Fuchsia

***NOTE:*** *The instructions here work only for those Flutter apps that don’t depend on Fuchsia infrastructure (ie. don’t depend on FIDL interfaces).  For SysUI this means **armadillo** but not **armadillo_user_shell**.  Since implementations of FIDL interfaces don't exist on other platforms functionality that depends on them will not work.*

When switching between a Fuchsia device and an Android device as a target for a flutter app to run, you will likely need to perform the following steps at least the first time you run on the new target device:

To run/build on Android:
1. ``cd <fuchsia_root>/<flutter app directory>``
1. ``<fuchsia_root>/lib/flutter/bin/flutter upgrade``
1. ``<fuchsia_root>/lib/flutter/bin/flutter build clean``
1. ``<fuchsia_root>/lib/flutter/bin/flutter <test|run>``

To run/build on Fuchsia:
1. ``rm -Rf <fuchsia_root>/out/debug-x86-64/gen/``
1. ``fbuild``

This assumes you have the fbuild (which builds a debug version of Fuchsia) script function installed.
