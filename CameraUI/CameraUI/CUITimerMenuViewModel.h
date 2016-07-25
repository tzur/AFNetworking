// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUIMenuItemViewModel.h"

@class CUITimerModeViewModel;

@protocol CUITimerContainer;

NS_ASSUME_NONNULL_BEGIN

/// View model for a menu with different interval options for a \c id<CUITimerContainer>.
///
/// \c subitems contains the available \c intervals. \c title and \c iconURL are taken from the
/// first interval that matches (i.e. is within \c precision) the \c id<CUITimerContainer>. If no
/// interval currently matches, \c title and \c iconURL are \c nil.
///
/// The \c hidden and \c selected properties are always \c NO.
///
/// Calling \c didTap doesn't do anything.
@interface CUITimerMenuViewModel : NSObject <CUIMenuItemViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c timerContainer, and \c timerModes that will be the \c subitems of
/// the receiver.
- (instancetype)initWithTimerContainer:(id<CUITimerContainer>)timerContainer
                            timerModes:(NSArray<CUITimerModeViewModel *> *)timerModes
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
