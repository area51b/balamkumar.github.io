//
//  SignUpViewController.m
//  
//
//  Created by Madhav Raj Maharjan on 2/7/14.
//
//

#import "SignUpViewController.h"
#import "Global.h"

static NSString *kSegueSignupSuccess = @"signupSuccessSeque";

@interface SignUpViewController ()

@property BOOL inSignupProcess;

@end

@implementation SignUpViewController


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

- (void) signupSuccess
{
    self.inSignupProcess = NO;
    
    Global *global = [Global sharedGlobal];
    ApigeeClientResponse *response = [global getLastResponse];
    ApigeeUser *user = (ApigeeUser *)[[response entities] objectAtIndex:0];   

    NSString *message = [NSString stringWithFormat:@"Login with your username: %@ and your password", [user username]];
    [Global alert: message withTitle:@"Signup Successful" buttonTitle:@"OK"];
    [self performSegueWithIdentifier:kSegueSignupSuccess sender:nil];
}

- (void) signupFailure:(id) sender
{
    self.inSignupProcess = NO;
    
    ApigeeClientResponse *response = (ApigeeClientResponse *) sender;
    [Global alert:[response response] withTitle:@"Signup Failed" buttonTitle:@"Close"];
}

- (void) signupButton:(id)sender
{
    if ([self inSignupProcess])
        return;
    
    NSString *username = [_username text];
    NSString *fullname = [_fullname text];
    NSString *email = [_email text];
    NSString *password = [_password text];
    NSString *repassword = [_repassword text];
    
    if (![username length]>0)
    {
       [Global alert:@"Username is mandatory" withTitle:@"Missing Inputs" buttonTitle:@"OK"];
        return;
    }
    
    if (![password length] > 0)
    {
        [Global alert:@"Password is mandatory" withTitle:@"Missing Inputs" buttonTitle:@"OK"];
        return;
    }
    
    if (![password isEqualToString:repassword])
    {
        [Global alert:@"The password do not match!" withTitle:@"Password Error" buttonTitle:@"Close"];
        return;
    }
    
    Global *global = [Global sharedGlobal];
    self.inSignupProcess = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L),
                   ^(void){
                       if ([global signup:username email:email fullname:fullname password:password])
                       {
                           [self performSelectorOnMainThread:@selector(signupSuccess) withObject:nil waitUntilDone:NO];
                           
                       } else {
                           ApigeeClientResponse *response = [global getLastResponse];
                           [self performSelectorOnMainThread:@selector(signupFailure:) withObject:response waitUntilDone:YES];
                       }
                   });

}

@end
