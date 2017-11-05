//
//  CQSendCompletion.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Foundation/Foundation.h>
@class JVDirectChatPanel;
@class JVChatRoomPanel;


@protocol CQSendCompletionHandler <NSObject>

- (NSArray *)textView:(NSTextView *)textView stringCompletionsForPrefix:(NSString *)prefix;
- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index;
- (void)textView:(NSTextView *)textView selectedCompletion:(NSString *)completion fromPrefix:(NSString *)prefix;

@end



@interface CQChatSendCompletionHandler : NSObject <CQSendCompletionHandler>
- (instancetype)initWithChat:(JVDirectChatPanel *)directChatPanel;
- (void)pushPreferredNickname:(NSString *)nickname;
- (void)removeAllPreferredNicknames;
- (void)removePreferredNickname:(NSString *)nickname;
- (void)replacePreferredNickname:(NSString *)oldNickname with:(NSString *)new;
@end
