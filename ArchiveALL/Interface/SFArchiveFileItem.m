//
//  SFArchiveFileItem.m
//  ArchiveALL
//
//  Created by songfei on 14-2-12.
//  Copyright (c) 2014年 songfei. All rights reserved.
//

#import "SFArchiveFileItem.h"

@implementation SFArchiveFileItem

- (NSString *)description
{
    NSMutableString* str = [[NSMutableString alloc] init];
    [str appendFormat:@"%@",self.fullPathName];
    
    return str;
}

- (NSString *)fileName
{
    return [self.fullPathName lastPathComponent];
}

@end
