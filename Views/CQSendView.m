//
//  CQSendView.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQSendView.h"
#import "MVTextView.h"
#import "CQSendHistory.h"
#import "CQSendStringCommandParser.h"



@interface CQSendView () <NSTextViewDelegate>
@end



@implementation CQSendView
{
	MVTextView * __unsafe_unretained _sendTextView;
	CQSendHistory * _history;
}



- (instancetype)initWithFrame:(NSRect)frameRect
{
	if (!(self = [super initWithFrame:frameRect])) {
		return nil;
	}
	
	_history = [[CQSendHistory alloc] init];
	
	return self;
}



- (void)awakeFromNib
{
	[_sendTextView setUsesSystemCompleteOnTab:[[NSUserDefaults standardUserDefaults] boolForKey:@"JVUsePantherTextCompleteOnTab"]];
	[_sendTextView setContinuousSpellCheckingEnabled:NO];
	[_sendTextView setUsesFontPanel:NO];
	[_sendTextView setUsesRuler:NO];
	[_sendTextView setAllowsUndo:YES];
	[_sendTextView setImportsGraphics:NO];
	[_sendTextView setUsesFindPanel:NO];
	[_sendTextView setUsesFontPanel:NO];
	[_sendTextView reset:nil];
	self.wantsLayer = YES;
	self.layer.backgroundColor = _sendTextView.backgroundColor.CGColor;
}



#pragma mark -
#pragma mark Properties

- (void)setStringToSend:(NSAttributedString *)stringToSend
{
	if (!stringToSend) {
		[_sendTextView reset:nil];
		[self resizeToFit];
	} else {
		[_sendTextView reset:nil];
		[_sendTextView.textStorage insertAttributedString:stringToSend atIndex:0];
	}
}

- (NSAttributedString *)stringToSend
{
	return [_sendTextView.textStorage copy];
}





- (void)resizeToFit
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatInputAutoResizes"]) {
		return;
	}
	
	
	// We need to resize the send view to fit the textview's content.
	// Get the send view's parent dimensions, fit to its width,
	// fit to the text view's height (using the parent-if-split view)'s height blah...
	// 
	
	const CGFloat MIN_HEIGHT_FOR_TRANSCRIPT_AREA = 75.0;
	const CGFloat MIN_HEIGHT_FOR_SEND_AREA = 22.0;
	NSSplitView * splitView = (NSSplitView *)self.superview;
	
	NSRect splitViewFrame = splitView.frame;
	NSRect sendViewFrame = self.frame;
	NSSize contentSize = _sendTextView.minimumSizeForContent;
	CGFloat dividerThickness = splitView.dividerThickness;
	CGFloat maxContentHeight = (NSHeight(splitViewFrame) - dividerThickness - MIN_HEIGHT_FOR_TRANSCRIPT_AREA);
	CGFloat newSendViewHeight = MIN(maxContentHeight, MAX(MIN_HEIGHT_FOR_SEND_AREA, contentSize.height + 8.0));
	
	// Nothing to change
	if (newSendViewHeight == NSHeight(sendViewFrame)) {
		return;
	}
	
	
	[self.delegate sendViewWillResize:self];
	
	// This should work, but it's not doing anything at all...
	//	{
	//		[splitView setPosition:NSHeight(splitViewFrame) - newSendViewHeight - dividerThickness ofDividerAtIndex:0];
	//	}
	
	// So instead do this...
	{
		NSView * displayView = [splitView.subviews objectAtIndex:0];
		NSRect displayFrame = displayView.frame;
		
		displayFrame.size.height = NSHeight( splitViewFrame ) - dividerThickness - newSendViewHeight;
		displayFrame.origin = NSMakePoint( 0., 0. );
		
		sendViewFrame.size.height = newSendViewHeight;
		sendViewFrame.origin.y = NSHeight( displayFrame ) + dividerThickness;
		
		displayView.frame = displayFrame;
		self.frame = sendViewFrame;
		
		[splitView adjustSubviews];
	}
	
	[self.delegate sendViewDidResize:self];
}


#pragma mark -
#pragma mark Text View

- (BOOL)textView:(NSTextView *)textView enterKeyPressed:(NSEvent *)event
{
	[self.delegate sendViewRequestedSend:self];
	return YES;
}



- (BOOL)textView:(NSTextView *)textView returnKeyPressed:(NSEvent *)event
{
	[self.delegate sendViewRequestedSend:self];
	return YES;
}



- (BOOL)textView:(NSTextView *)textView functionKeyPressed:(NSEvent *)event
{
	unichar chr = 0;
	
	if( [[event charactersIgnoringModifiers] length] ) {
		chr = [[event charactersIgnoringModifiers] characterAtIndex:0];
	} else {
		return NO;
	}
	
	// exclude device-dependent flags, caps-lock and fn key (necessary for pg up/pg dn/home/end on portables)
	if( [event modifierFlags] & ~( NSFunctionKeyMask | NSNumericPadKeyMask | NSAlphaShiftKeyMask | NSAlternateKeyMask | 0xffff ) ) {
		return NO;
	}
	
	BOOL usesOnlyArrows = [[NSUserDefaults standardUserDefaults] boolForKey:@"JVSendHistoryUsesOnlyArrows"];
	
	if( chr == NSUpArrowFunctionKey && ( usesOnlyArrows || [event modifierFlags] & NSAlternateKeyMask ) ) {
		return [self upArrowKeyPressed];
	} else if( chr == NSDownArrowFunctionKey && ( usesOnlyArrows || [event modifierFlags] & NSAlternateKeyMask ) ) {
		return [self downArrowKeyPressed];
	}
	
	return NO;
}



- (NSArray *)textView:(NSTextView *)textView stringCompletionsForPrefix:(NSString *)prefix
{
	return nil;
}



- (BOOL)textView:(NSTextView *)textView escapeKeyPressed:(NSEvent *)event
{
	[_sendTextView reset:nil];
	return YES;
}



- (void)textDidChange:(NSNotification *)notification
{
	// The user physically typed into the field, so reset history so that now we're back at head.
	[self.history goToHead];
	
	[self resizeToFit];
}


#pragma mark -

- (BOOL)upArrowKeyPressed
{
	if (self.history.isAtHead) {
		[self.history updateHead:self.stringToSend];
	}
	
	[self.history goBack];
	self.stringToSend = self.history.currentString;
	
	return YES;
}


- (BOOL)downArrowKeyPressed
{
	[self.history goForward];
	self.stringToSend = self.history.currentString;
	return YES;
}







#pragma mark -
#pragma mark Sending

- (void)sendWithConnection:(MVChatConnection *)connection inView:(id<JVChatViewController>)chatView
{
	NSAttributedString * stringToSend = self.stringToSend;
	if (stringToSend.length == 0) {
		return;
	}
	
	[self.history addToHistory:stringToSend];
	self.stringToSend = nil;
	
	NSArray<CQSendCommandAndArgs*> * commands = [CQSendStringCommandParser parseString:stringToSend];
	for (CQSendCommandAndArgs * command in commands) {
		if (command.command) {
			if (![CQSendCommandAndArgs processUserCommand:command toConnection:connection inView:chatView]) {
				[connection sendCommand:command.command withArguments:command.arguments];
			}
		} else {
			[connection sendCommand:command.message withArguments:command.arguments];
		}
	}
}



@end
