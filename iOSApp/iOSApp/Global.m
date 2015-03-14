//
//  AppDelegate.m
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 2/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import "Global.h"

@implementation Global

+ (id)sharedGlobal
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

+ (void) alert:(NSString*) message withTitle:(NSString*) title buttonTitle:(NSString *) buttonTitle
{
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:buttonTitle
                                          otherButtonTitles:nil];
    [alert show];
}

- (void) initializeWithOrgName:(NSString*) orgName andAppName:(NSString*) appName
{
    self.apigeeClient = [[ApigeeClient alloc] initWithOrganizationId:orgName applicationId:appName];
    self.monitoringClient = [self.apigeeClient monitoringClient];
    self.dataClient = [self.apigeeClient dataClient];
    
    [self.dataClient setLogging:true];

}

- (BOOL) login:(NSString*) username withPassword:(NSString*) password
{
    self.response = [self.dataClient logInUser:username password:password];
    if ([self.response completedSuccessfully])
    {
        ApigeeUser *user = [self.dataClient getLoggedInUser];
        if (user.username)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL) signup:(NSString *) username email:(NSString*) email fullname:(NSString*) fullname password:(NSString*) password
{
    self.response = [self.dataClient addUser:username email:email name:fullname password:password];
    if ([self.response completedSuccessfully])
    {
        return YES;
    }
    return NO;
}

- (ApigeeUser *) getUser
{
    return [self.dataClient getLoggedInUser];
}

-(ApigeeClientResponse *)createEntity:(NSDictionary *)newEntity
{
    NSString *query = [NSString stringWithFormat:@"name='%@'",[newEntity objectForKey:@"name"]];
    self.response = [self.dataClient getEntities:[newEntity objectForKey:@"type"] queryString:query];
    
    if ([self.response completedSuccessfully])
    {
        if ([self.response entityCount] == 0)
        {
            self.response = [self.dataClient createEntity:newEntity];
        }
    }
    return self.response;
}

- (ApigeeClientResponse *) getLastResponse
{
    return self.response;
}

- (void) logOut
{
    [self.dataClient logOut];
}

- (NSMutableArray *) getWoeidList
{
    NSMutableArray *woeidList = [[NSMutableArray alloc] init];
    
//    ApigeeCollection *collection = [self.dataClient getCollection:@"weather-woeid"];
    
    [woeidList addObject:@"23424948"];
    [woeidList addObject:@"12589352"];
    
    return woeidList;
}

@end
