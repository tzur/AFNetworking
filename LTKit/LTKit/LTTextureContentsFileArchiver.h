// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsArchiver.h"

@class LTFileManager;

/// Archives texture's contents to a persistent file. This class is commonly for user created
/// content, or in cases where the contents cannot be loaded from an existing storage.
///
/// @note the current implementation accepts only RGBA8 textures, and will assert on other formats.
@interface LTTextureContentsFileArchiver : NSObject <LTTextureContentsArchiver>

/// Initializes with no file path. In this case, the \c filePath will be randomally generated and
/// the texture will be stored in the temporary directory of the App's sandbox, therefore its
/// storage is volatile.
- (instancetype)init;

/// Designated initializer: initializes with the given file path. The texture will be stored and
/// loaded from the given path.
- (instancetype)initWithFilePath:(NSString *)filePath;

/// Path to file to back the texture with.
@property (readonly, nonatomic) NSString *filePath;

@end
