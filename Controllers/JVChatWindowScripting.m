//
//  JVChatWindowScripting.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/5/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "JVChatWindowScripting.h"
#import "JVChatRoomPanel.h"
#import "JVClassicChatWindowController.h"
#import "JVSmartTranscriptPanel.h"
#import "JVChatConsolePanel.h"
#import "JVChatRoomMember.h"


@implementation NSWindow (JVChatWindowControllerScripting)
- (id <JVChatViewController>) activeChatViewController {
	if( ! [[self windowController] isKindOfClass:[JVChatWindowController class]] ) return nil;
	return [[self windowController] activeChatViewController];
}

- (id <JVChatListItem>) selectedListItem {
	if( ! [[self windowController] isKindOfClass:[JVClassicChatWindowController class]] ) return nil;
	return [(JVClassicChatWindowController *)[self windowController] selectedListItem];
}

#pragma mark -

- (NSArray *) chatViews {
	if( ! [[self windowController] isKindOfClass:[JVChatWindowController class]] ) return nil;
	return [(JVChatWindowController *)[self windowController] allChatViewControllers];
}

- (id <JVChatViewController>) valueInChatViewsAtIndex:(NSUInteger) index {
	return [[self chatViews] objectAtIndex:index];
}

- (id <JVChatViewController>) valueInChatViewsWithUniqueID:(id) identifier {
	for( id <JVChatViewController, JVChatListItemScripting> view in [self chatViews] )
		if( [[view uniqueIdentifier] isEqual:identifier] )
			return view;
	
	return nil;
}

- (id <JVChatViewController>) valueInChatViewsWithName:(NSString *) name {
	for( id <JVChatViewController, JVChatListItemScripting> view in [self chatViews] )
		if( [[view title] isEqualToString:name] )
			return view;
	
	return nil;
}

- (void) addInChatViews:(id <JVChatViewController>) view {
	if( ! [[self windowController] isKindOfClass:[JVChatWindowController class]] ) return;
	[[self windowController] addChatViewController:view];
}

- (void) insertInChatViews:(id <JVChatViewController>) view {
	if( ! [[self windowController] isKindOfClass:[JVChatWindowController class]] ) return;
	[[self windowController] addChatViewController:view];
}

- (void) insertInChatViews:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	if( ! [[self windowController] isKindOfClass:[JVChatWindowController class]] ) return;
	[[self windowController] insertChatViewController:view atIndex:index];
}

- (void) removeFromViewsAtIndex:(NSUInteger) index {
	if( ! [[self windowController] isKindOfClass:[JVChatWindowController class]] ) return;
	[[self windowController] removeChatViewControllerAtIndex:index];
}

- (void) replaceInChatViews:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	if( ! [[self windowController] isKindOfClass:[JVChatWindowController class]] ) return;
	[[self windowController] replaceChatViewControllerAtIndex:index withController:view];
}

#pragma mark -

- (NSArray *) chatViewsWithClass:(Class) class {
	NSMutableArray *ret = [NSMutableArray array];
	
	for( id <JVChatViewController> item in [self chatViews] )
		if( [item isMemberOfClass:class] )
			[ret addObject:item];
	
	return ret;
}

- (id <JVChatViewController>) valueInChatViewsAtIndex:(NSUInteger) index withClass:(Class) class {
	return [[self chatViewsWithClass:class] objectAtIndex:index];
}

- (id <JVChatViewController>) valueInChatViewsWithUniqueID:(id) identifier andClass:(Class) class {
	return [self valueInChatViewsWithUniqueID:identifier];
}

- (id <JVChatViewController>) valueInChatViewsWithName:(NSString *) name andClass:(Class) class {
	for( id <JVChatViewController> view in [self chatViewsWithClass:class] )
		if( [[view title] isEqualToString:name] )
			return view;
	
	return nil;
}

- (void) addInChatViews:(id <JVChatViewController>) view withClass:(Class) class {
	NSUInteger index = [[self chatViews] indexOfObject:[[self chatViewsWithClass:class] lastObject]];
	[self insertInChatViews:view atIndex:( index + 1 )];
}

