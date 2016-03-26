// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileSystemFileManager.h"

/// \c NSFileManager extension that conforms to the \c PTNFileSystemFileManager protocol. The
/// protocol is already supported by \c NSFileManager and this is a mere implicit statement of the
/// protocol conformity.
@interface NSFileManager (FileSystem) <PTNFileSystemFileManager>
@end
