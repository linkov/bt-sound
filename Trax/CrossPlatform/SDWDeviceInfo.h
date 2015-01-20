//
//  SDWDeviceInfo.h
//  Trax
//
//  Created by alex on 1/18/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDWDeviceInfo : NSObject

@property (strong) NSString *deviceName;
@property (strong) NSString *songInfo;
@property (strong) NSNumber *songID;
@property (strong) NSNumber *songElapsedTime;

@end
