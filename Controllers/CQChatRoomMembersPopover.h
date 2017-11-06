//
//  CQChatRoomMembersPopover.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/5/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class JVChatRoomPanel;


@interface CQChatRoomMembersPopoverViewController : NSViewController
@property (readwrite, strong, nonatomic, nullable) JVChatRoomPanel * room; 
@property (readonly) NSSize fittingSize;
@end



@interface CQChatRoomMembersPopover : NSPopover
@property (nullable, retain) IBOutlet CQChatRoomMembersPopoverViewController * contentViewController;
@end



