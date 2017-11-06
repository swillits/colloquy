//
//  CQRoomIconGenerator.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/6/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CQRoomIconGenerator : NSObject

+ (NSImage *)iconOfSize:(NSSize)size forRoomName:(NSString *)name withColor:(NSColor *)color;
+ (NSColor *)generateUniqueColor;

@end
