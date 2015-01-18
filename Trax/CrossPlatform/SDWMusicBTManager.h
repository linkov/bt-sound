//
//  SDWMusicBTManager.h
//  Trax
//
//  Created by alex on 1/18/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//

#import "SDWBTManager.h"
#import "SDWDeviceInfo.h"

@protocol SDWMusicBTManagerDelegate

@optional

- (void)managerDidPopulateData:(NSArray *)data;


@end


@interface SDWMusicBTManager : SDWBTManager

@property (weak) id<SDWMusicBTManagerDelegate> delegate;

- (void)syncCurrentTrackWithDeviceInfo:(SDWDeviceInfo *)deviceInfo;
- (void)updateTrackToCurrent;

@end
