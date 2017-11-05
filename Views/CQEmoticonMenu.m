//
//  CQEmoticonMenu.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQEmoticonMenu.h"
#import "JVEmoticonSet.h"


@implementation CQEmoticonMenu

- (instancetype)initWithTitle:(NSString *)title
{
	if (!(self = [super initWithTitle:title])) {
		return nil;
	}
	
	[[NSNotificationCenter chatCenter] addObserver:self selector:@selector(rebuild) name:JVEmoticonSetsScannedNotification object:nil];
	
	return self;
}


@dynamic delegate;


- (void)update
{
	[self rebuild];
}




- (void)rebuild
{
	[self removeAllItems];
	
	
	BOOL setIsOverride = NO;
	JVEmoticonSet * selectedSet = [self.delegate selectedEmoticonsSetInMenu:self isOverride:&setIsOverride];
	BOOL enumerateSet = [self.delegate shouldEnumerateEmoticonsInMenu:self];
	
	if (selectedSet && enumerateSet) {
		for (NSMenuItem * item in selectedSet.emoticonMenuItems) {
			item.action = @selector(_insertEmoticon:);
			[self addItem:item];
		}
		
		if (self.itemArray.count == 0) {
			[self addItemWithTitle:NSLocalizedString( @"No Selectable Emoticons", "no selectable emoticons menu item title" ) action:nil keyEquivalent:@""].enabled = NO;
		}
		
		[self addItem:NSMenuItem.separatorItem];
		
		NSMenuItem * prefsItem = [self addItemWithTitle:NSLocalizedString( @"Preferences", "preferences menu item title" ) action:nil keyEquivalent:@""];
		prefsItem.submenu = [[NSMenu alloc] initWithTitle:NSLocalizedString( @"Preferences", "preferences menu item title" )];
		
		for (NSMenuItem * item in [self preferencesMenuItems:selectedSet isOverride:setIsOverride]) {
			[prefsItem.submenu addItem:item];
		}
	
	} else {
		for (NSMenuItem * item in [self preferencesMenuItems:selectedSet isOverride:setIsOverride]) {
			[self addItem:item];
		}
	}
}




- (NSArray<NSMenuItem *> *)preferencesMenuItems:(JVEmoticonSet *)selectedSet isOverride:(BOOL)isOverride
{
	NSMutableArray * items = [NSMutableArray array]; 
	NSMenuItem * item = nil;
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Style Default", "default style emoticons menu item title" ) action:@selector(changeEmoticons:) keyEquivalent:@""];
	[items addObject:[NSMenuItem separatorItem]];
	
	
	item = [[NSMenuItem alloc] initWithTitle:[[JVEmoticonSet textOnlyEmoticonSet] displayName] action:@selector( changeEmoticons: ) keyEquivalent:@""];
	item.representedObject = [JVEmoticonSet textOnlyEmoticonSet];
	
	
	[items addObject:[NSMenuItem separatorItem]];
	
	NSArray * sets = [JVEmoticonSet.emoticonSets.allObjects sortedArrayUsingSelector:@selector(compare:)];
	for (JVEmoticonSet * set in sets) {
		if (!set.displayName.length) continue;
		
		item = [[NSMenuItem alloc] initWithTitle:set.displayName action:@selector(changeEmoticons:) keyEquivalent:@""];
		item.representedObject = set;
		
		if (set == selectedSet) {
			if (isOverride) {
				item.state = NSOnState;
			} else {
				item.state = NSMixedState;
			}
		} else {
			item.state = NSOffState;
		}
		
		[items addObject:item];
	}
	
	[items addObject:[NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Appearance Preferences...", "appearance preferences menu item title" ) action:@selector(_openAppearancePreferences:) keyEquivalent:@""];
	[items addObject:item];
	
	return items;
}


@end
