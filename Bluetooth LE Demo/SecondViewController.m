//
//  SecondViewController.m
//  Bluetooth LE Demo
//
//  Created by 許家豪 on 2014/11/18.
//
//  Copyright (c) 2014年 Esignal. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()
{
    
}

@end

@implementation SecondViewController

-(void)setBleShieldSeque:(id)newbleShieldSeque
{
    _bleShieldSeque=newbleShieldSeque;
    bleShield=_bleShieldSeque;
    bleShield.delegate=self;

    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)ButtonTapped:(UIButton *)sender
{
    [self dismissModalViewControllerAnimated:true];
}

- (IBAction)DidOnExit:(UITextField *)sender
{
    [sender resignFirstResponder];
}

- (void)keyBoardWillShow:(NSNotification *)note{
    
    CGRect rect = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat ty = - rect.size.height;
    
    [UIView animateWithDuration:0.45 animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, ty);
    }];
    
}

#pragma mark 键盘即将退出
- (void)keyBoardWillHide:(NSNotification *)note{
    
    [UIView animateWithDuration:0.1 animations:^{
        self.view.transform = CGAffineTransformIdentity;
    }];
}

-(void)viewDidDisappear:(BOOL)animated
{
    if(bleShield.activePeripheral.state==CBPeripheralStateConnected) [bleShield CancelConnectWithPeriperal:bleShield.activePeripheral];
    
}

-(void) bleDidDisconnect:(CBPeripheral *)peripheral
{
    NSLog(@"Disconnected with %@ ", peripheral.identifier.UUIDString);
    
    
    UIAlertView * alertBox=[[UIAlertView alloc]
                            initWithTitle:@"警告"
                            message:@"裝置斷線"
                            delegate:self
                            cancelButtonTitle:@"確定"
                            otherButtonTitles:nil, nil];
    [alertBox show];
    
}

-(void) bleDidReceiveData:(CBCharacteristic *)characteristic data:(unsigned char *) data length:(int) length
{
    NSData *receiveData = [NSData dataWithBytes:data length:length];
    NSString *decodeString = [[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding];
    
    [self.DataText insertText:decodeString];
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) bleDidConnect:(CBPeripheral *)peripheral
{
    NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
    
    
}
- (IBAction)SendButtonTapped:(UIButton *)sender
{
    Byte data[20];
    NSInteger data_len = 0;
    NSData *sendData = [self.SendText.text dataUsingEncoding:NSUTF8StringEncoding];
    
    memset(data,0x00, 20);
    
    data_len=sendData.length;
    [sendData getBytes:data length:data_len];
    
    sendData= [NSData dataWithBytes:data length:data_len];
    
    [bleShield write:bleShield.activePeripheral d:sendData];
    
    self.SendText.text=@"";
}


@end
