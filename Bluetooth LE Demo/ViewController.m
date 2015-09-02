//
//  ViewController.m
//
//  Bluetooth LE Demo Code
//
//  Created by CHIA HAO HSU on 2014/11/18.

//  Copyright (c) 2014年 Esignal. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()
{
    UIImageView *backGround;
    UIImageView *backGround2;
    
    UITableView * DeviceListView;
    
    NSMutableArray* UUIDarray;
    NSMutableArray* DeviceNameArray;
    NSMutableArray* perpherial;
    
    NSTimer *ScanPeripheralTimer;

}

@end

static bool Scaning=false;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UUIDarray = [[NSMutableArray alloc] init ];
    DeviceNameArray = [[NSMutableArray alloc] init];
    perpherial = [[NSMutableArray alloc] init];
    
    bleShield = [[BLE alloc] init];
    [bleShield CentralManagerInitial];
    bleShield.delegate = self;
    
    CGFloat ScreenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat ScreenHight = [[UIScreen mainScreen] bounds].size.height;
    
    DeviceListView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,ScreenWidth,ScreenHight) style:UITableViewStylePlain];
    
    DeviceListView.dataSource = self;
    DeviceListView.delegate = self;
    
    [DeviceListView setRowHeight:60];
    [DeviceListView setSeparatorInset:UIEdgeInsetsZero];
    [self.view addSubview:DeviceListView];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    
    
    bleShield.delegate = self;
    [DeviceListView reloadData];
    
    ScanPeripheralTimer=[NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(ScanPeripheralTimer:) userInfo:nil repeats:YES];
    
}

#pragma mark - Timer Action
- (void)ScanPeripheralTimer:(NSTimer *)timer
{
    if(Scaning)
    {
        Scaning=false;
        [bleShield stopScanPeripheral];
        [DeviceListView reloadData];

        return;
        
    }

    [UUIDarray removeAllObjects];
    [DeviceNameArray removeAllObjects];
    [perpherial removeAllObjects];
    
     Scaning=true;
    [bleShield ScanPeripheral];
    

    
}

-(void) bledidDiscover:(CBPeripheral *)peripheral RSSI:(NSNumber *)RSSI
{
    NSString *UUIDstring;
    NSString *DeviceNameString;
    NSString *UUIDstring2;
    NSString *DeviceNameString2;
    
    UUIDstring2 = peripheral.identifier.UUIDString;
    DeviceNameString2 = peripheral.name;
    
    if(DeviceNameString2==nil)return;
    
    for(int i = 0; i < UUIDarray.count; i++)
    {
        UUIDstring = [UUIDarray objectAtIndex:i];
        DeviceNameString= [DeviceNameArray objectAtIndex:i];
        
        if ((UUIDstring == NULL) || (DeviceNameString == NULL))
            continue;
        
        if ([peripheral.identifier.UUIDString isEqualToString:UUIDstring])
        {

            [perpherial replaceObjectAtIndex:i withObject:peripheral];
            [UUIDarray replaceObjectAtIndex:i withObject:peripheral.identifier.UUIDString];
            [DeviceNameArray replaceObjectAtIndex:i withObject:peripheral.name];
            [DeviceListView reloadData];
            return;
        }
    }
    [perpherial addObject:peripheral];
    [UUIDarray addObject:UUIDstring2];
    [DeviceNameArray addObject:DeviceNameString2];
    
    [DeviceListView reloadData];
    
    
}

//-----------------------------------------------------------------------------
//
//                      ----TableView Controll----
//
//-----------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{

    return [[NSString alloc] initWithFormat:@"  Peripherals Nearby"];

}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(perpherial.count!=0 && section==0)  return DeviceNameArray.count;
    
    return 1;
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    if (cell == nil) { cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] init];
    }
    
    if(perpherial.count==0)
    {
        cell.textLabel.text =@"No Device";
    }
    else
    {
        cell.textLabel.text = [DeviceNameArray objectAtIndex:indexPath.row];
        cell.detailTextLabel.text=[UUIDarray objectAtIndex:indexPath.row];
        
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if(perpherial.count==0)
    {
        [DeviceListView reloadData];
        return;
    }
    
    [ScanPeripheralTimer invalidate];
    
    if(Scaning)
    {
        Scaning=false;
        [bleShield stopScanPeripheral];
    }
    
      if(bleShield.activePeripheral.state==CBPeripheralStateConnected)
     {
     [bleShield CancelConnectWithPeriperal:bleShield.activePeripheral];
     }
    
    
    NSLog(@"Select %@",[DeviceNameArray objectAtIndex:indexPath.row]);
    
    [bleShield connectPeripheral:[perpherial objectAtIndex:indexPath.row]];
    
    [self performSegueWithIdentifier:@"goto_Control" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    BLE *object1 = bleShield;
    [[segue destinationViewController] setBleShieldSeque:object1];

}

-(void) bleDidConnect:(CBPeripheral *)peripheral
{
    NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
    
}

-(void) bleDidDisconnect:(CBPeripheral *)peripheral
{
    NSLog(@"Disconnected with %@ ", peripheral.identifier.UUIDString);
}

-(void) bleDidReceiveData:(CBCharacteristic *)characteristic data:(unsigned char *) data length:(int) length
{

    NSData *receiveData = [NSData dataWithBytes:data length:length];
    NSString *decodeString = [[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding];
    
    NSLog(@"Receive:%@",decodeString);
    
}
@end
