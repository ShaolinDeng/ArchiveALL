//
//  SFBaseArchiveInterface.m
//  ArchiveALL
//
//  Created by songfei on 14-2-13.
//  Copyright (c) 2014年 songfei. All rights reserved.
//

#import "SFBaseArchive.h"

@implementation SFBaseArchive

- (instancetype)initWithFilePath:(NSString*)filePath
{
    self = [super init];
    if(self)
    {
        self.filePath = filePath;
    }
    return self;
}

- (NSArray*)listFileItem
{
    return nil;
}

- (SFArchiveExtractResult)extractFileItem:(NSString*)fileItem destPath:(NSString*)destPath destName:(NSString*)destName
{
    return SFArchiveExtractResult_UnknowError;
}

@end
