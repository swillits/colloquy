//
//  CQStreamlinedRoomSelectorView.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/5/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQStreamlinedRoomSelectorView.h"
#import "JVChatWindowController.h"
#import "JVChatRoomPanel.h"
#import "CQChatRoomMembersPopover.h"


@interface CQStreamlinedRoomSelectorView () <NSPopoverDelegate>
@property (readwrite, strong, nonatomic) JVChatWindowController * chatWindowController;
@end


@implementation CQStreamlinedRoomSelectorView
{
	NSUInteger _highlightedIndex;
	NSMutableDictionary * _tooltips;
	CQChatRoomMembersPopover * _popover;
	NSTimer * _mouseDownTimer;
}


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self sharedInit];
	}
	return self;
}



- (instancetype)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
		[self sharedInit];
	}
	return self;
}


- (void)sharedInit
{
	_highlightedIndex = NSNotFound;
	_tooltips = [[NSMutableDictionary alloc] init];
	
	_popover = [[CQChatRoomMembersPopover alloc] init];
	_popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
	_popover.animates = NO;
	_popover.behavior = NSPopoverBehaviorTransient;
	_popover.delegate = self;
}



- (void)popoverDidClose:(NSNotification *)notification
{
	_popover.contentViewController.room = nil;
}



- (void)viewDidMoveToWindow
{
	NSWindowController * wc = self.window.windowController;
	_highlightedIndex = NSNotFound;
	
	if ([wc isKindOfClass:[JVChatWindowController class]]) {
		self.chatWindowController = (JVChatWindowController *)wc;
	} else {
		self.chatWindowController = nil;
	}
}



- (void)setChatWindowController:(JVChatWindowController *)chatWindowController
{
	if (_chatWindowController) {
		[NSNotificationCenter.defaultCenter removeObserver:self name:JVChatWindowControllerChatViewsDidChangeNotificationName object:_chatWindowController];
		
		[NSNotificationCenter.defaultCenter removeObserver:self name:JVChatViewControllerInfoDidChangeNotificationName object:nil];
	}
	
	_chatWindowController = chatWindowController;
	
	if (_chatWindowController) {
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(tile) name:JVChatWindowControllerChatViewsDidChangeNotificationName object:_chatWindowController];
		
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(chatRoomInfoDidChange:) name:JVChatViewControllerInfoDidChangeNotificationName object:nil];
	}
	
	[self tile];
}



- (void)chatRoomInfoDidChange:(NSNotification *)note
{
	id<JVChatViewController> vc = note.object;
	if ([self.chatWindowController.allChatViewControllers containsObject:vc]) {
		[self setNeedsDisplay:YES];
	}
}






#define CHAT_WIDTH ((CGFloat)40.0)
#define CHAT_HEIGHT ((CGFloat)32.0)
#define ICON_SIZE ((CGFloat)24.0)
#define VIEW_HEIGHT 32.0
#define RECT_FOR_CHAT_AT_INDEX(index)   CGRectMake((CGFloat)(index) * CHAT_WIDTH, 0, CHAT_WIDTH, CHAT_HEIGHT) 



- (void)tile
{
	[self setNeedsDisplay:YES];
	[self setFrameSize:self.intrinsicContentSize];
	[self invalidateIntrinsicContentSize];
	
	
	[self removeAllToolTips];
	[_tooltips removeAllObjects];
	
	[self.chatWindowController.allChatViewControllers enumerateObjectsUsingBlock:^(id<JVChatViewController>  _Nonnull chat, NSUInteger idx, BOOL * _Nonnull stop) {
		NSRect rect = RECT_FOR_CHAT_AT_INDEX(idx);
		
		NSToolTipTag tag = [self addToolTipRect:rect owner:self userData:nil];
		[_tooltips setObject:@"" forKey:@(tag)];
	}];
}



- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data
{
	return [_tooltips objectForKey:@(tag)] ?: @"";
}



- (NSSize)intrinsicContentSize
{
	if (self.chatWindowController.allChatViewControllers.count == 0) {
		return NSMakeSize(0, VIEW_HEIGHT);
	}
	
	NSRect rect = RECT_FOR_CHAT_AT_INDEX(self.chatWindowController.allChatViewControllers.count - 1);
	return NSMakeSize(NSMaxX(rect), VIEW_HEIGHT);
}






#pragma mark -
#pragma mark Mouse

- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}


- (void)mouseDown:(NSEvent *)event
{
	NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
	
	_highlightedIndex = NSNotFound;
	
	[self.chatWindowController.allChatViewControllers enumerateObjectsUsingBlock:^(id<JVChatViewController>  _Nonnull chat, NSUInteger idx, BOOL * _Nonnull stop) {
		NSRect rect = RECT_FOR_CHAT_AT_INDEX(idx);
		
		if (NSPointInRect(point, rect)) {
			_highlightedIndex = idx;
			
			if ([chat isKindOfClass:[JVChatRoomPanel class]]) {
				_mouseDownTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:NO block:^(NSTimer * _Nonnull timer) {
					_popover.contentViewController.room = (JVChatRoomPanel *)chat;
					_popover.contentSize = _popover.contentViewController.fittingSize;
					[_popover showRelativeToRect:rect ofView:self preferredEdge:NSMinYEdge];
					_mouseDownTimer = nil;
				}];
			}
			
			*stop = YES;
		}
	}];
	
	[self setNeedsDisplay:YES];
}


