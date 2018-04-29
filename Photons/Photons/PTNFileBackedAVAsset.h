// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTValueObject.h>

#import "PTNAVDataAsset.h"

@class LTPath;

NS_ASSUME_NONNULL_BEGIN

/// An implementation of the \c PTNAVDataAsset protocol that encapsulates a local file.
///
/// @note This asset assumes that the file at the given path doesn't change its location or contents
/// while the asset exists. If underlying data or location does change the asset's behavior is
/// undefined.
///
/// @note \c saveToFile: will trigger a file copying operation. \c fetchData will trigger a file
/// read operation from \c path. \c fetchAVAsset will create create an \c AVAsset from \c path.
@interface PTNFileBackedAVAsset : LTValueObject <PTNAVDataAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with file located at \c path as the audiovisual file to use as asset.
- (instancetype)initWithFilePath:(LTPath *)path NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
