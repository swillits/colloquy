#import "JVChatTabItem.h"
#import "JVChatWindowController.h"
#import "JVChatProtocols.h"


@implementation JVChatTabItem
- (id) initWithChatViewController:(id <JVChatViewController>) controller {
	if( ( self = [super initWithIdentifier:[controller identifier]] ) ) {
		_controller = controller;
	}
	return self;
}

- (void) dealloc {
	_controller = nil;
}

- (id <JVChatViewController>) chatViewController {
	return _controller;
}

- (NSString *) label {
	return [_controller title];
}

- (NSImage *) icon {
	NSImage *active = [_controller icon];

	if( [_controller respondsToSelector:@selector( statusImage )] && [(id)_controller statusImage] )
		active = [(id)_controller statusImage];

	if( [active size].width > 16. || [active size].height > 16. ) {
		NSImage *ret = [active copy];
		[ret setSize:NSMakeSize( 16., 16. )];
		active = ret;
	}

	return active;
}

- (BOOL) isEnabled {
	if( [_controller respondsToSelector:@selector( isEnabled )] )
		return [(id)_controller isEnabled];
	return YES;
}

- (id) view {
	return [_controller view];
}

- (id) initialFirstResponder {
	if( [_controller firstResponder] )
		return [_controller firstResponder];
	return [_controller view];
}

- (void) _setInitialFirstResponder:(id) first autoGenerated:(BOOL) au {
	// This locks us up when un-hiding the application, not sure why. Not calling super fixes it.
	// [super _setInitialFirstResponder:first autoGenerated:au];
}
@end
