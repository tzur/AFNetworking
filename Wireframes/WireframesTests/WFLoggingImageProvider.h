// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Wireframes/WFImageProvider.h>

NS_ASSUME_NONNULL_BEGIN

/// Image provider for testing that performs as a proxy to an internal \c WFImageProvider, but logs
/// successful and non-successful fetches. This can be used to verify that all the images that are
/// required by the view that is currently being tested exist and can be loaded.
@interface WFLoggingImageProvider : NSObject <WFImageProvider>

/// Initializes with an underlying \c WFImageLoader.
- (instancetype)init;

/// Initializes with an internal image provider to log.
- (instancetype)initWithImageProvider:(id<WFImageProvider>)imageProvider NS_DESIGNATED_INITIALIZER;

/// Waits until all pending requests to the image provider have been performed. Additional requests
/// that arrive after this call will throw an exception.
///
/// While waiting, this method will spin the runloop. If the wait time is larger than
/// <tt>[Expecta asynchronousTestTimeout]</tt>, an exception will be thrown.
- (void)waitUntilCompletion;

/// URLs that are currently being requested.
@property (readonly, nonatomic) NSArray<NSURL *> *ongoingURLs;

/// URLs that were fetched successfully.
@property (readonly, nonatomic) NSArray<NSURL *> *completedURLs;

/// URLs that were not fetched successfully.
@property (readonly, nonatomic) NSArray<NSURL *> *errdURLs;

/// Images that were returned from the internal provider.
@property (readonly, nonatomic) NSArray<UIImage *> *images;

/// Errors that were returned from the internal provider.
@property (readonly, nonatomic) NSArray<NSError *> *errors;

@end

#ifdef __cplusplus
extern "C" {
#endif

/// Installs an instance of the logging image provider as the default image provider, and returns
/// that instance. This allows to use expectations on the returned instance in tests. For example:
///
/// @code
/// it(@"should load all images correctly", ^{
///   WFLoggingImageProvider *provider = WFUseLoggingImageProvider();
///
///   MyView *view = [[MyView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
///   [view layoutIfNeeded];
///
///   [provider waitUntilCompletion];
///
///   expect(provider.completedURLs.count).to.beGreaterThan(0);
///   expect(provider.encounteredErrors).to.beFalsy();
/// });
/// @endcode
///
/// @note you must install the logger before the subject under test creates the view models that
/// are used for loading the images.
///
/// @note the installment is valid only in the current test. To use it in multiple tests add the
/// call to this function to the \c beforeEach block.
WFLoggingImageProvider *WFUseLoggingImageProvider();

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
