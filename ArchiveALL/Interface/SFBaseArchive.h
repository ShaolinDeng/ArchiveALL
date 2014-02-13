//
//  SFBaseArchiveInterface.h
//  ArchiveALL
//
//  Created by songfei on 14-2-13.
//  Copyright (c) 2014年 songfei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SFArchiveExtractResult)
{
    SFArchiveExtractResult_OK,
    SFArchiveExtractResult_OpenArchiveFileError,
    SFArchiveExtractResult_ReadArchiveFileError,
    SFArchiveExtractResult_ExtractFileError,
    SFArchiveExtractResult_SearchFileError,
    SFArchiveExtractResult_PasswordError,
    SFArchiveExtractResult_UnknowError,
};

@interface SFBaseArchive : NSObject

@property (nonatomic,strong) NSString* filePath;
@property (nonatomic,strong) NSString* password;

- (instancetype)initWithFilePath:(NSString*)filePath;

- (NSArray*)listFileItem;
- (SFArchiveExtractResult)extractFileItem:(NSString*)fileItem destPath:(NSString*)destPath destName:(NSString*)destName;

@end
