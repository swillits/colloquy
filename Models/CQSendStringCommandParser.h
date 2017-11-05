//
//  CQSendStringCommandParser.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol JVChatViewController;
NS_ASSUME_NONNULL_BEGIN


// If it's a plain message, only message is non-nil.
// If it's a command, message is nil, command is non-nil, and arguments may be nil.
@interface CQSendCommandAndArgs : NSObject
@property (readwrite, copy, nullable) NSAttributedString * message;
@property (readwrite, assign) BOOL isAction;

@property (readwrite, copy, nullable) NSString * command;
@property (readwrite, copy, nullable) NSAttributedString * arguments;
+ (instancetype)message:(NSAttributedString *)message isAction:(BOOL)isAction;
+ (instancetype)command:(NSString *)command andArguments:(NSAttributedString * _Nullable)arguments;
@end


@interface CQSendStringCommandParser : NSObject
+ (NSArray<CQSendCommandAndArgs*> *)parseString:(NSAttributedString *)stringToSend asAction:(BOOL)asAction;
@end


// Definitely not the right place to put this, but it should be in some common place rather than duplicated.
@interface CQSendCommandAndArgs (NotTheRightPlace)
+ (BOOL)processUserCommand:(CQSendCommandAndArgs *)command toConnection:(MVChatConnection *)connection inView:(id <JVChatViewController>)view;
@end



@protocol CQSendCommandProcessor
@optional
// Plugins can implement this to intercept commands
- (BOOL)processUserCommand:(NSString *)command withArguments:(NSAttributedString *)arguments toConnection:(MVChatConnection *)connection inView:(id <JVChatViewController>)view;
@end

NS_ASSUME_NONNULL_END

