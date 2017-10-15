// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAppLifecycleTimer.h"
#import "INTDataStructures.h"
#import "INTDeviceInfoObserver.h"
#import "INTTransformerBlock.h"

NS_ASSUME_NONNULL_BEGIN

@protocol INTEventLogger;

/// \c INTEventsPipeline configration. Contains parameters used for initializing an
/// \c INTEventsPipeline object.
typedef struct {
  /// Used for generating context when low level events are reported, in order to pass to
  /// \c transformerBlocks for further processing.
  INTAppContextGeneratorBlock contextGeneratorBlock;

  /// Used for transforming low level events into high level events.
  std::vector<INTTransformerBlock> transformerBlocks;

  /// Used for logging high level events.
  NSArray<id<INTEventLogger>> *eventLoggers;

  /// Used for fetching total run time and foreground time of the application.
  id<INTAppLifecycleTimer> appLifecycleTimer;
} INTEventsPipelineConfiguration;

/// This class manages the low level to high level event reporting pipline of Intelligence, using
/// a context generator block and transformer blocks.
///
/// The pipeline of transforming and reporting events is the following:
///
/// A. Initialize an empty application context dictionary.
/// B. When a new low level event is reported:
///   - Create a new metadata, containing total application run time, total foreground state run
///     time, device timestamp and unique event id for the event. All time related properties are
///     calculated on the reception of the event.
///   - Execute the \c contextGeneratorBlock, and update the application context with its result.
///   - For each transformer:
///     - Run the transformer with the event, the aggregated data returned by its previous
///       execution, the provided application context and event metadata.
///     - Store the aggregated data for the next process.
///   - Log all the high level events that were generated by executing all of the transformers in
///     this round.
@interface INTEventsPipeline : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c configuration.
- (instancetype)initWithConfiguration:(const INTEventsPipelineConfiguration &)configuration
    NS_DESIGNATED_INITIALIZER;

/// Reports a low level \c event. \c event goes through the event reporting pipeline, as described
/// in the class documentation. This method is thread safe. Events are processed asynchronously via
/// a serial queue, so it make take some time between the call to the receiver has returned to a log
/// of a generated high level events.
- (void)reportLowLevelEvent:(id)event;

@end

/// Protocol for observing \c INTDeviceInfo that are reported by an \c INTDeviceInfoManager.
@interface INTEventsPipeline (DeviceInfoManagerDelegate) <INTDeviceInfoObserverDelegate>

/// Reports an \c INTDeviceInfoLoadedEvent with \c deviceInfo, deviceInfoRevisionID and
/// \c isNewRevision.
- (void)deviceInfoObserver:(INTDeviceInfoObserver *)deviceInfoObserver
          loadedDeviceInfo:(INTDeviceInfo *)deviceInfo
      deviceInfoRevisionID:(NSUUID *)deviceInfoRevisionID
             isNewRevision:(BOOL)isNewRevision;

/// Reports an \c INTDeviceInfoChangedEvent with \c deviceToken converted to a string as defined by
/// <tt>-[INTDeviceInfoChangedEvent deviceToken]</tt>.
- (void)deviceTokenDidChange:(nullable NSData *)deviceToken;

/// Reports an \c INTAppRunCountUpdatedEvent with \c runCount.
- (void)appRunCountUpdated:(NSNumber *)runCount;

@end

NS_ASSUME_NONNULL_END