- (void) insertInChatViews:(id <JVChatViewController>) view atIndex:(NSUInteger) index withClass:(Class) class {
	if( index == [[self chatViewsWithClass:class] count] ) {
		[self addInChatViews:view withClass:class];
	} else {
		NSUInteger indx = [[self chatViews] indexOfObject:[[self chatViewsWithClass:class] objectAtIndex:index]];
		[self insertInChatViews:view atIndex:indx];
	}
}

- (void) removeFromChatViewsAtIndex:(NSUInteger) index withClass:(Class) class {
	NSUInteger indx = [[self chatViews] indexOfObject:[[self chatViewsWithClass:class] objectAtIndex:index]];
	[self removeFromViewsAtIndex:indx];
}

- (void) replaceInChatViews:(id <JVChatViewController>) view atIndex:(NSUInteger) index withClass:(Class) class {
	NSUInteger indx = [[self chatViews] indexOfObject:[[self chatViewsWithClass:class] objectAtIndex:index]];
	[self replaceInChatViews:view atIndex:indx];
}

#pragma mark -

- (NSArray *) chatRooms {
	return [self chatViewsWithClass:[JVChatRoomPanel class]];
}

- (id <JVChatViewController>) valueInChatRoomsAtIndex:(NSUInteger) index {
	return [self valueInChatViewsAtIndex:index withClass:[JVChatRoomPanel class]];
}

- (id <JVChatViewController>) valueInChatRoomsWithUniqueID:(id) identifier {
	return [self valueInChatViewsWithUniqueID:identifier andClass:[JVChatRoomPanel class]];
}

- (id <JVChatViewController>) valueInChatRoomsWithName:(NSString *) name {
	return [self valueInChatViewsWithName:name andClass:[JVChatRoomPanel class]];
}

- (void) addInChatRooms:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVChatRoomPanel class]];
}

- (void) insertInChatRooms:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVChatRoomPanel class]];
}

- (void) insertInChatRooms:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self insertInChatViews:view atIndex:index withClass:[JVChatRoomPanel class]];
}

- (void) removeFromChatRoomsAtIndex:(NSUInteger) index {
	[self removeFromChatViewsAtIndex:index withClass:[JVChatRoomPanel class]];
}

- (void) replaceInChatRooms:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self replaceInChatViews:view atIndex:index withClass:[JVChatRoomPanel class]];
}

#pragma mark -

- (NSArray *) directChats {
	return [self chatViewsWithClass:[JVDirectChatPanel class]];
}

- (id <JVChatViewController>) valueInDirectChatsAtIndex:(NSUInteger) index {
	return [self valueInChatViewsAtIndex:index withClass:[JVDirectChatPanel class]];
}

- (id <JVChatViewController>) valueInDirectChatsWithUniqueID:(id) identifier {
	return [self valueInChatViewsWithUniqueID:identifier andClass:[JVDirectChatPanel class]];
}

- (id <JVChatViewController>) valueInDirectChatsWithName:(NSString *) name {
	return [self valueInChatViewsWithName:name andClass:[JVDirectChatPanel class]];
}

- (void) addInDirectChats:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVDirectChatPanel class]];
}

- (void) insertInDirectChats:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVDirectChatPanel class]];
}

- (void) insertInDirectChats:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self insertInChatViews:view atIndex:index withClass:[JVDirectChatPanel class]];
}

- (void) removeFromDirectChatsAtIndex:(NSUInteger) index {
	[self removeFromChatViewsAtIndex:index withClass:[JVDirectChatPanel class]];
}

- (void) replaceInDirectChats:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self replaceInChatViews:view atIndex:index withClass:[JVDirectChatPanel class]];
}

#pragma mark -

- (NSArray *) chatTranscripts {
	return [self chatViewsWithClass:[JVChatTranscriptPanel class]];
}

- (id <JVChatViewController>) valueInChatTranscriptsAtIndex:(NSUInteger) index {
	return [self valueInChatViewsAtIndex:index withClass:[JVChatTranscriptPanel class]];
}

