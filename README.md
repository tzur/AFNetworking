# Welcome to the world of LTKit!

## How to add LTKit to your project

1. Create a new XCode project.
2. Enter the `LTKit` directory and drag the `LTKit.xcodeproj` directory to your new project.
3. Drag the `opencv2.framework` directory from `third_party/images/opencv` to your project to add OpenCV as a framework.
4. Click on your new project, then on `Build Settings`: 
	- Add `-ObjC` to `Other Linker Flags`.
	- Add references to `LTKit` and `libextobjc` to the `Header Search Paths`. A common setting is to append the string `$(SRCROOT)/../../LTKit $(SRCROOT)/../../third_party/utils/libextobjc`, but it may change if your project's directory has a different relative path to LTKit.
5. In the `General` tab, add the following frameworks: `AVFoundation`, `AssetsLibrary`, `CoreMedia`, `OpenGLES`, `GLKit`.
6. In `Build Phases`, add `LTKit (LTKit)` to the `Target Dependencies`, and `libLTKit.a` to `Link Binary With Libraries`.
7. Add `#import <LTKit/LTKit.h>` to each file that uses `LTKit`. Remember to always prefer forward declaration of classes instead of including headers in `.h` files to speed up compilation time.
