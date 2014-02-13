//
//  SFArchiveFileItem.h
//  ArchiveALL
//
//  Created by songfei on 14-2-12.
//  Copyright (c) 2014年 songfei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFArchiveFileItem : NSObject

@property (nonatomic,readonly) NSString* fileName;
@property (nonatomic,strong) NSString* fullPathName;
@property (nonatomic) UInt64 fileSize;
@property (nonatomic,strong) NSDate* createDate;
@property (nonatomic) BOOL isFolder;
@property (nonatomic) BOOL isCrypted;

@end
