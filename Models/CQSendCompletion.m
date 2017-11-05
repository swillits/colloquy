//
//  CQSendCompletion.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQSendCompletion.h"
#import "JVDirectChatPanel.h"
#import "JVChatRoomPanel.h"
#import "JVChatRoomMember.h"



static NSArray * ChatRoomCommands = nil;
static NSArray * DirectChatCommands = nil;
static dispatch_once_t CommandsInit;



@implementation CQChatSendCompletionHandler
{
	JVDirectChatPanel * __weak _chatPanel;
	NSMutableArray *_preferredTabCompleteNicknames;
}

- (instancetype)initWithChat:(JVDirectChatPanel *)directChatPanel
{
	if (!(self = [super init])) {
		return nil;
	}
	
	_chatPanel = directChatPanel;
	_preferredTabCompleteNicknames = [[NSMutableArray alloc] initWithCapacity:10];
	
	dispatch_once(&CommandsInit, ^{
		ChatRoomCommands = @[@"/me ", @"/msg ", @"/nick ", @"/away ", @"/say ", @"/raw ", @"/quote ", @"/join ", @"/quit ", @"/disconnect ", @"/query ", @"/umode ", @"/google ", @"/part "];
		
		DirectChatCommands = @[@"/topic ", @"/kick ", @"/ban ", @"/kickban ", @"/op ", @"/voice ", @"/halfop ", @"/quiet ", @"/deop ", @"/devoice ", @"/dehalfop ", @"/dequiet ", @"/unban ", @"/bankick ", @"/cycle ", @"/hop ", @"/me ", @"/msg ", @"/nick ", @"/away ", @"/say ", @"/raw ", @"/quote ", @"/join ", @"/quit ", @"/disconnect ", @"/query ", @"/umode ", @"/globops ", @"/google ", @"/part "];
	});
	
	return self;
}



- (void)pushPreferredNickname:(NSString *)nickname
{
	[_preferredTabCompleteNicknames removeObject:nickname];
	[_preferredTabCompleteNicknames insertObject:nickname atIndex:0];
}



- (void)removeAllPreferredNicknames
{
	[_preferredTabCompleteNicknames removeAllObjects];
}


- (void)removePreferredNickname:(NSString *)nickname
{
	[_preferredTabCompleteNicknames removeObject:nickname];
}


- (void)replacePreferredNickname:(NSString *)oldNickname with:(NSString *)new
{
	NSUInteger index = [_preferredTabCompleteNicknames indexOfObject:oldNickname];
	if (index != NSNotFound) {
		[_preferredTabCompleteNicknames replaceObjectAtIndex:index withObject:new];
	}
}



- (NSArray *)textView:(NSTextView *)textView stringCompletionsForPrefix:(NSString *)prefix
{
	JVDirectChatPanel * chat = _chatPanel;
	JVChatRoomPanel * chatRoom = ([chat isKindOfClass:[JVChatRoomPanel class]] ? (JVChatRoomPanel *)chat : nil);
	if (!chat) {
		return nil;
	}
	
	NSString * title = chat.title;
	NSString * connectionNickname = chat.connection.nickname;
	NSMutableArray * possibleCompletion = [NSMutableArray array];
	
	
	
	if (chatRoom) {
		if ([prefix isEqualToString:@""]) {
			if( [_preferredTabCompleteNicknames count] ) {
				[possibleCompletion addObject:[_preferredTabCompleteNicknames objectAtIndex:0]];
			}
			return possibleCompletion;
		}
		
		for (NSString *name in _preferredTabCompleteNicknames) {
			if( [name rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch )].location == NSOrderedSame ) {
				[possibleCompletion addObject:name];
			}
		}
		
		for( JVChatRoomMember *member in chat.children) {
			NSString *name = [member nickname];
			if( ! [possibleCompletion containsObject:name] && [name rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch )].location == NSOrderedSame ) {
				[possibleCompletion addObject:name];
			}
		}
	}
	
	
	if (!chatRoom) {
		if ([title rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch )].location == 0 ) {
			[possibleCompletion addObject:title];
		}
		if ([connectionNickname rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch )].location == 0 ) {
			[possibleCompletion addObject:connectionNickname ?: @""];
		}
	}
	
	
	NSArray * commands = nil;
	if (chatRoom) {
		commands = ChatRoomCommands;
	} else {
		commands = DirectChatCommands;
	}
	
	for (NSString * name in commands) {
		if ([name hasCaseInsensitivePrefix:prefix]) {
			[possibleCompletion addObject:name];
		}
	}
	
	
	for (MVChatRoom * room in chat.connection.knownChatRooms) {
		if ([room.uniqueIdentifier hasCaseInsensitivePrefix:prefix]) {
			[possibleCompletion addObject:room.uniqueIdentifier];
		}
		
		if ([room.displayName hasCaseInsensitivePrefix:prefix]) {
			[possibleCompletion addObject:room.displayName];
		}
	}
	
	return possibleCompletion;
}



- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	JVDirectChatPanel * chat = _chatPanel;
	JVChatRoomPanel * chatRoom = ([chat isKindOfClass:[JVChatRoomPanel class]] ? (JVChatRoomPanel *)chat : nil);
	if (!chat) {
		return nil;
	}
	
	NSEvent * event = [[NSApplication sharedApplication] currentEvent];
	NSString * search = [textView.string substringWithRange:charRange];
	NSMutableArray * suggestions = [NSMutableArray array];
	NSString * suffix = ( ! ( [event modifierFlags] & NSAlternateKeyMask ) ? ( charRange.location == 0 ? @": " : @" " ) : @"" );
	NSUInteger length = [search length];
	
	
	// Compare to people in the room
	if (chatRoom) {
		if (length > 0) {
			for (JVChatRoomMember *member in chatRoom.children) {
				NSString *name = [member nickname];
				if( length <= [name length] && [search caseInsensitiveCompare:[name substringToIndex:length]] == NSOrderedSame ) {
					[suggestions addObject:[name stringByAppendingString:suffix]];
				}
			}
		}
	}
	
	// Compare to chat properties
	if (!chatRoom) {
		NSArray * compareTo = @[
			chat.title ?: @"",
			chat.connection.nickname ?: @"",
			chat.user.nickname ?: @""
		];
		
		for (NSString * property in compareTo) {
			if (property.length >= search.length) {
				if ([[property substringToIndex:search.length] caseInsensitiveCompare:search] == NSOrderedSame) {
					[suggestions addObject:[property stringByAppendingString:suffix]];
				}
			}
		}
	}
	
	
	// ??
	{
		unichar chr = 0;
		if (event.charactersIgnoringModifiers.length) {
			chr = [event.charactersIgnoringModifiers characterAtIndex:0];
		}
		
		if (chr != NSTabCharacter) {
			[suggestions addObjectsFromArray:words];
		}
	}
	
	
	
	return suggestions;
}


- (void)textView:(NSTextView *)textView selectedCompletion:(NSString *)completion fromPrefix:(NSString *)prefix
{
	JVDirectChatPanel * chat = _chatPanel;
	JVChatRoomPanel * chatRoom = ([chat isKindOfClass:[JVChatRoomPanel class]] ? (JVChatRoomPanel *)chat : nil);
	if (!chat) {
		return;
	}
	
	if (chatRoom) {
		NSString * nickname = chat.connection.localUser.nickname;
		if (nickname && [completion isEqual:nickname]) {
			return;
		}
		
		[_preferredTabCompleteNicknames removeObject:completion];
		[_preferredTabCompleteNicknames insertObject:completion atIndex:0];
	}
}



@end


