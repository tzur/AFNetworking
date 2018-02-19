// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

@protocol LTGPUResource;

NS_ASSUME_NONNULL_BEGIN

/// Proxies all messages to the underlying \c LTGPUResource object, except for the \c -dealloc
/// message. When the \c -dealloc message is sent, it calls the \c -dispose method of the underlying
/// \c resource on the correct \c LTGLContext (where the \c resource was created) to ensure its
/// proper deallocation. This keeps the \c LTGLContext alive during the \c resource disposal.
///
/// @important partial mocking, using \c OCMPartialMock, of the underlying \c resources won't work
/// due to \c OCMock's internal hooks on NSObject (and not on \c NSProxy).
@interface LTGPUResourceProxy : NSProxy

/// Initializes with the given \c resource, to which all the messages will be forwarded.
- (instancetype)initWithResource:(NSObject<LTGPUResource> *)resource;

/// The underlying instance which will receive all messages sent to this object.
@property (readonly, nonatomic) NSObject<LTGPUResource> *resource;

@end

NS_ASSUME_NONNULL_END
