### POC using Apigee ###

### Configure Push Notification ###

**Change Bundle ID of iOSApp to** `com.ncs.fow`

**Create Apple APN Notification Certificates**

* Create AppID `com.ncs.fow` with Push Notification Enabled.
* Generate APN Development Certificate for [fow-apn-dev.p12](fow-apn-deve.cer)

**Configure Notifier on Admin Portal**

* Upload APN Notification Certificate (above) as `iOS-FOW`.

### Add Push Notification suppport to iOSApp ###

Update content of [AppDelegate.m](iOSApp/iOSApp/AppDelegate.m) as shown below

```
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    UIRemoteNotificationType enabledTypes = [application enabledRemoteNotificationTypes];
    if (enabledTypes & (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound))
    {
        NSLog(@"Registering for remote notifications");
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *notifier = @"iOS-FOW";
    ApigeeDataClient *dataClient = [[Global sharedGlobal] dataClient];
    ApigeeClientResponse *response = [dataClient setDevicePushToken:deviceToken forNotifier:notifier];
    if ([response completedSuccessfully])
    {
        NSLog(@"Registered for remote notifications");
    } else {
        NSLog(@"Error: %@",response.rawResponse);

    }
}

- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Error: %@",error.localizedDescription);
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    {
        NSString *message = nil;
        id alert = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
        if ([alert isKindOfClass:[NSString class]]) {
            message = alert;
        } else if ([alert isKindOfClass:[NSDictionary class]]) {
            message = [alert objectForKey:@"body"];
        }
        if (message) {    
            UIApplicationState state = [application applicationState];
            if (state == UIApplicationStateActive)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Title"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"Close"
                                                      otherButtonTitles:nil, nil];
                [alertView show];
            } else {
                NSLog(@"Remote Notification received");
                NSLog(@" - alert: %@", [[userInfo objectForKey:@"aps"] objectForKey:@"alert"]);
                NSLog(@" - badge: %@", [[userInfo objectForKey:@"aps"] objectForKey:@"badge"]);
                NSLog(@" - sound: %@", [[userInfo objectForKey:@"aps"] objectForKey:@"sound"]);
            }
        }
    }
}
       
```

### Test Push Notification ###

Test push notifcation from [Admin Portal](https://www.apigee.com/appservices/#!) :'Push' > 'Send Notification'

Select `iOS-FOW` as notifier, All Devices, JSON payload (below), Deliery:now and Submit.

```
{
    "aps" : {
        "alert" : {
            "body" : "Bob wants to play poker",
          },
        "badge" : 5,
    }
}
```

