//
//  SDWMusicBTManager.m
//  Trax
//
//  Created by alex on 1/18/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//
@import CoreBluetooth;
#import "SDWMusicBTManager.h"
#import "SDWMusicManager.h"
#import "Utils.h"

NSString * const SongInfoServiceID = @"7E57";
NSString * const SongIDCharacteristicID = @"7E56";
NSString * const SongInfoCharacteristicID = @"7E55";
NSString * const PhoneNameCharacteristicID = @"7E53";
NSString * const SongElapsedTimeCharacteristicID = @"7E52";

@interface SDWMusicBTManager () <SDWMusicManagerDelegate,CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

@property SDWMusicManager *musicManager;

// music

@property (strong) CBMutableCharacteristic *songInfoCharacteristic;
@property (strong) CBMutableCharacteristic *songIDCharacteristic;
@property (strong) CBMutableCharacteristic *songElapsedTimeCharacteristic;

@property (strong) CBMutableCharacteristic *phoneInfoCharacteristic;

@end

@implementation SDWMusicBTManager


#pragma mark - API

- (void)updateTrackToCurrent {
    [self musicDidChangeTrack];
}

- (void)syncCurrentTrackWithDeviceInfo:(SDWDeviceInfo *)deviceInfo {

    [self.musicManager playItemWithID:deviceInfo.songID beginFrom:deviceInfo.songElapsedTime];
    
}

#pragma mark - SDWMusicManagerDelegate

- (void)musicDidChangeTrack {

    if (self.mainInfoService.characteristics) {
        [self sendValue:[self.musicManager currentTrack] forCharacteristic:self.songInfoCharacteristic];
        [self sendValue:[self.musicManager currentTrackID] forCharacteristic:self.songIDCharacteristic];
        [self sendValue:[Utils phoneName] forCharacteristic:self.phoneInfoCharacteristic];
        [self sendValue:[self.musicManager elapsedTime] forCharacteristic:self.songElapsedTimeCharacteristic];
    }
}


#pragma mark - Setup

- (void)setup {

    [super setup];


    self.musicManager = [SDWMusicManager new];
    self.musicManager.delegate = self;

}

- (void)setupServices {

    self.songElapsedTimeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:SongElapsedTimeCharacteristicID]
                                                                            properties:CBCharacteristicPropertyNotify
                                                                                 value:nil
                                                                           permissions:CBAttributePermissionsReadable];

    self.phoneInfoCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:PhoneNameCharacteristicID]
                                                                      properties:CBCharacteristicPropertyNotify
                                                                           value:nil
                                                                     permissions:CBAttributePermissionsReadable];

    self.songIDCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:SongIDCharacteristicID]
                                                                   properties:CBCharacteristicPropertyNotify
                                                                        value:nil
                                                                  permissions:CBAttributePermissionsReadable];

    self.songInfoCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:SongInfoCharacteristicID]
                                                                     properties:CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];


    self.mainInfoService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:SongInfoServiceID]
                                                          primary:YES];

    self.mainInfoService.characteristics = @[self.songInfoCharacteristic,self.phoneInfoCharacteristic,self.songIDCharacteristic,self.songElapsedTimeCharacteristic];

    [self.peripheralManager addService:self.mainInfoService];
    
}


#pragma mark - Negotiate connection

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {

    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        // [self.peripheralManager startAdvertising:self.peripheralData];

        if (!self.peripheralManager.isAdvertising) {
            [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:SongInfoServiceID]] }];
        }

    } else if (peripheral.state == CBPeripheralManagerStatePoweredOff) {
        [self.peripheralManager stopAdvertising];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

    // self.btDevice = peripheral;
    self.discoveredDevice.delegate = self;
    [self.discoveredDevice discoverServices:@[[CBUUID UUIDWithString:SongInfoServiceID]]];
    [self.centralManager stopScan];
    
    
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {

    for (CBService *service in peripheral.services) {

        NSLog(@"Service UUID - %@",service.UUID);

        [self.discoveredDevice discoverCharacteristics:@[
                                                         [CBUUID UUIDWithString:SongInfoCharacteristicID],
                                                         [CBUUID UUIDWithString:PhoneNameCharacteristicID],
                                                         [CBUUID UUIDWithString:SongIDCharacteristicID],
                                                         [CBUUID UUIDWithString:SongElapsedTimeCharacteristicID]
                                                         ]
                                            forService:service];
        
        
    }
    
}

#pragma mark - Parse data

- (void)updateDeviceInfo {

    NSMutableArray *deviceInfoObjects = [[NSMutableArray alloc]initWithCapacity:self.discoveredDevices.count];

    for (CBPeripheral *per in self.discoveredDevices) {


        SDWDeviceInfo *info = [SDWDeviceInfo new];


        for (CBService *ser in per.services) {

            for (CBCharacteristic *ch in ser.characteristics) {


                //NSLog(@"ch.UUID.UUIDString - %@",ch.UUID.UUIDString);

                if ([ch.UUID.UUIDString isEqualToString:SongIDCharacteristicID]) {
                    NSString *sID = [[NSString alloc] initWithData:ch.value encoding:NSUTF8StringEncoding];
                    info.songID = [NSNumber numberWithLongLong:[sID longLongValue]];
                }

                if ([ch.UUID.UUIDString isEqualToString:SongElapsedTimeCharacteristicID]) {
                    NSString *sID = [[NSString alloc] initWithData:ch.value encoding:NSUTF8StringEncoding];
                    info.songElapsedTime = [NSNumber numberWithLongLong:[sID longLongValue]];
                }

                if ([ch.UUID.UUIDString isEqualToString:PhoneNameCharacteristicID]) {
                    NSString *sID = [[NSString alloc] initWithData:ch.value encoding:NSUTF8StringEncoding];
                    info.deviceName = sID;
                }

                if ([ch.UUID.UUIDString isEqualToString:SongInfoCharacteristicID]) {
                    NSString *printable = [[NSString alloc] initWithData:ch.value encoding:NSUTF8StringEncoding];
                    info.songInfo = printable;
                }


            }
        }

        [deviceInfoObjects addObject:info];
    }

    for (SDWDeviceInfo *info in deviceInfoObjects) {

        NSLog(@"trackID - %@",info.songID);
        NSLog(@"trackName - %@",info.songInfo);
        NSLog(@"trackElapsed - %f",[info.songInfo doubleValue]);
        NSLog(@"deviceName - %@",info.deviceName);
    }
    
    [self.delegate managerDidPopulateData:deviceInfoObjects];
    
}


@end
