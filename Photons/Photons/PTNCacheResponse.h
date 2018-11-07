// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Wrapper to objects returned by cache, aggregating cached data and its information into a
/// single object.
@interface PTNCacheResponse<DataType: id<NSObject>, InfoType: id<NSObject>> : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c data and \c info.
- (instancetype)initWithData:(nullable DataType)data info:(nullable InfoType)info;

/// Cached data component.
@property (readonly, nonatomic, nullable) DataType data;

/// Associated information of cache data.
@property (readonly, nonatomic, nullable) InfoType info;

@end

NS_ASSUME_NONNULL_END
