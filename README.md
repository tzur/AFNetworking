# Foundations - a fun and powerful iOS infrastructure monorepo

## Summary of existing libraries

| Library Name  | Description                        |
|---------------|------------------------------------|
| Bazaar        | In-app purchase management         |
| Blueprints    | Immutable trees                    |
| Camera        | Camera pipeline infrastructure     |
| CameraUI      | Camera view layer                  |
| DaVinci       | Brushes infrastructure             |
| Fiber         | Networking framework               |
| HelpUI        | UI for help screens                |
| Intelligence  | Analytics library                  |
| LTEngine      | Image processing and rendering     |
| LTKit         | Basic stuff everyone needs         |
| Laboratory    | A/B testing                        |
| Milkshake     | In-house shake screen              |
| Photons       | Asset loading infrastructure       |
| PhotonsUI     | Assets and albums view layer       |
| Pinky         | Metal processing including DNNs    |
| Shopix        | High-level store layer             |
| TinCan        | Inter-app communication            |
| Warehouse     | Persistent storage for projects    |
| Wireframes    | UI building blocks                 |

## Installation instructions

### How to add LTKit to your project

1. Create a new Xcode project.
2. Enter the `LTKit` directory and drag the `LTKit.xcodeproj` directory to your new project.
3. Click on your new project, then on `Build Settings`: 
	- Add `-ObjC` to `Other Linker Flags`.
	- Add references to `LTKit` and `libextobjc` to the `Header Search Paths`. A common setting is to append the string `$(SRCROOT)/../../LTKit $(SRCROOT)/../../third_party/libextobjc`, but it may change if your project's directory has a different relative path to LTKit.
4. In `Build Phases`, add `LTKit (LTKit)` to the `Target Dependencies`, and `libLTKit.a` to `Link Binary With Libraries`.
5. Add `#import <LTKit/LTKit.h>` to each file that uses `LTKit`. Remember to always prefer forward declaration of classes instead of including headers in `.h` files to speed up compilation time.

### How to add LTEngine to your project

1. Create a new Xcode project.
2. Drag the following files from LTEngine's directory in Finder into Xcode's project-navigator:
  - `LTEngine/LTEngine/LTEngine.xcodeproj`
  - `LTEngine/third_party/Mantle/Mantle.xcodeproj`
  - `LTEngine/third_party/opencv/opencv2.framework` 
  - `LTEngine/third_party/objection/Objection-iOS.framework`
  - `LTEngine/third_party/openexr-binaries/lib/libOpenEXR.a`
3. Add LTEngine to your project's prefix header file:
  - If your project doesn't have a prefix-header (a `.pch` file):
    - In XCode, create a new file with the `PCH File` template found under iOS -> Other.
    - Congratulations, your project now has a prefix-header file.
  - Add `#import <LTEngine/LTEngine-Prefix.pch>` to the prefix-header.
4. Add the `Configurations` submodule to your project, full instructions are available [here](https://github.com/lightricks/configuration).
5. In Xcode's project-navigator, click on your new project, then in the `Build Settings` tab:
  - Set `Precompile Prefix Header` to `YES`.
  - Set `Prefix Header` to the name of your prefix-header (including the .pch suffix).
  - Add the following paths to `Header Search Paths` with `<LTEngine Path>` replaced by the actual path to LTEngine's directory:
    (It is highly advised to use relative paths by using `$(SRCROOT)` to indicate the project's root directory.)
    *  `<LTEngine Path>/LTEngine`
    *  `<LTEngine Path>/LTKit/LTKit`
    *  `<LTEngine Path>/third_party/Mantle`
    *  `<LTEngine Path>/third_party/libextobjc`
  - If missing, add the following paths to `Framework Search Paths` with `<LTEngine Path>` replaced by the actual path to LTEngine's directory:
    (It is highly advised to use relative paths by using `$(SRCROOT)` to indicate the project's root directory.)
    *  `<LTEngine Path>/third_party/opencv`
    *  `<LTEngine Path>/third_party/objection`
  - If missing, add the following paths to `Library Search Paths` with `<LTEngine Path>` replaced by the actual path to LTEngine's directory:
    (It is highly advised to use relative paths by using `$(SRCROOT)` to indicate the project's root directory.)
    *  `<LTEngine Path>/third_party/openexr-binaries/lib`
6. a. In the `General` tab, add the following to `Linked Frameworks and Binaries`: 
		- `Accelerate`
		- `AVFoundation`
		- `CoreMedia`
		- `MobileCoreServices`
   b. In the `General` tab, add the following to `Embedded Binaries`: 
		- `Mantle.framework` (from `Mantle-iOS`)
7. In the `Build Phases` tab:
  - Add the following to `Target Dependencies`:
    * `LTEngine (LTEngine)`
    * `Mantle-iOS (Mantle)`
  - Add the following to `Link Binary With Libraries`: 
    * `libLTEngine.a`
    * `libLTKit.a`
    * `Mantle.framework` (from `Mantle-iOS`)
    * `libcompression.tbd`
    * `libextobjc_iOS.a`
  - Add `LTEngine.bundle` to `Copy Bundle Resources`.
8. LTEngine requires the C++ Standard Library to be included in the project, in order to include it, a `.mm` file must be present in your project. If no such file exists, rename an existing `.m` file to `.mm`.
9. In case there are issues, try executing `git submodule update --init --recursive`.
