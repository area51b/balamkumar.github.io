//
//  SignUpViewController.h
//  
//
//  Created by Madhav Raj Maharjan on 2/7/14.
//
//

#import <UIKit/UIKit.h>

@interface SignUpViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *fullname;
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *repassword;

@property (strong, nonatomic) UITextField *currentTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)signupButton:(id)sender;

@end
