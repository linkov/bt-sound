//
//  SDWMusicManager.h
//  Trax
//
//  Created by alex on 1/18/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SDWMusicManagerDelegate

@optional

- (void)musicDidChangeTrack;


@end



@interface SDWMusicManager : NSObject

@property (weak) id<SDWMusicManagerDelegate> delegate;

- (NSString *)elapsedTime;
- (NSString *)currentTrackID;
- (NSString *)currentTrack;
- (void)playItemWithID:(NSNumber *)itemID beginFrom:(NSNumber *)elapsedTime;

@end
