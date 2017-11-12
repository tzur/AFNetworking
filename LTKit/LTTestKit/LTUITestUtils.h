// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "LTUIInterruptionHandler.h"

NS_ASSUME_NONNULL_BEGIN

/// Returns a UI interruption handler that handles alerts by allowing them. The output of this
/// function can be used as the input \c LTUIInterruptionHandler for \c addInterruptionMonitor if
/// the wanted hanling is to always allow.
LTUIInterruptionHandler *lt_getAllowAllAlertsBlock();

/// Adds the given UI interruption handler to the current context so that it'll be invoked upon
/// UI interruptions.
void lt_addInterruptionMonitor(LTUIInterruptionHandler *UIInterruptionHandler);

NS_ASSUME_NONNULL_END
