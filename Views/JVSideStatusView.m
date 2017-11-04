#import "JVSideStatusView.h"
#import "NSImageAdditions.h"

@implementation JVSideStatusView
- (void) resetCursorRects {
	[super resetCursorRects];
	if( ! splitView ) return;

	NSImage *resizeImage = [NSImage imageNamed:@"sidebarResizeWidget"];
	NSRect location;
	location.size = [resizeImage size];
	location.origin = NSMakePoint( NSWidth( [self bounds] ) - [resizeImage size].width, 0. );
	[self addCursorRect:location cursor:[NSCursor resizeLeftRightCursor]];
}

- (void) drawRect:(NSRect) rect {
	NSImage * bg = [NSImage imageNamed:@"sidebarStatusAreaBackground"];
	[bg drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];

	if( splitView ) {
		NSImage *resizeImage = [NSImage imageNamed:@"sidebarResizeWidget"];
		NSPoint point = NSMakePoint( NSWidth( [self bounds] ) - [resizeImage size].width, 0. );
		[resizeImage drawAtPoint:point fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	}
}

- (void) mouseDown:(NSEvent *) event {
	if( ! splitView ) return;
    NSPoint clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];

	NSImage *resizeImage = [NSImage imageNamed:@"sidebarResizeWidget"];
	NSRect location;
	location.size = [resizeImage size];
	location.origin = NSMakePoint( NSWidth( [self bounds] ) - [resizeImage size].width, 0. );

	_insideResizeArea = ( NSPointInRect( clickLocation, location ) );
	if( ! _insideResizeArea ) return;

	clickLocation = [self convertPoint:[event locationInWindow] fromView:[self superview]];
	_clickOffset = NSWidth( [[self superview] frame] ) - clickLocation.x;
}

- (void) mouseDragged:(NSEvent *) event {
	if( ! splitView || ! _insideResizeArea ) return;

	[[NSNotificationCenter defaultCenter] postNotificationName:NSSplitViewWillResizeSubviewsNotification object:splitView];

    NSPoint clickLocation = [self convertPoint:[event locationInWindow] fromView:[self superview]];

	NSRect newFrame = [[self superview] frame];
	newFrame.size.width = clickLocation.x + _clickOffset;

	id <NSSplitViewDelegate> delegate = [splitView delegate];
	if( delegate && [delegate respondsToSelector:@selector( splitView:constrainSplitPosition:ofSubviewAt: )] ) {
		float new = [delegate splitView:splitView constrainSplitPosition:newFrame.size.width ofSubviewAt:0];
		newFrame.size.width = new;
	}

	if( delegate && [delegate respondsToSelector:@selector( splitView:constrainMinCoordinate:ofSubviewAt: )] ) {
		float min = [delegate splitView:splitView constrainMinCoordinate:0. ofSubviewAt:0];
		newFrame.size.width = MAX( min, newFrame.size.width );
	}

	if( delegate && [delegate respondsToSelector:@selector( splitView:constrainMaxCoordinate:ofSubviewAt: )] ) {
		float max = [delegate splitView:splitView constrainMaxCoordinate:0. ofSubviewAt:0];
		newFrame.size.width = MIN( max, newFrame.size.width );
	}

	[[self superview] setFrame:newFrame];

	[splitView adjustSubviews];

	[[NSNotificationCenter defaultCenter] postNotificationName:NSSplitViewDidResizeSubviewsNotification object:splitView];
}
@end
