// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Represents a memory mapped input file, which allows a read only access to its contents.
@interface LTMMInputFile : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Creates a new memory mapped input file. The input file is based on the file that found in the
/// given \c path with.
///
/// The file will be memory mapped and be accessible using \c data until this object is
/// deallocated. The mapped pages are private, so if a memory mapped output file is mapped to the
/// same file on disk, a copy-on-write will happen and the changes will not be visible to the input
/// file.
///
/// If the file cannot be opened, or memory mapped, \c error will be populated and \c nil will be
/// returned.
- (instancetype)initWithPath:(NSString *)path error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// Path to the memory mapped file.
@property (readonly, nonatomic) NSString *path;

/// Pointer to the mapped data.
@property (readonly, nonatomic) const uchar *data;

/// Size of the buffer pointed by \c data.
@property (readonly, nonatomic) size_t size;

@end

NS_ASSUME_NONNULL_END
