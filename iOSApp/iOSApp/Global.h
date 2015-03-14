//
//  AppDelegate.h
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 2/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ApigeeiOSSDK/Apigee.h>

static NSString *kWoeidURL = @"http://portalcity-prod.apigee.net/woeid/v1/search?q=%@&apikey=%@";
static NSString *kForecastURL = @"http://portalcity-prod.apigee.net/weather/v1/forecast?w=%@&u=%@&apikey=%@";

static NSString *kWoeidApiKey =  @"zgkZmV9GOEKZljFpG4Ko5cpqRok9zA0x";

static NSString *kWoeidEntity = @"woeid";

@interface Global : NSObject{}

@property (strong, nonatomic) ApigeeClient *apigeeClient;
@property (strong, nonatomic) ApigeeMonitoringClient *monitoringClient;
@property (strong, nonatomic) ApigeeDataClient *dataClient;
@property (strong, nonatomic) ApigeeClientResponse *response;

+ (id)sharedGlobal;

+ (void) alert:(NSString*) message withTitle:(NSString*) title buttonTitle:(NSString *) buttonTitle;

- (void) initializeWithOrgName:(NSString*) OrgName andAppName:(NSString*) appName;

- (BOOL) login:(NSString*) username withPassword:(NSString*) password;
- (BOOL) signup:(NSString *) username email:(NSString*) email fullname:(NSString*) fullname password:(NSString*) password;
- (ApigeeUser *) getUser;
- (void) logOut;

-(ApigeeClientResponse *)createEntity:(NSDictionary *)newEntity;
- (ApigeeClientResponse *) getLastResponse;

@end
