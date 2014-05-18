// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Category for quick loading of LTShare bundled images. Use this category instead of
/// \c -[UIImage imageNamed:] in the following scenarios:
///
/// - Loading an image from a bundle which is not the main bundle. Note that this is especially
///   important if you're not aware of the actual bundle location inside the main bundle, because
///   otherwise it's possible to use the original \c -[UIImage imageNamed:] call with the image name
///   of \c "<bundle name>/<image name>" to load it.
///
/// - Using modifiers which are not available in imageNamed:, such as 4-inch modifier for iPhone 5
///   ("-568h") and orientation ("-Portrait", "-Landscape").
///
/// Be aware that loading an image with this category doesn't cache it, in contrast to the original
/// \c -[UIImage imageNamed:] method.
///
/// The current filename search order is:
///
/// 1. <name><height modifier><orientation><scale><device><extension>
///    (a-568h-Portrait@2x~iphone.png)
///
/// 2. <name><height modifier><scale><device><extension> (a-568h@2x~iphone.png)
///
/// 3. <name><orientation><scale><device><extension> (a-Portrait@2x~iphone.png)
///
/// 4. <name><scale><device><extension> (a@2x~iphone.png)
///
/// 5. <name><height modifier><scale><extension> (a-568h@2x.png)
///
/// 6. <name><scale><extension> (a@2x.png)
///
/// 7. <name><height modifier><orientation><device><extension> (a-568h-Portrait~iphone.png)
///
/// 8. <name><height modifier><device><extension> (a-568h~iphone.png)
///
/// 9. <name><orientation><device><extension> (a-Portrait~iphone.png)
///
/// 10. <name><device><extension> (a~iphone.png)
///
/// 11. <name><height modifier><extension> (a-568h.png)
///
/// 12. <name><extension> (a.png)
///
/// @note if a filename is duplicated because a modifier is empty (such as a height modifier), it
/// will be returned only once, on its first position.
@interface UIImage (Loading)

/// Returns all the file names (without extension) in the search order defined by this category in
/// an array. If the device is non-retina, returns retina image names after the non-retina names,
/// for fallback in case there are only retina assets.
+ (NSArray *)imageNamesForBasicName:(NSString *)name;

/// Returns image path in the main bundle, or nil if the image cannot be found in the main bundle.
+ (NSString *)imagePathForNameInMainBundle:(NSString *)name;

/// Returns image path from a specific bundle, or nil if the image cannot be found in that bundle.
+ (NSString *)imagePathForName:(NSString *)name fromBundle:(NSBundle *)bundle;

/// Loads image from the main bundle. This method doesn't cache the images as \c
/// -[UIImage imageNamed:].
+ (UIImage *)imageNamedInMainBundle:(NSString *)name;

/// Loads image from a specific bundle. This method doesn't cache the images as \c
/// -[UIImage imageNamed:].
+ (UIImage *)imageNamed:(NSString *)name fromBundle:(NSBundle *)bundle;

@end
