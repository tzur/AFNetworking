// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Object for wrapping a block of UI interruption handling code together with the data needed in
/// order to add it as an interruption monitor.
/// @see [XCTestCase addUIInterruptionMonitorWithDescription:handler:]
@interface LTUIInterruptionHandler : LTValueObject

/// Type for the UI interruption handling block. The handler is passed an XCUIElement representing
/// the top level UI element for the alert. The return value should be YES if UI interruption
/// was handled, NO if it wasn't.
typedef BOOL (^LTUIInterruptionHandlerBlock)(XCUIElement *);

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c description and \c block.
- (instancetype)initWithDescription:(NSString *)description
                           withBlock:(LTUIInterruptionHandlerBlock)block NS_DESIGNATED_INITIALIZER;

/// Textual description for this handler. Mainly used for debugging and analysis.
@property (readonly, nonatomic) NSString *descriptionText;

/// Handler's code.
@property (readonly, nonatomic) LTUIInterruptionHandlerBlock block;

@end

NS_ASSUME_NONNULL_END
