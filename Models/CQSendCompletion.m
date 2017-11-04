//
//  CQSendCompletion.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQSendCompletion.h"

@implementation CQSendCompletion

/*
 was in context of JVDirectChatPanel
 
- (NSArray *) textView:(NSTextView *) textView stringCompletionsForPrefix:(NSString *) prefix {
	NSMutableArray *possibleCompletion = [NSMutableArray array];
	
	if( [[self title] rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch )].location == 0 )
		[possibleCompletion addObject:[self title]];
	if( [[[self connection] nickname] rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch )].location == 0 )
		[possibleCompletion addObject:[[self connection] nickname] ?: @""];
	
	static NSArray *commands;
	if (!commands) commands = [[NSArray alloc] initWithObjects:@"/me ", @"/msg ", @"/nick ", @"/away ", @"/say ", @"/raw ", @"/quote ", @"/join ", @"/quit ", @"/disconnect ", @"/query ", @"/umode ", @"/google ", @"/part ", nil];
	
	for( NSString *name in commands )
		if ([name hasCaseInsensitivePrefix:prefix])
			[possibleCompletion addObject:name];
	
	for ( MVChatRoom* room in self.connection.knownChatRooms )
	{
		if ( [room.uniqueIdentifier hasCaseInsensitivePrefix:prefix] )
			[possibleCompletion addObject:room.uniqueIdentifier];
		if ( [room.displayName hasCaseInsensitivePrefix:prefix] )
			[possibleCompletion addObject:room.displayName];
	}
	
	return possibleCompletion;
}

- (NSArray *) textView:(NSTextView *) textView completions:(NSArray *) words forPartialWordRange:(NSRange) charRange indexOfSelectedItem:(NSInteger *) index {
	NSEvent *event = [[NSApplication sharedApplication] currentEvent];
	NSString *search = [[[send textStorage] string] substringWithRange:charRange];
	NSMutableArray *ret = [NSMutableArray array];
	NSString *suffix = ( ! ( [event modifierFlags] & NSAlternateKeyMask ) ? ( charRange.location == 0 ? @": " : @" " ) : @"" );
	NSString *comparison = [[[self user] nickname] substringToIndex:[search length]];
	
	if( [search length] <= [[self title] length] && comparison && [search caseInsensitiveCompare:comparison] == NSOrderedSame )
		[ret addObject:[[self title] stringByAppendingString:suffix] ?: @""];
	comparison = [[[self connection] nickname] substringToIndex:[search length]];
	if( [search length] <= [[[self connection] nickname] length] && comparison && [search caseInsensitiveCompare:comparison] == NSOrderedSame )
		[ret addObject:[[[self connection] nickname] stringByAppendingString:suffix] ?: @""];
	
	unichar chr = 0;
	if( [[event charactersIgnoringModifiers] length] )
		chr = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
	if( chr != NSTabCharacter ) [ret addObjectsFromArray:words];
	return ret;
}
*/

/*

#pragma mark -
#pragma mark TextView/Input Support

// TODO-SW
- (NSArray *) textView:(NSTextView *) textView stringCompletionsForPrefix:(NSString *) prefix {
	NSMutableArray *possibleCompletion = [NSMutableArray array];
	
	if( [prefix isEqualToString:@""] ) {
		if( [_preferredTabCompleteNicknames count] )
			[possibleCompletion addObject:[_preferredTabCompleteNicknames objectAtIndex:0]];
		return possibleCompletion;
	}
	
	for( NSString *name in _preferredTabCompleteNicknames )
		if( [name rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch )].location == NSOrderedSame )
			[possibleCompletion addObject:name];
	
	for( JVChatRoomMember *member in _sortedMembers ) {
		NSString *name = [member nickname];
		if( ! [possibleCompletion containsObject:name] && [name rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch )].location == NSOrderedSame )
			[possibleCompletion addObject:name];
	}
	
	static NSArray *commands;
	if (!commands) commands = [[NSArray alloc] initWithObjects:@"/topic ", @"/kick ", @"/ban ", @"/kickban ", @"/op ", @"/voice ", @"/halfop ", @"/quiet ", @"/deop ", @"/devoice ", @"/dehalfop ", @"/dequiet ", @"/unban ", @"/bankick ", @"/cycle ", @"/hop ", @"/me ", @"/msg ", @"/nick ", @"/away ", @"/say ", @"/raw ", @"/quote ", @"/join ", @"/quit ", @"/disconnect ", @"/query ", @"/umode ", @"/globops ", @"/google ", @"/part ", nil];
	
	for( NSString *name in commands )
		if ([name hasCaseInsensitivePrefix:prefix])
			[possibleCompletion addObject:name];
	
	for ( MVChatRoom* room in self.connection.knownChatRooms )
	{
		if ( [room.uniqueIdentifier hasCaseInsensitivePrefix:prefix] )
			[possibleCompletion addObject:room.uniqueIdentifier];
		if ( [room.displayName hasCaseInsensitivePrefix:prefix] )
			[possibleCompletion addObject:room.displayName];
	}
	
	return possibleCompletion;
}



// TODO-SW
- (void) textView:(NSTextView *) textView selectedCompletion:(NSString *) completion fromPrefix:(NSString *) prefix {
	if( [completion isEqualToString:[[[self connection] localUser] nickname]] ) return;
	[_preferredTabCompleteNicknames removeObject:completion];
	[_preferredTabCompleteNicknames insertObject:completion atIndex:0];
}


// TODO-SW
- (NSArray *) textView:(NSTextView *) textView completions:(NSArray *) words forPartialWordRange:(NSRange) charRange indexOfSelectedItem:(NSInteger *) index {
	NSEvent *event = [[NSApplication sharedApplication] currentEvent];
	NSString *search = [sendView.stringToSend.string substringWithRange:charRange];
	NSMutableArray *ret = [NSMutableArray array];
	NSString *suffix = ( ! ( [event modifierFlags] & NSAlternateKeyMask ) ? ( charRange.location == 0 ? @": " : @" " ) : @"" );
	NSUInteger length = [search length];
	
	for( JVChatRoomMember *member in _sortedMembers ) {
		if (!length) break;
		
		NSString *name = [member nickname];
		
		if( length <= [name length] && [search caseInsensitiveCompare:[name substringToIndex:length]] == NSOrderedSame )
			[ret addObject:[name stringByAppendingString:suffix]];
	}
	
	unichar chr = 0;
	if( [[event charactersIgnoringModifiers] length] )
		chr = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
	if( chr != NSTabCharacter ) [ret addObjectsFromArray:words];
	return ret;
}
*/

@end
