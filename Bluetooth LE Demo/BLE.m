//
//  Created by 欣宏電子 CHIA HAO HSU on 2014/11.18.
//
//  Copyright (c) 2014年 許家豪. All rights reserved.

#import "BLE.h"

@interface BLE()

@end

@implementation BLE

@synthesize delegate;
@synthesize CM;
@synthesize peripherals;
@synthesize MacAddress;

@synthesize activePeripheral;

static bool isConnect=false;
static bool done = false;

//-----------------------------------------------------------------------------------
//BLE initial
- (void) CentralManagerInitial
{
    self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

//-----------------------------------------------------------------------------------
//Read BLE RSSI
-(void) readRSSI:(CBPeripheral *)peripheral
{
    [peripheral readRSSI];
    
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    [[self delegate]  bleDidUpdateRSSI:peripheral.RSSI];
}

//-----------------------------------------------------------------------------------
//Read Data From Device
-(void) read:(CBPeripheral *)Periperal Service:(CBService *)Service Characteristic:(CBCharacteristic *)Characteristic
{
    
    CBService *service = [self findServiceFromUUID:Service.UUID p:Periperal];
    
    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:service.UUID],
              Periperal.identifier.UUIDString);
        
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:Characteristic.UUID service:service];
    
    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:Characteristic.UUID],
              [self CBUUIDToString:Service.UUID],
              Periperal.identifier.UUIDString);
        
        return;
    }
    
    [Periperal readValueForCharacteristic:Characteristic];
}

//Receivce Data From Device
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    unsigned char data[20];
    
    static unsigned char buf[512];
    static int len = 0;
    
    NSInteger data_len;
    
    if (!error)
    {
        len = 0;
        data_len = characteristic.value.length;
        [characteristic.value getBytes:data length:data_len];
        
        memcpy(&buf[len], data, data_len);
        len += data_len;
        
        
        [[self delegate] bleDidReceiveData:characteristic data:buf length: len];
        
    }
    
    else
    {
        NSLog(@"UpdateValueForCharacteristic failed!");
    }
}

//-----------------------------------------------------------------------------------
//Write
-(void) write:(CBPeripheral *)peripheral d:(NSData *)d
{
    CBUUID *uuid_service = [CBUUID UUIDWithString:@"fff0"];
    CBUUID *uuid_char = [CBUUID UUIDWithString:@"fff2"];
    
    [self writeValue:uuid_service characteristicUUID:uuid_char p:peripheral data:d];
}

-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data
{
    
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];
    
    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);
        
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    
    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);
        
        return;
    }
    
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    
}

//-----------------------------------------------------------------------------------
//Enable & Notification
-(void) enableReadNotification:(CBPeripheral *)Periperal Switch:(BOOL) Switch
{
    CBUUID *UUID_Service = [CBUUID UUIDWithString:@"FFF0"];
    CBUUID *UUID_Characteristic = [CBUUID UUIDWithString:@"FFF1"];
    
    CBService *service = [self findServiceFromUUID:UUID_Service p:Periperal];
    
    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:UUID_Service],
              Periperal.identifier.UUIDString);
        
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:UUID_Characteristic service:service];
    
    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:UUID_Characteristic],
              [self CBUUIDToString:UUID_Service],
              Periperal.identifier.UUIDString);
        
        return;
    }
    
    [Periperal setNotifyValue:Switch forCharacteristic:characteristic];
    
}
//-----------------------------------------------------------------------------------
-(NSString *) CBUUIDToString:(CBUUID *) cbuuid;
{
    NSData *data = cbuuid.data;
    
    if ([data length] == 2)
    {
        const unsigned char *tokenBytes = [data bytes];
        return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
    }
    else if ([data length] == 16)
    {
        NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[data bytes]];
        return [nsuuid UUIDString];
    }
    
    return [cbuuid description];
}
//-----------------------------------------------------------------------------------
//Search BLE Device

-(void)ScanPeripheral
{
    if (self.CM.state != CBCentralManagerStatePoweredOn)
    {
        NSLog(@"CoreBluetooth not correctly initialized !");
        NSLog(@"State = %d (%s)\r\n", self.CM.state, [self centralManagerStateToString:self.CM.state]);
        return;
    }
    
    NSLog(@"Start Scanning");
    self.peripherals = [[NSMutableArray alloc] initWithObjects:nil];
    [self.CM scanForPeripheralsWithServices:nil options:nil];
    
}

