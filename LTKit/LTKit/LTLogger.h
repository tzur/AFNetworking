// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Yaron Inger.

/**
 * For Objective-C code, this library adds flexible, non-intrusive logging capabilities
 * that can be efficiently enabled or disabled via compile switches.
 *
 * There are four levels of logging: Info, Warning, Error and Debug, and each can be enabled
 * independently via the LOGGING_LEVEL_INFO, LOGGING_LEVEL_WARNING, LOGGING_LEVEL_ERROR and
 * LOGGING_LEVEL_DEBUG switches, respectively.
 *
 * In addition, ALL logging can be enabled or disabled via the LOGGING switch.
 *
 * Logging functions are implemented here via macros. Disabling logging, either entirely, or
 * at a specific level, completely removes the corresponding log invocations from the compiled
 * code, thus eliminating both the memory and CPU overhead that the logging calls would add.
 * You might choose, for example, to completely remove all logging from production release code,
 * by setting LOGGING off in your production builds settings. Or, as another example,
 * you might choose to include Error logging in your production builds by turning only LOGGING
 * and LOGGING_LEVEL_ERROR on, and turning the others off.
 *
 * To perform logging, use any of the following function calls in your code:
 *
 *		LogDebug(fmt, ...)	- recommended for temporary use during debugging.
 *
 *		LogInfo(fmt, ...)	- recommended for general, infrequent, information messages.
 *
 *		LogWarning(fmt, ...)	- recommended for use only when there is an warning to be logged.
 *
 *		LogError(fmt, ...)	- recommended for use only when there is an error to be logged.
 *
 * In each case, the functions follow the general NSLog/printf template, where the first argument
 * "fmt" is an NSString that optionally includes embedded Format Specifiers, and subsequent optional
 * arguments indicate data to be formatted and inserted into the string. As with NSLog, the number
 * of optional arguments must match the number of embedded Format Specifiers. For more info, see the
 * core documentation for NSLog and String Format Specifiers.
 *
 * Although you can directly edit this file to turn on or off the switches below, the preferred
 * technique is to set these switches via the compiler build setting GCC_PREPROCESSOR_DEFINITIONS
 * in your build configuration.
 */

/**
 * Set this switch to enable or disable logging capabilities.
 * This can be set either here or via the compiler build setting GCC_PREPROCESSOR_DEFINITIONS
 * in your build configuration. Using the compiler build setting is preferred for this to
 * ensure that logging is not accidentally left enabled by accident in release builds.
 */
#ifndef LOGGING
  #define LOGGING	0
#endif

/**
 * Set any or all of these switches to enable or disable logging at specific levels.
 * These can be set either here or as a compiler build settings.
 * For these settings to be effective, LOGGING must also be defined and non-zero.
 */
#ifndef LOGGING_LEVEL_DEBUG
  #define LOGGING_LEVEL_DEBUG		1
#endif
#ifndef LOGGING_LEVEL_INFO
  #define LOGGING_LEVEL_INFO		1
#endif
#ifndef LOGGING_LEVEL_WARNING
  #define LOGGING_LEVEL_WARNING	1
#endif
#ifndef LOGGING_LEVEL_ERROR
  #define LOGGING_LEVEL_ERROR		1
#endif


// *********** END OF USER SETTINGS - Do not change anything below this line ***********


#if !(defined(LOGGING) && LOGGING)
	#undef LOGGING_LEVEL_DEBUG
  #undef LOGGING_LEVEL_WARNING
  #undef LOGGING_LEVEL_ERROR
  #undef LOGGING_LEVEL_INFO
#endif

#if !(defined(LT_LOG_FORMAT))
  #define LT_LOG_FORMAT(fmt, lvl, ...) [[LTLogger sharedLogger] \
          logWithFormat:fmt \
                   file:[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String] \
                   line:__LINE__ logLevel:lvl, ##__VA_ARGS__]
#endif

#if defined(LOGGING_LEVEL_DEBUG) && LOGGING_LEVEL_DEBUG
  #define LogDebug(fmt, ...) LT_LOG_FORMAT(fmt, LTLogLevelDebug, ##__VA_ARGS__)
#else
  #define LogDebug(...)
#endif

#if defined(LOGGING_LEVEL_INFO) && LOGGING_LEVEL_INFO
	#define LogInfo(fmt, ...) LT_LOG_FORMAT(fmt, LTLogLevelInfo, ##__VA_ARGS__)
#else
	#define LogInfo(...)
#endif

#if defined(LOGGING_LEVEL_WARNING) && LOGGING_LEVEL_WARNING
  #define LogWarning(fmt, ...) LT_LOG_FORMAT(fmt, LTLogLevelWarning, ##__VA_ARGS__)
#else
  #define LogWarning(...)
#endif

#if defined(LOGGING_LEVEL_ERROR) && LOGGING_LEVEL_ERROR
	#define LogError(fmt, ...) LT_LOG_FORMAT(fmt, LTLogLevelError, ##__VA_ARGS__)
#else
	#define LogError(...)
#endif

#pragma mark -
#pragma mark Helper macros for logging common structs
#pragma mark -

#define LogDebugCGRect(rect, fmt, ...) LogDebug( \
    [fmt stringByAppendingString:@"(x: %g, y: %g, width: %g, height: %g)"], \
    ##__VA_ARGS__, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)

#define LogDebugCGPoint(point, fmt, ...) LogDebug( \
    [fmt stringByAppendingString:@"(x: %g, y: %g)"], ##__VA_ARGS__, point.x, point.y)

/// Based on http://vgable.com/blog/2010/08/19/the-most-useful-objective-c-code-ive-ever-written/
#define LogExpression(expr) do { \
    __typeof__(expr) value = (expr); \
    const char *typeCode = @encode(__typeof__(expr)); \
    NSString *output = [LTLogger descriptionFromTypeCode:typeCode andValue:&value]; \
    if (output) { \
      LogDebug(@"%s = %@", #expr, output); \
    } else { \
      LogDebug(@"Unknown type given to log: %s", typeCode); \
    } \
} while (0)

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

/// Global logger for LT projects. This logger supports multiple logging levels, as well as multiple
/// output targets for logging.  Call this class directly only for configuration, but use the
/// logging macros for the logging itself.
@interface LTLogger : NSObject

/// Shared instance of the logger.
+ (LTLogger *)sharedLogger;

/// Returns a printable description given a type (returned from \c \@encode) and a value of that
/// type. If the type cannot be parsed, nil is returned.
///
/// @param type bla bla
/// @param value the bla bla
///
/// @return string from bla bla
///
/// @see LTLogger
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
