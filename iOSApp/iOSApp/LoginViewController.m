//
//  LoginViewController.m
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 2/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import "LoginViewController.h"
#import <ApigeeiOSSDK/Apigee.h>
#import "AppDelegate.h"
#import "Global.h"

static NSString *kSequeSignup = @"signupSeque";
static NSString *kSequeLoginSuccess = @"loginSuccessSeque";


@interface LoginViewController ()

@property BOOL inLoginProcess;

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

    }
    return self;
}

- (void) keyboardDidShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight ) {
        CGSize size = kbSize;
        kbSize.height = size.width;
        kbSize.width = size.height;
    }
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    CGFloat visibleHeight = self.view.frame.size.height - self.scrollView.frame.origin.y - kbSize.height;
    CGFloat textFieldOrigin = self.currentTextField.frame.origin.y;
    if (textFieldOrigin > visibleHeight)
    {
        CGPoint scrollPoint = CGPointMake(0.0, textFieldOrigin - visibleHeight/2);
        [self.scrollView setContentOffset:scrollPoint animated:YES];
        self.scrollView.scrollEnabled = NO;
    }
}

- (void) keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    
    [UIView animateWithDuration:0.4 animations:^{
        self.scrollView.contentInset = contentInsets;
    }];
    self.scrollView.scrollIndicatorInsets = contentInsets;
    self.scrollView.scrollEnabled = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    NSNotificationCenter *notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:self.view.window];
    [notifyCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:self.view.window];
        
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSNotificationCenter *notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [notifyCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [self.view endEditing:YES];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
*/
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    [self.currentTextField resignFirstResponder];
}


- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    self.currentTextField = textField;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    self.currentTextField = nil;
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textFieldView {
    [textFieldView resignFirstResponder];
    return YES;
}


- (IBAction)signupButton:(id)sender
{
    [self performSegueWithIdentifier:kSequeSignup sender:self];
}

- (void) loginSuccess
{
    self.inLoginProcess = NO;
    
    //Global *global = [Global sharedGlobal];
    //ApigeeUser *user = [global getUser];
    
    //NSString *message = [NSString stringWithFormat:@"Login as %@", [user username]];
    //[Global alert:message withTitle:@"Login Successful" buttonTitle:@"OK"];
    
    [self performSegueWithIdentifier:kSequeLoginSuccess sender:nil];
}

- (void) loginFailure:(id) sender
{
    self.inLoginProcess = NO;
    ApigeeClientResponse *response = (ApigeeClientResponse *) sender;
    [Global alert:[response response] withTitle:@"Login Failed" buttonTitle:@"Close"];
}

- (IBAction)loginButton:(id)sender
{
    if ([self inLoginProcess])
        return;
    
    NSString *username = [_username text];
    NSString *password = [_password text];
    
    if (([username length] >0) && ([password length] > 0))
    {
        Global *global = [Global sharedGlobal];
        self.inLoginProcess = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L),
                       ^(void){
                               if ([global login:username withPassword:password])
                               {
                                   [self performSelectorOnMainThread:@selector(loginSuccess) withObject:nil waitUntilDone:NO];
                               } else {
                                   ApigeeClientResponse *response = [global getLastResponse];
                                   
                                   [self performSelectorOnMainThread:@selector(loginFailure:) withObject:response waitUntilDone:YES];
                               }
                       });
        
    } else {
        [Global alert:@"Username and/or Password is missing" withTitle:@"Missing Credentials" buttonTitle:@"OK"];
    }
}

@end
