// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Represents a memory mapped output file, which allows both reading from and writing to. The file
/// must be created with an initial size (which cannot be changed while the object is alive), but it
/// can be truncated upon destruction.
@interface LTMMOutputFile : NSObject

/// Creates a new memory mapped output file. The output file is created in the given \c path with
/// the given \c size and \c mode. If the file already exists, it will be overwritten (if
/// permissions allow so).
///
/// The file will be memory mapped and be accessible using \c data until this object is deallocated.
/// The mapped pages are shared, so two memory mapped output files that back the same file on disk
/// will share their changes immediately.
///
/// If the file cannot be opened, truncated to the given \c size or memory mapped, \c error will be
/// populated.
- (instancetype)initWithPath:(NSString *)path size:(size_t)size mode:(mode_t)mode
                       error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// Path to the memory mapped file.
@property (readonly, nonatomic) NSString *path;

/// Pointer to the mapped data.
@property (readonly, nonatomic) uchar *data;

/// Size of the buffer pointed by \c data.
@property (readonly, nonatomic) size_t size;

/// Size of the file after it will be unmapped from memory.
@property (nonatomic) size_t finalSize;

@end

NS_ASSUME_NONNULL_END
