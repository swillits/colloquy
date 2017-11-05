//
//  CQEmoticonMenu.h
//  Colloquy (Application)
//
//  Created by Seth Willits on 11/4/17.
//  Copyright © 2017 Colloquy Project. All rights reserved.
//

#import <Foundation/Foundation.h>
@class JVEmoticonSet;
@class CQEmoticonMenu;
@protocol CQEmoticonMenuDelegate;
NS_ASSUME_NONNULL_BEGIN


@protocol CQEmoticonMenuDelegate <NSMenuDelegate>
- (JVEmoticonSet *)selectedEmoticonsSetInMenu:(CQEmoticonMenu *)menu isOverride:(BOOL *)isOverride;
- (BOOL)shouldEnumerateEmoticonsInMenu:(CQEmoticonMenu *)menu;
@end


@interface CQEmoticonMenu : NSMenu
@property (readwrite, assign) BOOL enumerateSet;
@property (readwrite, nullable, weak) id<CQEmoticonMenuDelegate> delegate;
@end



@protocol CQEmoticonMenuTarget
- (void)changeEmoticons:(id _Nullable)sender;
- (void)_openAppearancePreferences:(id _Nullable)sender;
- (void)_insertEmoticon:(id _Nullable)sender;
@end
NS_ASSUME_NONNULL_END

