//
//  SDWBTManager.m
//  Trax
//
//  Created by alex on 1/17/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//
@import CoreBluetooth;
@import MediaPlayer;
@import CoreLocation;

#import "SDWDeviceInfo.h"
#import "SDWBTManager.h"

NSString * const SongInfoServiceID = @"7E57";
NSString * const SongIDCharacteristicID = @"7E56";
NSString * const SongInfoCharacteristicID = @"7E55";
NSString * const PhoneNameCharacteristicID = @"7E53";

NSString * const ServiceID = @"3718314F-2B74-4809-9EF9-F1D083C98E7E"; // proximityUUID, will be returned from server, same for all users
NSString * const beaconId = @"com.sdwr.found.beaconid";

@interface SDWBTManager () <CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, CLLocationManagerDelegate>

@property (copy) SDWBTManagerCompletionBlock responseBlock;

// beacon advertising

@property CLBeaconRegion *beaconRegion;
@property CBPeripheralManager *peripheralManager;
@property NSMutableDictionary *peripheralData;
@property CLLocationManager *locationManager;
@property CLProximity previousProximity;
@property (strong) NSUUID *uid;

// Central manager
@property CBCentralManager *centralManager;
@property (strong) CBPeripheral *discoveredDevice;
@property (strong) NSMutableSet *discoveredDevices;


// music
@property (strong) CBMutableService *mainInfoService; // song info & profile info
@property (strong) CBMutableCharacteristic *songInfoCharacteristic;
@property (strong) CBMutableCharacteristic *songIDCharacteristic;
@property (strong) CBMutableCharacteristic *phoneInfoCharacteristic;

@end

@implementation SDWBTManager

- (instancetype)init {

    self = [super init];
    if (self) {

        [self setup];
    }
    return self;
}

#pragma mark - Setup

- (void)setup {

    self.discoveredDevices = [NSMutableSet set];

    [[MPMusicPlayerController systemMusicPlayer] beginGeneratingPlaybackNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackChange:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];

    self.uid = [[NSUUID alloc]initWithUUIDString:ServiceID];
    [self setupBeacon];
}

- (void)dealloc {

    [[MPMusicPlayerController systemMusicPlayer]  endGeneratingPlaybackNotifications];
}


- (void)setupBeacon {

    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.uid identifier:beaconId];

    [self.beaconRegion setNotifyEntryStateOnDisplay:YES];
    [self.beaconRegion setNotifyOnEntry:YES];
    [self.beaconRegion setNotifyOnExit:YES];

    [self configureAsTransmitter];
   // [self configureAsReceiver];
}

- (void)configureAsTransmitter {

    NSNumber *power = [NSNumber numberWithInt:-63];
    self.peripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:power];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:queue];
}

- (void)configureAsReceiver {

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

#pragma mark - Music

- (void)trackChange:(NSNotification *)note {

    if (self.mainInfoService.characteristics) {
        [self sendValue:[self currentTrack] forCharacteristic:self.songInfoCharacteristic];
        [self sendValue:[self currentTrackID] forCharacteristic:self.songIDCharacteristic];
        [self sendValue:[self phoneName] forCharacteristic:self.phoneInfoCharacteristic];
    }
}

#pragma mark - GATT Services

- (void)setupServices {


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

    self.mainInfoService.characteristics = @[self.songInfoCharacteristic,self.phoneInfoCharacteristic,self.songIDCharacteristic];

    [self.peripheralManager addService:self.mainInfoService];
    
}

#pragma mark - API

- (void)fetchNearbyDeviceDataWithCompletion:(SDWBTManagerCompletionBlock)block {

}

- (void)updateTrackToCurrent {
    [self trackChange:nil];
}


#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {

    if (!self.mainInfoService) {
        [self setupServices];
    }
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {

    if (!error) {
        [self sendValue:@"test" forCharacteristic:self.songInfoCharacteristic];
    }
}

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

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {


    //    NSLog(@"did discover peripheral: %@, data: %@, %1.2f", [peripheral.identifier UUIDString], advertisementData, [RSSI floatValue]);
    //    CBUUID *uuid = [advertisementData[CBAdvertisementDataServiceUUIDsKey] firstObject];
    //    NSLog(@"service uuid: %@", [uuid UUIDString]);

    //  CBRange range =  [self rangeFromRSSI:[RSSI integerValue]];

    //   if (range == CBRangeNear && !self.btDevice) {
    self.discoveredDevice = peripheral;

    [self.centralManager connectPeripheral:self.discoveredDevice options:nil];
    // [self.manager stopScan];
    //   }
    //
    //    if (range == CBRangeFar && self.btDevice) {
    //
    //        self.btDevice = nil;
    //    }
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

    // self.btDevice = peripheral;
    self.discoveredDevice.delegate = self;
    [self.discoveredDevice discoverServices:@[[CBUUID UUIDWithString:SongInfoServiceID]]];
    [self.centralManager stopScan];


}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self.centralManager scanForPeripheralsWithServices:nil options: @{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
            break;
        default:
            break;
    }


}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

    NSLog(@"didDisconnectPeripheral");
    self.discoveredDevice = nil;
    [self.centralManager scanForPeripheralsWithServices:nil options: @{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
}



#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {

    for (CBService *service in peripheral.services) {

        NSLog(@"Service UUID - %@",service.UUID);

        [self.discoveredDevice discoverCharacteristics:@[
                                                         [CBUUID UUIDWithString:SongInfoCharacteristicID],
                                                         [CBUUID UUIDWithString:PhoneNameCharacteristicID],
                                                         [CBUUID UUIDWithString:SongIDCharacteristicID]
                                                         ]
                                            forService:service];


    }

}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {

    for (CBCharacteristic *cr in service.characteristics) {

        NSLog(@"CBCharacteristic UUID - %@",cr.UUID);
        NSString *printable = [[NSString alloc] initWithData:cr.value encoding:NSUTF8StringEncoding];
        NSLog(@"CBCharacteristic value - %@", printable);

        if (cr.properties & CBCharacteristicPropertyNotify) {


            [self.discoveredDevice setNotifyValue:YES
                                forCharacteristic:cr];

        }


    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    NSString *printable = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"CBCharacteristic value - %@", printable);
//    NSArray *filteredArr = [self.discoveredDevices allObjects];
//    filteredArr = [filteredArr filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self == %@",peripheral]];

    [self.discoveredDevices addObject:peripheral];
    [self updateDeviceInfo];

}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    } else {
        // Notification has stopped
       // [self.centralManager cancelPeripheralConnection:peripheral];
    }
}



