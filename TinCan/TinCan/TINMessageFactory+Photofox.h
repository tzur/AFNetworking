// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "TINMessageFactory.h"

NS_ASSUME_NONNULL_BEGIN

/// Action represeting an image edit request from Photox.
extern NSString * const kTINPhotofoxImageEditAction;

/// \c TinCan scheme for \c Photofox.
extern NSString * const kTINPhotofoxScheme;

/// Category augmenting \c TINMessageFactory with methods for the creation of messages to Photofox.
@interface TINMessageFactory (Photofox)

/// Returns a message with the given \c data, \c uti, \c kTINPhotofoxScheme set as \c targetScheme,
/// \c TINMessageTypeRequest as \c type, \c kTINPhotofoxImageEditAction as \c action, \c context
/// as \c context and \c appDisplayName saved in \c userInfo under the key
/// \c kTINMessageAppDisplayName.
/// Returns \c nil if an error occurs and sets the \c error.
///
/// If the user will choose to reply to this message, the returned message will have
/// \c TINMessageTypeReply as \c type, \c kTINPhotofoxImageEditAction as \c action,
/// \c context as \c context and the user-created image as \c filesURL.firstObject.
///
/// @param data Data is persistently stored in the message's associated directory and can be
/// obtained from the returned \c TINMessage \c fileNames array.
/// @param uti UTI of the \c data. It should conform to \c public.image.
/// @param context Context that the sender will receive unchanged in the return message.
/// @param appDisplayName Name of the sending app, that will appear on the back button.
/// @param error An error which is set if an error occurs.
- (nullable TINMessage *)en_imageEditingRequestWithData:(NSData *)data uti:(NSString *)uti
                                                context:(id<NSSecureCoding>)context
                                         appDisplayName:(NSString *)appDisplayName
                                                  error:(NSError **)error;

@end

/// Category augmenting \c TINMessage with properties for usage in Photofox.
@interface TINMessage (Photofox)

/// Display name of the app that sent this message. Returns \c nil if no display name was put
/// with the \c kTINMessageAppDisplayName key in the message's \c userInfo.
@property (readonly, nonatomic, nullable) NSString *en_appDisplayName;

@end

NS_ASSUME_NONNULL_END
