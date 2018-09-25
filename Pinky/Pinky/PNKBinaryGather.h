// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

/// Kernel that has a two stage operation. First the kernel reshuffles and gathers the feature
/// channels of each of the primary and secondary inputs. Then the kernel concatenates the results
/// of those gathers in order such that the output channel order maintains that all channels from
/// the primary input come before those of the secondary input. The kernel effectively does the job
/// of three other kernels, two \c PNKGather passes on each of the primary and secondary inputs and
/// a final \c PNKConcatenation pass.
@interface PNKBinaryGather : NSObject <PNKBinaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device. It gathers feature channels of the primary
/// input image according to the channel numbers as they appear in \c primaryFeatureChannelIndices
/// and concatenates them with feature channels of the secondary input image gathered according to
/// the channel numbers as they appear in \c secondaryFeatureChannelIndices. Primary input image
/// must have \c inputFeatureChannels feture channels while secondary input image must have
/// \c inputFeatureChannels feature channels.
- (instancetype)initWithDevice:(id<MTLDevice>)device
   primaryInputFeatureChannels:(NSUInteger)primaryInputFeatureChannels
  primaryFeatureChannelIndices:(const std::vector<ushort> &)primaryFeatureChannelIndices
 secondaryInputFeatureChannels:(NSUInteger)secondaryInputFeatureChannels
secondaryFeatureChannelIndices:(const std::vector<ushort> &)secondaryFeatureChannelIndices
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
