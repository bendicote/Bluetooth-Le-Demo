//
//  Created by CHIA HAO HSU on 2014/11/18.

//  Copyright (c) 2014年 許家豪. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE

#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@protocol BLEDelegate

@optional
-(void) bledidDiscover:(CBPeripheral *)peripheral RSSI:(NSNumber *)RSSI;
-(void) bleDidConnect:(CBPeripheral *)peripheral;
-(void) bleDidDisconnect:(CBPeripheral *)peripheral;
-(void) bleDidUpdateRSSI:(NSNumber *) rssi;
-(void) bleDidReceiveData:(CBCharacteristic *)characteristic data:(unsigned char *) data length:(int) length;

@required
@end


@interface BLE : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    
}

@property (nonatomic,assign) id <BLEDelegate> delegate;

@property (strong, nonatomic) NSMutableArray *peripherals;
@property (strong, nonatomic) NSString *MacAddress;
@property (strong, nonatomic) CBCentralManager *CM;
@property (strong, nonatomic) CBPeripheral *activePeripheral;

//CBCentralManager Initial
-(void)CentralManagerInitial;

//Scan
-(void)ScanPeripheral;

//Stop Scan
-(void)stopScanPeripheral;

//Connect
-(void) connectPeripheral:(CBPeripheral *)peripheral;

-(void) CancelConnectWithPeriperal:(CBPeripheral *)peripheral;

//Read
-(void) read:(CBPeripheral *)Periperal Service:(CBService *)Service Characteristic:(CBCharacteristic *)Characteristic;

//Write
-(void) write:(CBPeripheral *)peripheral d:(NSData *)d;

//Read RSSI
-(void) readRSSI:(CBPeripheral *)peripheral;

//Enable or Disable ReadNotification
-(void) enableReadNotification:(CBPeripheral *)Periperal Switch:(BOOL) Switch;

@end
