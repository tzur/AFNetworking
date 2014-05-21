// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsArchiver.h"

/// Archives textures that were initially created from a file inside one of the app's bundles, by
/// storing only the name and the bundle they were created from. Hence, the archiving operation is
/// very quick and memory efficient.
@interface LTTextureContentsBundleArchiver : NSObject <LTTextureContentsArchiver>

/// Initializes with an image name (in format similar to the one given to \c +[UIImage imageNamed:]
/// which exists in the main bundle of the app.
- (instancetype)initWithName:(NSString *)name;

/// Designated initializer: initializes with an image name (in format similar to the one given to
/// \c +[UIImage imageNamed:] which exists in the given bundle.
- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle;

/// Name of the texture backing image.
@property (readonly, nonatomic) NSString *name;

/// Bundle where the image exists.
@property (readonly, nonatomic) NSBundle *bundle;

@end
