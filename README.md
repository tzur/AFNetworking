# Welcome to the world of LTEngine!

## How to add LTEngine to your project

1. Create a new XCode project.
2. Enter the `LTEngine` directory and drag the `LTEngine.xcodeproj` directory to your new project.
3. Drag `third_party/images/opencv/opencv2.framework` and `third_party/utils/objection/Objection-iOS.framework` to your project to add OpenCV and Objection as frameworks.
4. Click on your new project, then on `Build Settings`:
	- Add `-ObjC` to `Other Linker Flags`.
	- Add references to `LTEngine` and `libextobjc` to the `Header Search Paths`. A common setting is to append the string `$(SRCROOT)/../../LTEngine $(SRCROOT)/../../third_party/utils/libextobjc`, but it may change if your project's directory has a different relative path to LTEngine.
5. In the `General` tab, add the following to `Linked Frameworks and Binaries`: `Accelerate`, `AVFoundation`, `AssetsLibrary`, `CoreMedia`, `OpenGLES`, `GLKit`.
6. In `Build Phases`, add `LTEngine (LTEngine)` to the `Target Dependencies`.
7. Still in `Build Phases`, add the following to `Link Binary With Libraries`: `libLTEngine.a`, `libLTKit.a`, `libMantle-iOS.a`, `libextobjc_iOS.a`.
