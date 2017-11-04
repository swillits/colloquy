//
//  CQSendView.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQSendView.h"
#import "MVTextView.h"
#import "CQInlineEmoticonButton.h"
#import "CQSendHistory.h"
#import "CQSendStringCommandParser.h"
#import "JVChatMessage.h"



@interface CQSendViewController () <MVTextViewDelegate>
@end



@implementation CQSendViewController
{
	MVTextView * __unsafe_unretained _sendTextView;
	CQInlineEmoticonButton * __unsafe_unretained _emoticonButton;
	CQSendHistory * _history;
}



- (instancetype)init
{
	if (!(self = [super init])) {
		return nil;
	}
	
	_history = [[CQSendHistory alloc] init];
	
	return self;
}



- (NSString *)nibName
{
	return @"CQSendView";
}



- (void)loadView
{
	[super loadView];
	
	
	self.emoticonButton.toolTip = NSLocalizedString( @"Emoticons", "choose emoticons inline button" );
	
	[_sendTextView setUsesSystemCompleteOnTab:[[NSUserDefaults standardUserDefaults] boolForKey:@"JVUsePantherTextCompleteOnTab"]];
	
	[_sendTextView setContinuousSpellCheckingEnabled:NO]; // NO in Console, but YES elsewhere? 
	[_sendTextView setUsesRuler:NO];
	[_sendTextView setAllowsUndo:YES];
	[_sendTextView setImportsGraphics:NO];
	[_sendTextView setUsesFontPanel:NO];
	
	[_sendTextView setSelectable:YES];
	[_sendTextView setEditable:YES];
	
	[_sendTextView setRichText:YES]; // NO in Console, but YES elsewhere?
	[_sendTextView setUsesFontPanel:YES]; // NO in Console, but YES elsewhere.
	
	[_sendTextView reset:nil];
	
	self.view.wantsLayer = YES;
	self.view.layer.backgroundColor = _sendTextView.backgroundColor.CGColor;
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
	[_sendTextView.textStorage.mutableString replaceOccurrencesOfString:@"\r" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, _sendTextView.string.length)];
	return [_sendTextView.textStorage copy];
}


- (BOOL)stringToSendIsACommand
{
	return [_sendTextView.string hasPrefix:@"/"] && ![_sendTextView.string hasPrefix:@"//"];
}


- (void)insertEmoticon:(NSString *)emoticon
{
	if (_sendTextView.string.length > 0) {
		[_sendTextView replaceCharactersInRange:NSMakeRange(_sendTextView.string.length, 0) withString:@" "];
	}
	
	[_sendTextView replaceCharactersInRange:NSMakeRange(_sendTextView.string.length, 0) withString:[NSString stringWithFormat:@"%@ ", emoticon]];
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
	NSSplitView * splitView = (NSSplitView *)self.view.superview;
	
	NSRect splitViewFrame = splitView.frame;
	NSRect sendViewFrame = self.view.frame;
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
		self.view.frame = sendViewFrame;
		
		[splitView adjustSubviews];
	}
	
	[self.delegate sendViewDidResize:self];
}


#pragma mark -
#pragma mark Text View

- (BOOL)textView:(NSTextView *)textView enterKeyPressed:(NSEvent *)event
{
	BOOL handled = NO;
	
	if (_sendTextView.hasMarkedText) {
		handled = NO;
		
	} else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MVChatSendOnEnter"] ) {
		[self.delegate sendViewRequestedSend:self options:0];
		handled = YES;
		
	} else if( [[NSUserDefaults standardUserDefaults] boolForKey:@"MVChatActionOnEnter"] ) {
		[self.delegate sendViewRequestedSend:self options:CQSendViewSendAsAction];
		handled = YES;
	}
	
	return handled;
}



- (BOOL)textView:(NSTextView *)textView returnKeyPressed:(NSEvent *)event
{
	BOOL handled = NO;
	
	if (_sendTextView.hasMarkedText) {
		handled = NO;
		
	} else if ((event.modifierFlags & NSAlternateKeyMask) != 0) {
		handled = NO;
		
	} else  if((event.modifierFlags & NSControlKeyMask) != 0 ) {
		[self.delegate sendViewRequestedSend:self options:CQSendViewSendAsAction];
		handled = YES;
		
	} else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MVChatSendOnReturn"] ) {
		[self.delegate sendViewRequestedSend:self options:0];
		handled = YES;
		
	} else if( [[NSUserDefaults standardUserDefaults] boolForKey:@"MVChatActionOnReturn"] ) {
		[self.delegate sendViewRequestedSend:self options:CQSendViewSendAsAction];
		handled = YES;
	}
	
	return handled;
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
	
	// TODO-SW: This was in JVDirectChatPanel but not Console
	//	} else if( chr == NSPageUpFunctionKey || chr == NSPageDownFunctionKey || chr == NSHomeFunctionKey || chr == NSBeginFunctionKey || chr == NSEndFunctionKey ) {
	//		[[[[display mainFrame] findFrameNamed:@"content"] frameView] keyDown:event];
	//		return YES;
	//	}
	
	return NO;
}



