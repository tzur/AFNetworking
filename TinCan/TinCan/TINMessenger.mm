// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessenger.h"

#import <LTKit/NSURL+Query.h>

#import "NSErrorCodes+TinCan.h"
#import "NSFileManager+TinCan.h"
#import "NSURL+TinCan.h"
#import "TINMessage+UserInfo.h"

NS_ASSUME_NONNULL_BEGIN

/// Returns the \c TINMessenger's URL representation of the given \c message.
static NSURL *TINMessengerURLFromMessage(TINMessage *message) {
  auto components = [[NSURLComponents alloc] init];
  components.scheme = message.targetScheme;
  components.host = @"message";
  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:@"app_group_id" value:message.appGroupID],
    [NSURLQueryItem queryItemWithName:@"message_id" value:message.identifier.UUIDString]
  ];
  return nn(components.URL);
}

@interface TINMessenger ()

/// Backing instance of \c UIApplication which is used for calling \c -openURL:.
@property (readonly, nonatomic) UIApplication *application;

/// File manager which is used to access the file system.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// Application's group ID this messenger's messages belong to.
@property (readonly, nonatomic) NSString *appGroupID;

/// Bundle instance which is used to access application's Info.plist data.
@property (readonly, nonatomic) NSBundle *bundle;

@end

@implementation TINMessenger

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithApplication:(UIApplication *)application
                        fileManager:(NSFileManager *)fileManager appGroupID:(NSString *)appGroupID
                             bundle:(NSBundle *)bundle {
  if (self = [super init]) {
    _application = application;
    _fileManager = fileManager;
    _appGroupID = appGroupID;
    _bundle = bundle;
  }
  return self;
}

+ (instancetype)messengerWithApplication:(UIApplication *)application
                             fileManager:(NSFileManager *)fileManager
                              appGroupID:(NSString *)appGroupID  bundle:(NSBundle *)bundle {
  return [[self alloc] initWithApplication:application fileManager:fileManager
                                appGroupID:appGroupID bundle:bundle];
}

+ (instancetype)messenger {
  return [self messengerWithApplication:[UIApplication sharedApplication]
                            fileManager:[NSFileManager defaultManager]
                             appGroupID:kTINAppGroupID bundle:[NSBundle mainBundle]];
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (void)sendMessage:(TINMessage *)message completion:(LTSuccessOrErrorBlock)block {
  LTParameterAssert(block);
  NSError *error;
  if (!message.url) {
    error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound
                          description:@"Message %@ must have a valid url", message];
  }

  if (![self.fileManager tin_writeMessage:message toURL:nn(message.url) error:&error]) {
    block(NO, [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed underlyingError:error
                            description:@"Failed storing the message %@", message]);
    return;
  }

  auto url = TINMessengerURLFromMessage(message);
  if (![self canSendMessageToTargetScheme:message.targetScheme]) {
    block(NO, [NSError lt_errorWithCode:TINErrorCodeMessageTargetNotFound url:url]);
    return;
  }

  auto completion = ^(BOOL success) {
    if (!success) {
      block(NO, [NSError lt_errorWithCode:TINErrorCodeMessageSendFailed
                              description:@"Failed sending message: %@ to url: %@", message, url]);
      return;
    }
    block(YES, nil);
  };

  [self.application openURL:url options:@{} completionHandler:completion];
}

- (BOOL)canSendMessageToTargetScheme:(NSString *)scheme {
  auto components = [[NSURLComponents alloc] init];
  components.scheme = scheme;
  if (!components.URL) {
    return NO;
  }

  if (![self.application canOpenURL:nn(components.URL)]) {
    return NO;
  }

  return YES;
}

- (nullable TINMessage *)messageFromURL:(NSURL *)url
                                  error:(NSError *__autoreleasing *)error {
  NSError *internalError;
  if (![self.class isTinCanURL:url error:&internalError]) {
    if (error) {
      *error = internalError;
    }
    return nil;
  }

  NSDictionary<NSString *, NSString *> *itemsMap = url.lt_queryDictionary;
  auto _Nullable uuid = [[NSUUID alloc] initWithUUIDString:nn(itemsMap[@"message_id"])];
  if (!uuid) {
    return nil;
  }

  auto _Nullable directoryURL =
      [NSURL tin_messageDirectoryURLWithAppGroup:nn(itemsMap[@"app_group_id"])
                                          scheme:nn(url.scheme) identifier:nn(uuid)];
  auto _Nullable messageURL = [directoryURL URLByAppendingPathComponent:kTINMessageFileName];
  if (!messageURL) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound
                             description:@"Failed getting message URL from URL %@", url];
    }
    return nil;
  }

  auto _Nullable message = [self.fileManager tin_readMessageFromURL:nn(messageURL)
                                                              error:&internalError];
  if (!message) {
    if (error) {
      *error = internalError;
    }
    return nil;
  }

  return message;
}

+ (BOOL)isTinCanURL:(NSURL *)url {
  return [self isTinCanURL:url error:nil];
}

+ (BOOL)isTinCanURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  if (![url.host isEqualToString:@"message"] ) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeInvalidArgument
                             description:@"host %@ must be %@", url.host, @"message"];
    }
    return NO;
  }

  NSDictionary<NSString *, NSArray<NSString *> *> *itemsDictionary = [url lt_queryArrayDictionary];
  for (NSString *name in @[@"app_group_id", @"message_id"]) {
    if (![self isItemsDictionary:itemsDictionary containsItemWithName:name error:error]) {
      return NO;
    }
  }

  return YES;
}

+ (BOOL)isItemsDictionary:(NSDictionary<NSString *, NSArray<NSString *> *> *)itemsDictionary
     containsItemWithName:(NSString *)name
                    error:(NSError *__autoreleasing *)error {
  NSArray<NSString *> * _Nullable names = itemsDictionary[name];
  if (!names) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeInvalidArgument
                             description:@"%@ must appear", name];
    }
    return NO;
  }

  if (names.count != 1) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeInvalidArgument
                             description:@"%@ must appear once", name];
    }
    return NO;
  }

  return YES;
}

- (BOOL)removeAllMessagesForScheme:(NSString *)scheme error:(NSError *__autoreleasing *)error {
  auto schemes = [self bundleSchemes];
  if (!schemes.count || ![schemes containsObject:scheme]) {
    if (error) {
      *error = [NSError lt_errorWithCode:TINErrorCodeNoValidSchemeFound];
    }
    return NO;
  }

  return [self.fileManager tin_removeAllMessagesWithAppGroupID:self.appGroupID scheme:scheme
                                                         error:error];
}

- (NSArray<NSString *> *)bundleSchemes {
  NSArray * _Nullable urlTypesArray = self.bundle.infoDictionary[@"CFBundleURLTypes"];
  if (!urlTypesArray) {
    return @[];
  }

  auto schemes = [NSMutableArray<NSString *> array];

  for (NSDictionary *urlSchemesDictionary in urlTypesArray) {
    NSArray * _Nullable schemesArray = urlSchemesDictionary[@"CFBundleURLSchemes"];
    if (!schemesArray) {
      return @[];
    }

    if (schemesArray.count) {
      [schemes addObject:nn(schemesArray.firstObject)];
    }
  }
  return schemes;
}

@end

NS_ASSUME_NONNULL_END
