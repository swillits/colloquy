//
//  CQRoomIconGenerator.m
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/6/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import "CQRoomIconGenerator.h"

@implementation CQRoomIconGenerator

typedef NS_ENUM(NSInteger, CharType) {
	CharTypeNone = -1,
	CharTypeLower,
	CharTypeUpper,
	CharTypePunctuation,
	CharTypeNumber
};


+ (NSImage *)iconOfSize:(NSSize)iconSize forRoomName:(NSString *)fullName withColor:(NSColor *)uniqueColor
{
	NSString * abrvName = nil;
	
	// Get an abbreviated name for the room.
	// : roomname, eRoomName, some-name-here, room-3dname, RoomName99, asdf.asdf
	// = room, eRN, snh, r3d, RN99, a.a
	
	if (fullName.length <= 4) {
		abrvName = fullName;
	
	} else {
		NSCharacterSet * numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
		NSCharacterSet * punctuation = [NSCharacterSet alphanumericCharacterSet].invertedSet;
		NSCharacterSet * upper = [NSCharacterSet uppercaseLetterCharacterSet];
		
		NSMutableString * ms = [NSMutableString string];
		NSUInteger length = fullName.length;
		NSUInteger index = 0;
		CharType charType = CharTypeNone;
		CharType prevCharType = CharTypeNone;
		
		while (index < length) {
			unichar c = [fullName characterAtIndex:index];
			
			if ([numbers characterIsMember:c]) {
				charType = 3;
				[ms appendFormat:@"%C", c];
				
			} else if ([punctuation characterIsMember:c]) {
				charType = 2;
				
			} else {
				if ([upper characterIsMember:c]) {
					charType = CharTypeUpper;
				} else {
					charType = CharTypeLower;
				}
				
				if (prevCharType != CharTypeNone) {
					if (prevCharType == charType) {
						// skip
					} else if (prevCharType == CharTypePunctuation) {
						[ms appendFormat:@"%C", c];
					} else if (prevCharType == CharTypeUpper && charType == CharTypeLower) {
						// skip
					} else if (prevCharType == CharTypeLower && charType == CharTypeUpper) {
						[ms appendFormat:@"%C", c];
					} else {
						[ms appendFormat:@"%C", c];
					}
				} else {
					[ms appendFormat:@"%C", c];
				}
			}
			
			index += 1;
			prevCharType = charType;
		}
		
		if (ms.length < 2 && fullName.length > 2) {
			abrvName = [fullName substringToIndex:MIN((NSUInteger)4, fullName.length)];
		} else {
			abrvName = ms;
		}
	}
	
	
	// Create an attributed string which fits the icon width, shortening the room name if needed
	NSAttributedString * as = nil;
	{
		CGFloat fontSize = 12.0;
		
		do {
			as = [[NSAttributedString alloc] initWithString:abrvName attributes:@{
				NSForegroundColorAttributeName : NSColor.whiteColor,
				NSFontAttributeName : [NSFont systemFontOfSize:fontSize],
			}];
			
			if (as.size.width > 30) {
				if (fontSize > 9.0) {
					fontSize -= 1.0;
				} else {
					abrvName = [abrvName substringToIndex:abrvName.length - 1];
					fontSize = 12.0;
				}
			} else {
				break;
			}
		} while (YES);
	}
	
	
	
	return [NSImage imageWithSize:iconSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		[uniqueColor set];
		[[NSBezierPath bezierPathWithRoundedRect:dstRect xRadius:4 yRadius:4] fill];
		
		NSRect rect = NSZeroRect;
		rect.size = as.size;
		rect.origin.x = floor((dstRect.size.width - as.size.width) / 2.0);
		rect.origin.y = floor((dstRect.size.height - as.size.height) / 2.0);
		[as drawInRect:rect];
		return YES;
	}];
	
	
}


