//
//  CQSendHistory.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CQSendHistory : NSObject

@property (readonly) BOOL isAtHead;
@property (readonly) NSAttributedString * currentString;

- (void)goToHead;
- (void)goBack;
- (void)goForward;

- (void)updateHead:(NSAttributedString *)string;
- (void)addToHistory:(NSAttributedString *)string;

@end