- (NSArray *)textView:(NSTextView *)textView stringCompletionsForPrefix:(NSString *)prefix
{
	// TODO-SW: See CQSendCompletion
	return nil;
}
	
	
- (NSArray *) textView:(NSTextView *) textView completions:(NSArray *) words forPartialWordRange:(NSRange) charRange indexOfSelectedItem:(NSInteger *) index
{
	// TODO-SW: See CQSendCompletion
	return nil;
}



- (BOOL)textView:(NSTextView *)textView escapeKeyPressed:(NSEvent *)event
{
	// TODO-SW: JVDirectChat does this test, but console just always called reset:
	if (_sendTextView.string.length == 0 && ! [[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatInputRetainsFormatting"]) {
		[_sendTextView reset:nil];
	} else {
		[_sendTextView setString:@""];
	}
	
	return YES;
}



- (void)textDidChange:(NSNotification *)notification
{
	if (_sendTextView.string.length == 0 && ! [[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatInputRetainsFormatting"]) {
		[_sendTextView reset:nil];
	}
	
	
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

- (void)sendWithConnection:(MVChatConnection *)connection asAction:(BOOL)asAction inView:(id<JVChatViewController>)chatView
{
	NSAttributedString * stringToSend = self.stringToSend;
	if (stringToSend.length == 0) {
		return;
	}
	
	if (![self confirmSendingLargeMessage:stringToSend.string]) {
		return;
	}
	
	[self.history addToHistory:stringToSend];
	{
		NSDictionary * typingAttributes = _sendTextView.typingAttributes;
		
		self.stringToSend = nil;
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"JVChatInputRetainsFormatting"]) {
			_sendTextView.typingAttributes = typingAttributes;
		}
	}
	
	
	// NOTE: it's really not clear to me when we should send directly to the connection or not.
	// JVChatConsolePanel always did, so it continues to do so.
	// JVDirectChatPanel did for commands, but then /me didn't work because the _sendCommand:withArguments:withEncoding:toTarget: in MVIRCChatConnection which was called, had a nil target which meant the command didn't work right.
	// For now JVChatConsolePanel continues to send direct to the connection, and JVDirectChatPanel implements the delegate methods to send through the "target" to the connection.
	// There's probably a better way to do this once there's better understanding.
	
	
	NSArray<CQSendCommandAndArgs*> * commands = [CQSendStringCommandParser parseString:stringToSend asAction:asAction];
	for (CQSendCommandAndArgs * command in commands) {
		if (command.command) {
			if (![CQSendCommandAndArgs processUserCommand:command toConnection:connection inView:chatView]) {
				if (connection.isConnected) {
					
					if ([self.delegate respondsToSelector:@selector(sendView:sendCommand:withArguments:)]) {
						[self.delegate sendView:self sendCommand:command.command withArguments:command.arguments];
					} else {
						[connection sendCommand:command.command withArguments:command.arguments];
					}
				}
			}
		} else {
			
			if ([self.delegate respondsToSelector:@selector(sendView:sendMessage:asAction:)]) {
				[self.delegate sendView:self sendMessage:command.message asAction:command.isAction];
			} else {
				[connection sendCommand:command.message.string withArguments:command.arguments];
			}
		}
	}
}






- (BOOL)confirmSendingLargeMessage:(NSString *)stringToSend
{
	// ask if the user really wants to send a message with lots of newlines.
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"JVWarnOnLargeMessages"]) {
		return YES;
	}
	
	NSUInteger newlineCount = 0;
	NSUInteger messageLimit = 5;
	
	NSArray *lines = [stringToSend componentsSeparatedByString:@"\n"];
	
	for( NSString *line in lines ) {
		if( [line length] ) newlineCount++;
	}
	
	if ( [[[NSUserDefaults standardUserDefaults] objectForKey:@"JVWarnOnLargeMessageLimit"] unsignedIntValue] > 1 ) {
		messageLimit = [[[NSUserDefaults standardUserDefaults] objectForKey:@"JVWarnOnLargeMessageLimit"] unsignedIntValue];
	}
	
	if ( newlineCount > messageLimit ) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString( @"Multiple lines detected", "multiple lines detected alert dialog title")];
		[alert setInformativeText:[NSString stringWithFormat:NSLocalizedString( @"You are about to send a message with %d lines. Are you sure you want to do this?", "about to send a %d line message alert dialog message" ), newlineCount]];
		[alert addButtonWithTitle:NSLocalizedString( @"Send", "Send alert dialog button title" )];
		[alert addButtonWithTitle:NSLocalizedString( @"Cancel", "Cancel alert dialog button title" )];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		if ( [alert runModal] == NSAlertSecondButtonReturn ) {
			return NO;
		}
	}
	
	return YES;
}


@end