+ (NSColor *)generateUniqueColor
{
	static NSArray * colors = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		srand48((long)(NSDate.timeIntervalSinceReferenceDate) << 8);
		colors = @[
			[NSColor colorWithHue:(224.0 / 360.0)  saturation:( 50.0  / 100.0)  brightness:( 63.0 / 100.0)  alpha:1.0],  // flatBlueColor
			[NSColor colorWithHue:( 24.0 / 360.0)  saturation:( 45.0  / 100.0)  brightness:( 37.0 / 100.0)  alpha:1.0],  // flatBrownColor
			[NSColor colorWithHue:( 25.0 / 360.0)  saturation:( 31.0  / 100.0)  brightness:( 64.0 / 100.0)  alpha:1.0],  // flatCoffeeColor
			[NSColor colorWithHue:(138.0 / 360.0)  saturation:( 45.0  / 100.0)  brightness:( 37.0 / 100.0)  alpha:1.0],  // flatForestGreenColor
			[NSColor colorWithHue:(184.0 / 360.0)  saturation:( 10.0  / 100.0)  brightness:( 65.0 / 100.0)  alpha:1.0],  // flatGrayColor
			[NSColor colorWithHue:(145.0 / 360.0)  saturation:( 77.0  / 100.0)  brightness:( 80.0 / 100.0)  alpha:1.0],  // flatGreenColor
			[NSColor colorWithHue:( 74.0 / 360.0)  saturation:( 70.0  / 100.0)  brightness:( 78.0 / 100.0)  alpha:1.0],  // flatLimeColor
			[NSColor colorWithHue:(283.0 / 360.0)  saturation:( 51.0  / 100.0)  brightness:( 71.0 / 100.0)  alpha:1.0],  // flatMagentaColor
			[NSColor colorWithHue:(  5.0 / 360.0)  saturation:( 65.0  / 100.0)  brightness:( 47.0 / 100.0)  alpha:1.0],  // flatMaroonColor
			[NSColor colorWithHue:(168.0 / 360.0)  saturation:( 86.0  / 100.0)  brightness:( 74.0 / 100.0)  alpha:1.0],  // flatMintColor
			[NSColor colorWithHue:(210.0 / 360.0)  saturation:( 45.0  / 100.0)  brightness:( 37.0 / 100.0)  alpha:1.0],  // flatNavyBlueColor
			[NSColor colorWithHue:( 28.0 / 360.0)  saturation:( 85.0  / 100.0)  brightness:( 90.0 / 100.0)  alpha:1.0],  // flatOrangeColor
			[NSColor colorWithHue:(324.0 / 360.0)  saturation:( 49.0  / 100.0)  brightness:( 96.0 / 100.0)  alpha:1.0],  // flatPinkColor
			[NSColor colorWithHue:(300.0 / 360.0)  saturation:( 45.0  / 100.0)  brightness:( 37.0 / 100.0)  alpha:1.0],  // flatPlumColor
			[NSColor colorWithHue:(222.0 / 360.0)  saturation:( 24.0  / 100.0)  brightness:( 95.0 / 100.0)  alpha:1.0],  // flatPowderBlueColor
			[NSColor colorWithHue:(253.0 / 360.0)  saturation:( 52.0  / 100.0)  brightness:( 77.0 / 100.0)  alpha:1.0],  // flatPurpleColor
			[NSColor colorWithHue:(  6.0 / 360.0)  saturation:( 74.0  / 100.0)  brightness:( 91.0 / 100.0)  alpha:1.0],  // flatRedColor
			[NSColor colorWithHue:( 42.0 / 360.0)  saturation:( 25.0  / 100.0)  brightness:( 94.0 / 100.0)  alpha:1.0],  // flatSandColor
			[NSColor colorWithHue:(204.0 / 360.0)  saturation:( 76.0  / 100.0)  brightness:( 86.0 / 100.0)  alpha:1.0],  // flatSkyBlueColor
			[NSColor colorWithHue:(195.0 / 360.0)  saturation:( 55.0  / 100.0)  brightness:( 51.0 / 100.0)  alpha:1.0],  // flatTealColor
			[NSColor colorWithHue:(356.0 / 360.0)  saturation:( 53.0  / 100.0)  brightness:( 94.0 / 100.0)  alpha:1.0],  // flatWatermelonColor
			[NSColor colorWithHue:( 48.0 / 360.0)  saturation:( 99.0  / 100.0)  brightness:(100.0 / 100.0)  alpha:1.0],  // flatYellowColor
		];
	});
	
	NSUInteger index = (NSUInteger)(round(drand48() * (double)(colors.count - 1)));
	return [colors objectAtIndex:index];
}


@end