- (id <JVChatViewController>) valueInChatTranscriptsWithUniqueID:(id) identifier {
	return [self valueInChatViewsWithUniqueID:identifier andClass:[JVChatTranscriptPanel class]];
}

- (id <JVChatViewController>) valueInChatTranscriptsWithName:(NSString *) name {
	return [self valueInChatViewsWithName:name andClass:[JVChatTranscriptPanel class]];
}

- (void) addInChatTranscripts:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVChatTranscriptPanel class]];
}

- (void) insertInChatTranscripts:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVChatTranscriptPanel class]];
}

- (void) insertInChatTranscripts:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self insertInChatViews:view atIndex:index withClass:[JVChatTranscriptPanel class]];
}

- (void) removeFromChatTranscriptsAtIndex:(NSUInteger) index {
	[self removeFromChatViewsAtIndex:index withClass:[JVChatTranscriptPanel class]];
}

- (void) replaceInChatTranscripts:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self replaceInChatViews:view atIndex:index withClass:[JVChatTranscriptPanel class]];
}

#pragma mark -

- (NSArray *) smartTranscripts {
	return [self chatViewsWithClass:[JVSmartTranscriptPanel class]];
}

- (id <JVChatViewController>) valueInSmartTranscriptsAtIndex:(NSUInteger) index {
	return [self valueInChatViewsAtIndex:index withClass:[JVSmartTranscriptPanel class]];
}

- (id <JVChatViewController>) valueInSmartTranscriptsWithUniqueID:(id) identifier {
	return [self valueInChatViewsWithUniqueID:identifier andClass:[JVSmartTranscriptPanel class]];
}

- (id <JVChatViewController>) valueInSmartTranscriptsWithName:(NSString *) name {
	return [self valueInChatViewsWithName:name andClass:[JVSmartTranscriptPanel class]];
}

- (void) addInSmartTranscripts:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVSmartTranscriptPanel class]];
}

- (void) insertInSmartTranscripts:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVSmartTranscriptPanel class]];
}

- (void) insertInSmartTranscripts:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self insertInChatViews:view atIndex:index withClass:[JVSmartTranscriptPanel class]];
}

- (void) removeFromSmartTranscriptsAtIndex:(NSUInteger) index {
	[self removeFromChatViewsAtIndex:index withClass:[JVSmartTranscriptPanel class]];
}

- (void) replaceInSmartTranscripts:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self replaceInChatViews:view atIndex:index withClass:[JVSmartTranscriptPanel class]];
}

#pragma mark -

- (NSArray *) chatConsoles {
	return [self chatViewsWithClass:[JVChatConsolePanel class]];
}

- (id <JVChatViewController>) valueInChatConsolesAtIndex:(NSUInteger) index {
	return [self valueInChatViewsAtIndex:index withClass:[JVChatConsolePanel class]];
}

- (id <JVChatViewController>) valueInChatConsolesWithUniqueID:(id) identifier {
	return [self valueInChatViewsWithUniqueID:identifier andClass:[JVChatConsolePanel class]];
}

- (id <JVChatViewController>) valueInChatConsolesWithName:(NSString *) name {
	return [self valueInChatViewsWithName:name andClass:[JVChatConsolePanel class]];
}

- (void) addInChatConsoles:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVChatConsolePanel class]];
}

- (void) insertInChatConsoles:(id <JVChatViewController>) view {
	[self addInChatViews:view withClass:[JVChatConsolePanel class]];
}

- (void) insertInChatConsoles:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self insertInChatViews:view atIndex:index withClass:[JVChatConsolePanel class]];
}

- (void) removeFromChatConsolesAtIndex:(NSUInteger) index {
	[self removeFromChatViewsAtIndex:index withClass:[JVChatConsolePanel class]];
}

- (void) replaceInChatConsoles:(id <JVChatViewController>) view atIndex:(NSUInteger) index {
	[self replaceInChatViews:view atIndex:index withClass:[JVChatConsolePanel class]];
}

#pragma mark -