-(void)stopScanPeripheral
{
    [self.CM stopScan];
    NSLog(@"Stop Scanning");
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    for(int i = 0; i < self.peripherals.count; i++)
    {
        CBPeripheral *p = [self.peripherals objectAtIndex:i];
        
        if ((p.identifier == NULL) || (peripheral.identifier == NULL))
            continue;
        
        if ([p.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
        {
            [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
            NSLog(@"Duplicate UUID found updating...");
            
            return;
        }
    }
    [self.peripherals addObject:peripheral];
    
    [[self delegate] bledidDiscover:peripheral RSSI:RSSI];
}
//-----------------------------------------------------------------------------------
//DisConnect with device
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    
    [[self delegate] bleDidDisconnect:peripheral];
}

//CentralManger connect to device
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    
    NSLog(@"Verify Information...");
    
    self.activePeripheral = peripheral;
    
    [self getAllServicesFromPeripheral:peripheral];
}
//-----------------------------------------------------------------------------------
//Connect to device
- (void) connectPeripheral:(CBPeripheral *)peripheral
{
        NSLog(@"Connecting peripheral with UUID : %@", peripheral.identifier.UUIDString);
        
        self.activePeripheral = peripheral;
        self.activePeripheral.delegate = self;
        
        done=false;
        isConnect=true;
        
        [self.CM connectPeripheral:self.activePeripheral
                           options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    
}

-(void) CancelConnectWithPeriperal:(CBPeripheral *)peripheral
{
    [self.CM cancelPeripheralConnection:peripheral];
    
}


//DidUpadteforCharacteristics
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error)
    {
        
        for (int i=0; i < service.characteristics.count; i++)
        {
            CBCharacteristic *c= [service.characteristics objectAtIndex:i];//
            CBService *s= [peripheral.services objectAtIndex:(peripheral.services.count-1)];
            
            
            if ([service.UUID isEqual:s.UUID] && i==service.characteristics.count-1)
            {
                if (!done)
                {
                    isConnect=false;
                    done = true;
                    
                    [self enableReadNotification:self.activePeripheral Switch:YES];
                    [[self delegate] bleDidConnect:peripheral];
                    
                }
            }
            
            
        }
    }
    else
    {
        NSLog(@"Characteristic discorvery unsuccessful!");
    }
}
//-----------------------------------------------------------------------------------
-(void) getAllServicesFromPeripheral:(CBPeripheral *)p
{
    [p discoverServices:nil]; // Discover all services without filter
    
}
//-----------------------------------------------------------------------------------
-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p
{
    for (int i=0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        [p discoverCharacteristics:nil forService:s];
    }
}
//-----------------------------------------------------------------------------------
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error)
    {
        for (CBService *service in peripheral.services) {
            
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
    else
    {
        NSLog(@"Service discovery was unsuccessful!");
    }
}
//-----------------------------------------------------------------------------------
- (const char *) centralManagerStateToString: (int)state
{
    switch(state)
    {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }
    
    return "Unknown state";
}

//-----------------------------------------------------------------------------------
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
#if TARGET_OS_IPHONE
    
    NSLog(@"BLE Change %ld State (%s)", central.state, [self centralManagerStateToString:central.state]);

#endif
}

//-----------------------------------------------------------------------------------
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error)
    {
        
        if(characteristic.isNotifying==0)
        {
            NSLog(@"Disable ReadNotification state for peripheral with UUID %@\r\n",peripheral.identifier.UUIDString);
        }
        else
        {
            NSLog(@"Enable ReadNotification state for peripheral with UUID %@\r\n",peripheral.identifier.UUIDString);
        }
        
    }
    else
    {
        NSLog(@"Error in setting notification state for characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristic.UUID],
              [self CBUUIDToString:characteristic.service.UUID],
              peripheral.identifier.UUIDString);
        
        NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    }
}
//-----------------------------------------------------------------------------------
- (BOOL) UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2
{
    if ([UUID1.UUIDString isEqualToString:UUID2.UUIDString])
        return TRUE;
    else
        return FALSE;
}

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    
    if (memcmp(b1, b2, UUID1.data.length) == 0)
        return 1;
    else
        return 0;
}

-(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2
{
    char b1[16];
    
    [UUID1.data getBytes:b1];
    UInt16 b2 = [self swap:UUID2];
    
    if (memcmp(b1, (char *)&b2, 2) == 0)
        return 1;
    else
        return 0;
}

-(UInt16) CBUUIDToInt:(CBUUID *) UUID
{
    char b1[16];
    [UUID.data getBytes:b1];
    return ((b1[0] << 8) | b1[1]);
}

-(CBUUID *) IntToCBUUID:(UInt16)UUID
{
    char t[16];
    t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
    NSData *data = [[NSData alloc] initWithBytes:t length:16];
    return [CBUUID UUIDWithData:data];
}
//-----------------------------------------------------------------------------------
-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID])
            return s;
    }
    
    return nil; //Service not found on this peripheral
}
//-----------------------------------------------------------------------------------
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    
    return nil; //Characteristic not found on this service
}
//-----------------------------------------------------------------------------------
-(UInt16) swap:(UInt16)s
{
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}


@end