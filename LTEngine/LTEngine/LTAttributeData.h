// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTGPUStruct;

/// Value object containing binary data in a given format. The binary data can readily be provided
/// to \c LTArrayBuffer objects.
@interface LTAttributeData : NSObject <NSCopying>

/// Initializes with a copy of the given \c data in the format of the given \c gpuStruct. The number
/// of bytes of the given \c data must be a multiple of the number of bytes of the given
/// \c gpuStruct.
- (instancetype)initWithData:(NSData *)data inFormatOfGPUStruct:(LTGPUStruct *)gpuStruct;

/// Binary data in the format of the \c gpuStruct of this instance.
@property (readonly, nonatomic) NSData *data;

/// GPU struct determining the format of the binary \c data of this instance.
@property (readonly, nonatomic) LTGPUStruct *gpuStruct;

@end

NS_ASSUME_NONNULL_END
