//
//  CQChatRoomMembersPopover.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/5/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQChatRoomMembersPopover.h"
#import "JVChatRoomPanel.h"
#import "JVChatRoomMember.h"


@interface CQChatRoomMembersPopoverViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (readwrite, weak) NSPopover * popover;
@end


@implementation CQChatRoomMembersPopover
@dynamic contentViewController;

- (instancetype)init
{
	if ((self = [super init])) {
		self.contentViewController = [[CQChatRoomMembersPopoverViewController alloc] init];
		self.contentViewController.popover = self;
	}
	return self;
}

@end








@implementation CQChatRoomMembersPopoverViewController
{
	IBOutlet NSTableView * __weak membersTableView;
}

- (NSString *)nibName
{
	return @"CQChatRoomMembersPopover";
}


- (void)loadView
{
	[super loadView];
	membersTableView.target = self;
	membersTableView.doubleAction = @selector(doubleClicked:);
}



- (void)setRoom:(JVChatRoomPanel *)room
{
	_room = room;
	[self view];
	[membersTableView reloadData];
}


- (NSSize)fittingSize
{
	[self view];
	
	NSSize size;
	size.width = 160;
	size.height = 12 + membersTableView.rowHeight * membersTableView.numberOfRows;
	
	if (membersTableView.numberOfRows > 0) {
		size.height += (membersTableView.numberOfRows - 1) * membersTableView.intercellSpacing.height;
	}
	
	size.height = MIN(size.height, 400);
	
	return size;
}




- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return self.room.numberOfChildren;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView * cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:nil];
	JVChatRoomMember * member = [self.room childAtIndex:row];
	
	cell.textField.stringValue = member.nickname;
	cell.imageView.image = member.icon;
	
	return cell;
}



- (void)doubleClicked:(NSTableView *)tableView
{
	NSInteger row = membersTableView.clickedRow;
	if (row == -1) {
		return;
	}
	
	JVChatRoomMember * member = [self.room childAtIndex:(NSUInteger)row];
	[member doubleClicked:nil];
	[self.popover close];
}



- (nullable NSMenu *)menuForEvent:(NSEvent *)event
{
	NSPoint point = [membersTableView convertPoint:event.locationInWindow fromView:nil];
	NSInteger row = [membersTableView rowAtPoint:point];
	if (row == -1) {
		return nil;
	}
	
	JVChatRoomMember * member = [self.room childAtIndex:(NSUInteger)row];
	return member.menu;
}



@end



@interface CQChatRoomMembersPopoverScrollView : NSScrollView
@end

@interface CQChatRoomMembersPopoverTableView : NSTableView
@end

@implementation CQChatRoomMembersPopoverScrollView
- (BOOL)isOpaque
{
	return NO;
}
@end

@implementation CQChatRoomMembersPopoverTableView
- (BOOL)isOpaque
{
	return NO;
}

- (nullable NSMenu *)menuForEvent:(NSEvent *)event
{
	return [(NSView *)self.delegate menuForEvent:event];
}
@end

