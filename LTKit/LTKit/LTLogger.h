// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLoggerMacrosImpl.h"

// For Objective-C code, this library adds flexible, non-intrusive logging capabilities
// that can be efficiently enabled or disabled via compile switches.
//
// There are four levels of logging: Info, Warning, Error and Debug, and each can be enabled
// independently via the LOGGING_LEVEL_INFO, LOGGING_LEVEL_WARNING, LOGGING_LEVEL_ERROR and
// LOGGING_LEVEL_DEBUG preprocessor variables, respectively.
//
// In addition, ALL logging can be enabled or disabled via the LOGGING switch.
//
// Logging functions are implemented here via macros. Disabling logging, either entirely, or
// at a specific level, completely removes the corresponding log invocations from the compiled
// code, thus eliminating both the memory and CPU overhead that the logging calls would add.
// You might choose, for example, to completely remove all logging from production release code,
// by setting LOGGING off in your production builds settings. Or, as another example,
// you might choose to include Error logging in your production builds by turning only LOGGING
// and LOGGING_LEVEL_ERROR on, and turning the others off.
//
// To perform logging, use any of the following function calls in your code:
//
// LogDebug(fmt, ...)	- recommended for temporary use during debugging.
//
// LogInfo(fmt, ...)	- recommended for general, infrequent, information messages.
//
// LogWarning(fmt, ...)	- recommended for use only when there is an warning to be logged.
//
// LogError(fmt, ...)	- recommended for use only when there is an error to be logged.
//
// In each case, the functions follow the general NSLog/printf template, where the first argument
// "fmt" is an NSString that optionally includes embedded Format Specifiers, and subsequent optional
// arguments indicate data to be formatted and inserted into the string. As with NSLog, the number
// of optional arguments must match the number of embedded Format Specifiers. For more info, see the
// core documentation for NSLog and String Format Specifiers.

/// Log debugging macros. Use these macros to log, instead of directly calling methods of LTLogger.
#define LogDebug(fmt, ...) _LogDebug(fmt, ##__VA_ARGS__)
#define LogInfo(fmt, ...) _LogInfo(fmt, ##__VA_ARGS__)
#define LogWarning(fmt, ...) _LogWarning(fmt, ##__VA_ARGS__)
#define LogError(fmt, ...) _LogError(fmt, ##__VA_ARGS__)

/// Logs the given expression via LogDebug(). The expression itself will be printed, together with
/// its value.
#define LogExpression(expr) _LogExpression(expr)

/// Possible logging levels.
typedef NS_ENUM(NSUInteger, LTLogLevel) {
  LTLogLevelDebug,
  LTLogLevelInfo,
  LTLogLevelWarning,
  LTLogLevelError
};

/// Represents a logging target, such as standard output or a file. Classes conforming to this
/// protocol should register themselves in \c LTLogger to start recieving messages.
@protocol LTLoggerTarget <NSObject>

/// Logs the message to the implemented endpoint.
- (void)outputString:(NSString *)message;

@end

/// @class LTLogger
///
/// Global logger for LT projects. This logger supports multiple logging levels, as well as multiple
/// output targets for logging.  Call this class directly only for configuration, but use the
/// logging macros for the logging itself.
///
/// Logging is thread-safe, meaning it's possible to call the various \c logWith... methods from
/// multiple threads. Registering logging targets is currently not-thread safe.
@interface LTLogger : NSObject

/// Shared instance of the logger.
+ (LTLogger *)sharedLogger;

/// Returns a printable description given a type (returned from \c \@encode) and a value of that
/// type. If the type cannot be parsed, nil is returned.
+ (NSString *)descriptionFromTypeCode:(const char *)type andValue:(void *)value;

/// Registers the given logger target to start recieving messages to log.
- (void)registerTarget:(id<LTLoggerTarget>)target;

/// Logs the message to all selected targets.
- (void)logWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

/// Logs the message to all selected targets.
- (void)logWithFormat:(NSString *)format arguments:(va_list)argList NS_FORMAT_FUNCTION(1, 0);

/// Logs the message, including originating file name, line number and log level to all selected
/// targets.
- (void)logWithFormat:(NSString *)format file:(const char *)file line:(int)line
             logLevel:(LTLogLevel)logLevel, ... NS_FORMAT_FUNCTION(1, 5);

/// Minimal log level to log (by the order defined in the \c LTLogLevel enum).
@property (nonatomic) LTLogLevel minimalLogLevel;

@end

/// Logging target which logs to the standard output.
@interface LTOutputLogger : NSObject <LTLoggerTarget>
@end
