//
//  JVSideStatusButton.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "JVSideStatusButton.h"

@implementation JVSideStatusButton

- (BOOL)isOpaque
{
	return NO;
}


- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	
	// Right edge separator (but we need to shift the icon left to be able to use this.)
	//[[NSColor colorWithSRGBRed:0.8 green:0.8 blue:0.8 alpha:1.0] set];
	//NSRectFill(NSMakeRect(self.bounds.size.width - 1, 0, 1, self.bounds.size.height));
	
	
	if (self.menu) {
		NSBezierPath *path = [NSBezierPath bezierPath];
		
		NSRect backingRect = self.bounds;
		if( self.controlSize == NSRegularControlSize ) {
			[path moveToPoint:NSMakePoint( NSWidth( backingRect ) - 6, floor(NSHeight( backingRect ) / 2.0 + 1.0))];
			[path relativeLineToPoint:NSMakePoint( 6, 0 )];
			[path relativeLineToPoint:NSMakePoint( -3, 3 )];
		} else if( self.controlSize == NSSmallControlSize ) {
			[path moveToPoint:NSMakePoint( NSWidth( backingRect ) - 4, floor(NSHeight( backingRect ) / 2.0 + 1.0))];
			[path relativeLineToPoint:NSMakePoint( 4, 0 )];
			[path relativeLineToPoint:NSMakePoint( -2, 3 )];
		}
		
		[path closePath];
		[[[NSColor blackColor] colorWithAlphaComponent:0.65] set];
		[path fill];
	}
}


- (void)mouseDown:(NSEvent *)theEvent
{
	if( ! [self isEnabled] ) return;
	if( ! [self menu] ) {
		[super mouseDown:theEvent];
		return;
	}
	
	[self highlight:YES];
	[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];
	[self highlight:NO];
}


- (void)mouseUp:(NSEvent *)theEvent
{
	[self highlight:NO];
	[super mouseUp:theEvent];
}

@end
