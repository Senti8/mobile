Senti8 Mobile Companion
======

This is the mobile companion app to the Senti8 wearable wristband
created as part of the [2014 NASA Space Apps Challenge][1], solving the
[Space Wearables: Fashion Designer to Astronauts challenge][2].

It is designed for a Bluetooth Smart enabled iOS device (iPhone 4s+)
and currently scans for the Red Bear Labs Bluetooth LE Arduino shield.
A simple communications protocol has been outlined for passing messages
to and from the wearable. The communications module firmware is
available in our [wearable repo][3].

## Building
This project uses [CocoaPods][4] for dependency
management, however the Pods directory has been checked in and the
project should build as is. Use the Xcode workspace
(sentiate.xcworkspace) rather than the project to ensure that the Pods
dependencies are available to the app.


[1]: https://2014.spaceappschallenge.org/
[2]: https://2014.spaceappschallenge.org/challenge/space-wearables-fashion-designer-astronauts/
[3]: https://github.com/Senti8/wearable
[4]: http://cocoapods.org/