- (void)mouseDragged:(NSEvent *)event
{
	NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
	
	[_mouseDownTimer invalidate];
	_mouseDownTimer = nil;
	
	_highlightedIndex = NSNotFound;
	
	[self.chatWindowController.allChatViewControllers enumerateObjectsUsingBlock:^(id<JVChatViewController>  _Nonnull chat, NSUInteger idx, BOOL * _Nonnull stop) {
		NSRect rect = RECT_FOR_CHAT_AT_INDEX(idx);
		
		if (NSPointInRect(point, rect)) {
			_highlightedIndex = idx;
			*stop = YES;
		}
	}];
	
	[self setNeedsDisplay:YES];
}


- (void)mouseUp:(NSEvent *)event
{
	NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
	
	[self.chatWindowController.allChatViewControllers enumerateObjectsUsingBlock:^(id<JVChatViewController>  _Nonnull chat, NSUInteger idx, BOOL * _Nonnull stop) {
		NSRect rect = RECT_FOR_CHAT_AT_INDEX(idx);
		if (NSPointInRect(point, rect)) {
			[self.chatWindowController showChatViewController:chat];
			*stop = YES;
		}
	}];
	
	
	[_mouseDownTimer invalidate];
	_mouseDownTimer = nil;
	
	_highlightedIndex = NSNotFound;
	[self setNeedsDisplay:YES];
}



- (void)mouseMoved:(NSEvent *)event
{
	
}







#pragma mark -
#pragma mark Drawing

- (BOOL)isOpaque
{
	return NO;
}


- (void)drawRect:(NSRect)dirtyRect
{
	[self.chatWindowController.allChatViewControllers enumerateObjectsUsingBlock:^(id<JVChatViewController>  _Nonnull chat, NSUInteger idx, BOOL * _Nonnull stop) {
		
		NSRect chatRect = RECT_FOR_CHAT_AT_INDEX(idx);
		NSRect iconRect = NSMakeRect(NSMinX(chatRect) + (CHAT_WIDTH - ICON_SIZE) / 2.0, (CHAT_HEIGHT - ICON_SIZE) / 2.0, ICON_SIZE, ICON_SIZE);
		
		if (self.chatWindowController.activeChatViewController == chat) {
			NSGradient * g = [[NSGradient alloc] initWithColors:@[
				[NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.0],
				[NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.15],
				[NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.0],
			]];
			[g drawInRect:chatRect angle:90];
			
			[[NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.1] set];
			NSRectFillUsingOperation(NSMakeRect(NSMinX(chatRect), 0, 1, VIEW_HEIGHT), NSCompositeSourceOver);
			NSRectFillUsingOperation(NSMakeRect(NSMaxX(chatRect) - 1, 0, 1, VIEW_HEIGHT), NSCompositeSourceOver);
			
		}
		
		
		NSImage * icon = chat.icon;
		
		if (_highlightedIndex == idx) {
			icon = [NSImage imageWithSize:icon.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
				[icon drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
				[[NSColor colorWithRed:0 green:0 blue:0 alpha:0.25] set];
				NSRectFillUsingOperation(dstRect, NSCompositeSourceAtop);
				return YES;
			}];
		}
		
		[icon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
		
		if ([chat conformsToProtocol:@protocol(JVCanHaveNewMessages)]) {
			id<JVCanHaveNewMessages> msgHolder = (id)chat;
			NSColor * badgeColor = nil;
			
			if (msgHolder.newHighlightMessagesWaiting) {
				badgeColor = [NSColor colorWithSRGBRed:1.0 green:0 blue:0 alpha:1.0];
				
			} else if (msgHolder.newMessagesWaiting) {
				badgeColor = [NSColor colorWithSRGBRed:0.0 green:0 blue:1.0 alpha:1.0];
			}
			
			if (badgeColor) {
				[badgeColor set];
				[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(NSMaxX(iconRect) - 3.5, NSMaxY(iconRect) - 3.5, 7, 7)] fill];
			}
		}
		
		
		if ([chat isKindOfClass:[JVChatRoomPanel class]]) {
			NSBezierPath * path = [NSBezierPath bezierPath];
			
			[path moveToPoint:NSMakePoint( NSMaxX(chatRect) - 8, NSMidY(chatRect) - 3)];
			[path relativeLineToPoint:NSMakePoint( 4, 0 )];
			[path relativeLineToPoint:NSMakePoint( -2, -3 )];
			
			[path closePath];
			[[NSColor colorWithWhite:0.0 alpha:0.5] set];
			[path fill];
		}
		
	}];
}

@end
