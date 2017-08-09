// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <Expecta/Expecta.h>

/// Checks if actual \c LLSignalTestRecorder or \c RACSignal delivered values with \c expected as
/// the current thread.
/// Common usage:
/// @code
/// RACSignal *mySignal = [SignalReturningClass signalReturningMethod];
/// NSThread *myThread = [SignalReturningClass expectedDeliveryThread];
///
/// expect(mySignal).will.deliverValuesOnThread(myThread);
/// @endcode
///
/// @note When using the negating prependers (\c toNot, \c notTo, \c willNot) absence of values
/// delivered altogether will suffice as not delivering values on \c expected.
EXPMatcherInterface(deliverValuesOnThread, (NSThread *expected));
EXPMatcherInterface(deliverValuesOnMainThread, (NSThread *expected));

#define deliverValuesOnMainThread() deliverValuesOnThread([NSThread mainThread])
