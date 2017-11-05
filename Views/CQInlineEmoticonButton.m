//
//  CQInlineEmoticonButton.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQInlineEmoticonButton.h"

@implementation CQInlineEmoticonButton

- (void)mouseDown:(NSEvent *)event
{
	if (!self.isEnabled || !self.menu) {
		return;
	}
	
	[self highlight:YES];
	[NSMenu popUpContextMenu:self.menu withEvent:event forView:self];
	[self highlight:NO];
}

@end
