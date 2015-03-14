### POC using Apigee ###

### Installing Apigee iOS SDK using CocoaPods ###
CocoaPods is the dependency manager for Objective-C projects. Cocoa Pods allows easy installation of iOS Framework and dependencies.

**Install Cocoa Pods***

```
sudo sudo gem install cocoapods
```

**Create iOS Empty Project : ApigeeFOW**

```
Folder:    ~/apigeefow/iOSApp
Workspace: ~/apigeefow/iOSApp/iOSApp.xcworkspace
Project:   ~/apigeefow/iOSApp/iOSApp.xcodeproj
```

**Initialize Cocoa Pods (create Podfile)**

```
cd ~/apigeefow/iOSApp
pod init
vi Podfile
```
Update content of [Podfile](iOSApp/Podfile) as shown below

```
platform :ios, "6.0"

target "iOSApp" do
pod 'ApigeeiOSSDK', '~> 2.0'
end
...
```
**Install Dependencies**

```
pod install
```

**Open Workspace**

```
opend iOSApp.xcworkspace
```

