//
//  SDWBTManager.h
//  Trax
//
//  Created by alex on 1/17/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDWDeviceInfo.h"

@protocol SDWBTManagerDelegate

@optional

- (void)managerDidPopulateData:(NSArray *)data;


@end




typedef void (^SDWBTManagerCompletionBlock)(id object, NSError *error);


@interface SDWBTManager : NSObject

@property (weak) id<SDWBTManagerDelegate> delegate;

- (void)syncCurrentTrackWithDeviceInfo:(SDWDeviceInfo *)deviceInfo;
- (void)updateTrackToCurrent;


@end