- (NSArray *) indicesOfObjectsByEvaluatingRangeSpecifier:(NSRangeSpecifier *) specifier {
	NSString *key = [specifier key];
	
	if( [key isEqualToString:@"chatViews"] || [key isEqualToString:@"chatRooms"] || [key isEqualToString:@"directChats"] || [key isEqualToString:@"chatConsoles"] || [key isEqualToString:@"chatTranscripts"] ) {
		NSScriptObjectSpecifier *startSpec = [specifier startSpecifier];
		NSScriptObjectSpecifier *endSpec = [specifier endSpecifier];
		NSString *startKey = [startSpec key];
		NSString *endKey = [endSpec key];
		NSArray *chatViews = [self chatViews];
		
		if( ! startSpec && ! endSpec ) return nil;
		
		if( ! [chatViews count] ) [NSArray array];
		
		if( ( ! startSpec || [startKey isEqualToString:@"chatViews"] || [startKey isEqualToString:@"chatRooms"] || [startKey isEqualToString:@"directChats"] || [startKey isEqualToString:@"chatConsoles"] || [startKey isEqualToString:@"chatTranscripts"] ) && ( ! endSpec || [endKey isEqualToString:@"chatViews"] || [endKey isEqualToString:@"chatRooms"] || [endKey isEqualToString:@"directChats"] || [endKey isEqualToString:@"chatConsoles"] || [endKey isEqualToString:@"chatTranscripts"] ) ) {
			NSUInteger startIndex = 0;
			NSUInteger endIndex = 0;
			
			// The strategy here is going to be to find the index of the start and stop object in the full graphics array, regardless of what its key is.  Then we can find what we're looking for in that range of the graphics key (weeding out objects we don't want, if necessary).
			// First find the index of the first start object in the graphics array
			if( startSpec ) {
				id startObject = [startSpec objectsByEvaluatingSpecifier];
				if( [startObject isKindOfClass:[NSArray class]] ) {
					if( ! [(NSArray *)startObject count] ) startObject = nil;
					else startObject = [startObject objectAtIndex:0];
				}
				if( ! startObject ) return nil;
				startIndex = [chatViews indexOfObjectIdenticalTo:startObject];
				if( startIndex == NSNotFound ) return nil;
			}
			
			// Now find the index of the last end object in the graphics array
			if( endSpec ) {
				id endObject = [endSpec objectsByEvaluatingSpecifier];
				if( [endObject isKindOfClass:[NSArray class]] ) {
					if( ! [(NSArray *)endObject count] ) endObject = nil;
					else endObject = [endObject lastObject];
				}
				if( ! endObject ) return nil;
				endIndex = [chatViews indexOfObjectIdenticalTo:endObject];
				if( endIndex == NSNotFound ) return nil;
			} else endIndex = ( [chatViews count] - 1 );
			
			// Accept backwards ranges gracefully
			if( endIndex < startIndex ) {
				NSUInteger temp = endIndex;
				endIndex = startIndex;
				startIndex = temp;
			}
			
			// Now startIndex and endIndex specify the end points of the range we want within the main array.
			// We will traverse the range and pick the objects we want.
			// We do this by getting each object and seeing if it actually appears in the real key that we are trying to evaluate in.
			NSMutableArray *result = [NSMutableArray array];
			BOOL keyIsGeneric = [key isEqualToString:@"chatViews"];
			NSArray *rangeKeyObjects = ( keyIsGeneric ? nil : [self valueForKey:key] );
			NSUInteger curKeyIndex = 0;
			id obj = nil;
			
			for( NSUInteger i = startIndex; i <= endIndex; i++ ) {
				if( keyIsGeneric ) {
					[result addObject:[NSNumber numberWithUnsignedLong:i]];
				} else {
					obj = [chatViews objectAtIndex:i];
					curKeyIndex = [rangeKeyObjects indexOfObjectIdenticalTo:obj];
					if( curKeyIndex != NSNotFound )
						[result addObject:[NSNumber numberWithUnsignedLong:curKeyIndex]];
				}
			}
			
			return result;
		}
	}
	
	return nil;
}

