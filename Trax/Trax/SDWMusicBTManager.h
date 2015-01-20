//
//  SDWMusicBTManager.h
//  Trax
//
//  Created by alex on 1/18/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//

#import "SDWBTManager.h"
#import "SDWDeviceInfo.h"




@interface SDWMusicBTManager : SDWBTManager

- (void)syncCurrentTrackWithDeviceInfo:(SDWDeviceInfo *)deviceInfo;
- (void)updateTrackToCurrent;

@end
