//
//  ForecastTableViewCell.m
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 11/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import "ForecastTableViewCell.h"

@implementation ForecastTableViewCell
@synthesize imageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
