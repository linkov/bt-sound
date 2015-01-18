//
//  SDWBTManager.h
//  Trax
//
//  Created by alex on 1/17/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDWBTManager : NSObject




/* should be private for subclasses */

- (void)setup;
- (void)sendValue:(id)value forCharacteristic:(CBMutableCharacteristic *)cr;

// PeripheralManager
@property CBPeripheralManager *peripheralManager;
@property NSMutableDictionary *peripheralData;

@property (strong) NSUUID *uid;

// Central manager
@property CBCentralManager *centralManager;
@property (strong) CBPeripheral *discoveredDevice;
@property (strong) NSMutableSet *discoveredDevices;

@property (strong) CBMutableService *mainInfoService;


@end
