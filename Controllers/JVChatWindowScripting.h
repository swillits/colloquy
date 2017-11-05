//
//  JVChatWindowScripting.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/5/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JVChatWindowController.h"



@protocol JVChatListItemScripting
- (NSNumber *) uniqueIdentifier;
- (NSArray *) children;
- (NSString *) information;
- (NSString *) toolTip;
- (BOOL) isEnabled;
@end

@protocol JVChatViewControllerScripting <JVChatListItemScripting>
- (NSWindow *) window;
- (IBAction) close:(id) sender;
@end

