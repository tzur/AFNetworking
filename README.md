# Welcome to the world of LTEngine!

## How to add LTEngine to your project

1. Create a new XCode project.
2. Drag the following files from LTEngine's directory in Finder into XCode's project-navigator:
  - `LTEngine/LTEngine/LTEngine.xcodeproj`
  - `LTEngine/third_party/utils/mantle/Mantle.xcodeproj`
  - `LTEngine/third_party/images/opencv/opencv2.framework` 
  - `LTEngine/third_party/utils/objection/Objection-iOS.framework`
3. Add LTEngine to your project's prefix header file:
  - If your project doesn't have a prefix-header (a `.pch` file):
    - In XCode, create a new file with the `PCH File` template found under iOS -> Other.
    - Congratualtions, your project now has a prefix-header file.
  - Add `#import <LTEngine/LTEngine-Prefix.pch>` to the prefix-header.
4. Add the `Configurations` submodule to your project, full instructions are available [here](https://github.com/lightricks/configuration).
5. In XCode's project-navigator, click on your new project, then in the `Build Settings` tab:
  - Set `Precompile Prefix Header` to `YES`.
  - Set `Prefix Header` to the name of your prefix-header (including the .pch suffix).
  - Add the following paths to `Header Search Paths` with `<LTEngine Path>` replaced by the actual path to LTEngine's directory:
    (It is highly adviced to use relative paths by using `$(SRCROOT)` to indicate the project's root directory.)
    *  `<LTEngine Path>/LTEngine`
    *  `<LTEngine Path>/LTKit/LTKit`
    *  `<LTEngine Path>/third_party/utils/Mantle`
    *  `<LTEngine Path>/LTKit/third_party/utils/libextobjc`
  - If missing, add the following paths to `Framework Search Paths` with `<LTEngine Path>` replaced by the actual path to LTEngine's directory:
    (It is highly adviced to use relative paths by using `$(SRCROOT)` to indicate the project's root directory.)
    *  `<LTEngine Path>/third_party/images/opencv`
    *  `<LTEngine Path>/third_party/utils/objection`
6. In the `General` tab, add the following to `Linked Frameworks and Binaries`: 
  - `Accelerate`
  - `AVFoundation`
  - `AssetsLibrary`
  - `CoreMedia`
7. In the `Build Phases` tab:
  - Add the following to `Target Dependencies`:
    * `LTEngine (LTEngine)`
    * `Mantle-iOS (Mantle)`
  - Add the following to `Link Binary With Libraries`: 
    * `libLTEngine.a`
    * `libLTKit.a`
    * `Mantle.framework` (from `Mantle-iOS`)
    * `libextobjc_iOS.a`
  - Add `LTEngine.bundle` to `Copy Bundle Resources`.
8. LTEngine requires the C++ Standard Library to be included in the project, in order to include it, a `.mm` file must be present in your project. If no such file exists, rename an existing `.m` file to `.mm`.
