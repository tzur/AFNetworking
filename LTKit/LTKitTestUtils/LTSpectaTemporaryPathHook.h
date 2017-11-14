// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import <Specta/SPTGlobalBeforeAfterEach.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns given \c relativePath appended to the spec temporary base directory. The spec temporary
/// base directory depends on the specific spec currently running, so there's no concern for files
/// overwriting each other. If the spec temporary base directory doesn't exist it is created.
NSString *LTTemporaryPath(NSString *relativePath = @"");

/// Returns \c YES if the given \c relativePath to the spec temporary base directory exists.
BOOL LTFileExistsInTemporaryPath(NSString *relativePath);

/// Specta hook which removes the temporary path from the file system after each spec that created a
/// temporary path.
@interface LTSpectaTemporaryPathHook : NSObject <SPTGlobalBeforeAfterEach>
@end

NS_ASSUME_NONNULL_END