- (NSArray *) indicesOfObjectsByEvaluatingRelativeSpecifier:(NSRelativeSpecifier *) specifier {
	NSString *key = [specifier key];
	
	if( [key isEqualToString:@"chatViews"] || [key isEqualToString:@"chatRooms"] || [key isEqualToString:@"directChats"] || [key isEqualToString:@"chatConsoles"] || [key isEqualToString:@"chatTranscripts"] ) {
		NSScriptObjectSpecifier *baseSpec = [specifier baseSpecifier];
		NSString *baseKey = [baseSpec key];
		NSArray *chatViews = [self chatViews];
		NSRelativePosition relPos = [specifier relativePosition];
		
		if( ! baseSpec ) return nil;
		
		if( ! [chatViews count] ) return [NSArray array];
		
		if( [baseKey isEqualToString:@"chatViews"] || [baseKey isEqualToString:@"chatRooms"] || [baseKey isEqualToString:@"directChats"] || [baseKey isEqualToString:@"chatConsoles"] || [baseKey isEqualToString:@"chatTranscripts"] ) {
			NSUInteger baseIndex = 0;
			
			// The strategy here is going to be to find the index of the base object in the full graphics array, regardless of what its key is.  Then we can find what we're looking for before or after it.
			// First find the index of the first or last base object in the master array
			// Base specifiers are to be evaluated within the same container as the relative specifier they are the base of. That's this container.
			
			id baseObject = [baseSpec objectsByEvaluatingWithContainers:self];
			if( [baseObject isKindOfClass:[NSArray class]] ) {
				NSUInteger baseCount = [(NSArray *)baseObject count];
				if( baseCount ) {
					if( relPos == NSRelativeBefore ) baseObject = [baseObject objectAtIndex:0];
					else baseObject = [baseObject objectAtIndex:( baseCount - 1 )];
				} else baseObject = nil;
			}
			
			if( ! baseObject ) return nil;
			
			baseIndex = [chatViews indexOfObjectIdenticalTo:baseObject];
			if( baseIndex == NSNotFound ) return nil;
			
			// Now baseIndex specifies the base object for the relative spec in the master array.
			// We will start either right before or right after and look for an object that matches the type we want.
			// We do this by getting each object and seeing if it actually appears in the real key that we are trying to evaluate in.
			NSMutableArray *result = [NSMutableArray array];
			BOOL keyIsGeneric = [key isEqualToString:@"chatViews"];
			NSArray *relKeyObjects = ( keyIsGeneric ? nil : [self valueForKey:key] );
			NSUInteger curKeyIndex = 0, viewCount = [chatViews count];
			id obj = nil;
			
			if( relPos == NSRelativeBefore ) baseIndex--;
			else baseIndex++;
			
			while( baseIndex < viewCount ) {
				if( keyIsGeneric ) {
					[result addObject:[NSNumber numberWithUnsignedLong:baseIndex]];
					break;
				} else {
					obj = [chatViews objectAtIndex:baseIndex];
					curKeyIndex = [relKeyObjects indexOfObjectIdenticalTo:obj];
					if( curKeyIndex != NSNotFound ) {
						[result addObject:[NSNumber numberWithUnsignedLong:curKeyIndex]];
						break;
					}
				}
				
				if( relPos == NSRelativeBefore ) baseIndex--;
				else baseIndex++;
			}
			
			return result;
		}
	}
	
	return nil;
}

- (NSArray *) indicesOfObjectsByEvaluatingObjectSpecifier:(NSScriptObjectSpecifier *) specifier {
	if( [specifier isKindOfClass:[NSRangeSpecifier class]] ) {
		return [self indicesOfObjectsByEvaluatingRangeSpecifier:(NSRangeSpecifier *) specifier];
	} else if( [specifier isKindOfClass:[NSRelativeSpecifier class]] ) {
		return [self indicesOfObjectsByEvaluatingRelativeSpecifier:(NSRelativeSpecifier *) specifier];
	}
	return nil;
}
@end