#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {

    NSLog(@"didEnterRegion");
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {

    NSLog(@"didExitRegion");
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
//    if ([beacons count] == 0)
//        return;

    NSLog(@"didRangeBeacons - %@",beacons);

}


#pragma mark - Utils 

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
        NSLog(@"deviceName - %@",info.deviceName);
    }

}
- (void)sendValue:(id)value forCharacteristic:(CBMutableCharacteristic *)cr {

    NSData* data = [value dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheralManager updateValue:data forCharacteristic:cr onSubscribedCentrals:nil];
}

- (NSString *)phoneName {
    return [[UIDevice currentDevice] name];
}

- (void)playItemWithID:(NSNumber *)itemID {

    //MPNowPlayingInfoPropertyElapsedPlaybackTime and MPMediaItemPropertyPlaybackDuration.

    MPMediaPredicate *filter = [MPMediaPropertyPredicate predicateWithValue:itemID forProperty:MPMediaItemPropertyPersistentID];
    MPMediaQuery *songQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:filter]];
    NSArray *songs = [songQuery items]; // [songs count] is zero here
    NSLog(@"found songs - %@",songs);

//    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
//    [everything addFilterPredicate:nil]
//    NSArray *itemsFromGenericQuery = [everything items];
//
//    MPMusicPlayerController *iPodMusicPlayerController = [MPMusicPlayerController systemMusicPlayer];
//
//    MPMediaItemCollection *collection = [[MPMediaItemCollection alloc] initWithItems:@[item]];
////    MPMediaItem *item = [collection representativeItem];
//
//
//    [iPodMusicPlayerController setQueueWithItemCollection:collection];
//    [iPodMusicPlayerController setNowPlayingItem:item];
//
//    [iPodMusicPlayerController prepareToPlay];
//    [iPodMusicPlayerController play];
}

- (NSString *)currentTrackID {

    MPMusicPlayerController *iPodMusicPlayerController = [MPMusicPlayerController systemMusicPlayer];
    MPMediaItem *nowPlayingItem = [iPodMusicPlayerController nowPlayingItem];
    NSNumber *tID = [nowPlayingItem valueForProperty:MPMediaItemPropertyPersistentID];
    return [tID stringValue];
}

- (NSString *)currentTrack {

    NSString *track;

    MPMusicPlayerController *iPodMusicPlayerController = [MPMusicPlayerController systemMusicPlayer];

    MPMediaItem *nowPlayingItem = [iPodMusicPlayerController nowPlayingItem];

    if(nowPlayingItem)
    {
        NSString *itemTitle = [nowPlayingItem valueForProperty:MPMediaItemPropertyTitle];
        NSString *itemArtist = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtist];
        track = [NSString stringWithFormat:@"%@-%@",itemArtist,itemTitle];

    }else {
        track = @"nothing";
    }

    return track;
}



@end
