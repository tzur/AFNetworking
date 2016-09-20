// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import <CoreMedia/CMSampleBuffer.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns an \c NSDictionary that contains a copy of the propagatable metadata from the given \c
/// sampleBuffer. Returns \c nil if \c sampleBuffer doesn't contain any propagatable metadata.
NSDictionary * _Nullable CAMGetPropagatableMetadata(CMSampleBufferRef sampleBuffer);

/// Goes over the root level of key-value pairs in \c metadata, and sets \c sampleBuffer's metadata
/// with these pairs. If the key already exists in \c sampleBuffer's metadata it sets its value to
/// the new value. If the doesn't exist in \c sampleBuffer's metadata, it adds the new key-value
/// to \c sampleBuffer's metadata.
///
/// @note when the value of the key-value pair is an \c NSDictionary (e.g EXIF key-value pair), the
/// function overwrites the entire dictionary with the new dictionary (i.e. it doesn't set the
/// metadata recursively).
void CAMSetPropagatableMetadata(CMSampleBufferRef sampleBuffer, NSDictionary *metadata);

/// Sets the metadata from \c source to \c target.
///
/// This function is equivalent to:
/// @code CAMSetPropagatableMetadata(target, CAMGetPropagatableMetadata(source))
void CAMCopyPropagatableMetadata(CMSampleBufferRef source, CMSampleBufferRef target);

NS_ASSUME_NONNULL_END
