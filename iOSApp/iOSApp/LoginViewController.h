//
//  LoginViewController.h
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 2/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@property (strong, nonatomic) UITextField *currentTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction) signupButton:(id) sender;
- (IBAction) loginButton:(id)sender;

@end
