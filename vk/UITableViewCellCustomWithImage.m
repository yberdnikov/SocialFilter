//
//  UITableViewCellCustomWithImage.m
//  diplom
//
//  Created by admin on 01.11.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UITableViewCellCustomWithImage.h"

@implementation UITableViewCellCustomWithImage



+(UITableViewCellCustomWithImage*) cell{
    NSArray *objects=[[NSBundle mainBundle] loadNibNamed:@"Cell" owner:nil options:nil];
    return [objects objectAtIndex:0];
}

@end
