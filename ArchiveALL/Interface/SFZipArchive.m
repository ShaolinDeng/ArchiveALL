//
//  SFZipArchive.m
//  ArchiveALL
//
//  Created by songfei on 14-2-13.
//  Copyright (c) 2014年 songfei. All rights reserved.
//

#import "SFZipArchive.h"
#import "SFArchiveFileItem.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <fcntl.h>

#include <unistd.h>
#include <utime.h>
#include "unzip.h"

#define WRITEBUFFERSIZE (8192)

@implementation SFZipArchive

- (NSString*)CStringToNSString:(const char*)cstr
{
    NSString *str= [NSString stringWithCString:cstr encoding:NSUTF8StringEncoding];
    if(str == nil)
    {
        str = [NSString stringWithCString:cstr encoding:0x80000632];
    }
    else if(str == nil)
    {
        str = [NSString stringWithCString:cstr encoding:0x80000631];
    }
    return str;
}

- (NSArray *)listFileItem
{
    int i;
    char datebuf[32];

    unzFile uf=NULL;

    uf = unzOpen64([self.filePath UTF8String]);
    
    if (uf==NULL)
    {
        return nil;
    }
    
    unz_global_info64 gi;
    int err;
    
    unzGetGlobalInfo64(uf,&gi);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat: @"MM-dd-yyyy HH:mm:ss"];
    
    NSMutableArray* array = [[NSMutableArray alloc] init];
    
    for (i=0;i<gi.number_entry;i++)
    {
        char filename_inzip[256];
        unz_file_info64 file_info;

        err = unzGetCurrentFileInfo64(uf,&file_info,filename_inzip,sizeof(filename_inzip),NULL,0,NULL,0);
        if (err!=UNZ_OK)
        {
            break;
        }
        
        SFArchiveFileItem* item = [[SFArchiveFileItem alloc] init];
        
        item.fileSize = file_info.uncompressed_size;
        
        if ((file_info.flag & 1) != 0)
        {
            item.isCrypted = YES;
        }
        else
        {
            item.isCrypted = NO;
        }
        
        sprintf(datebuf, "%2.2lu-%2.2lu-%4.2lu %2.2lu:%2.2lu:%2.2lu",
                (uLong)file_info.tmu_date.tm_mon + 1,
                (uLong)file_info.tmu_date.tm_mday,
                (uLong)file_info.tmu_date.tm_year,
                (uLong)file_info.tmu_date.tm_hour,(uLong)file_info.tmu_date.tm_min,(uLong)file_info.tmu_date.tm_sec);
        
        item.createDate = [dateFormatter dateFromString:[NSString stringWithUTF8String:datebuf]];
        
        item.fullPathName = [self CStringToNSString:filename_inzip];
        item.isFolder = [item.fullPathName hasSuffix:@"/"];
        
        [array addObject:item];
        
        if ((i+1)<gi.number_entry)
        {
            err = unzGoToNextFile(uf);
            if (err!=UNZ_OK)
            {
                break;
            }
        }
    }
    
    unzClose(uf);
    
    return array;
}

- (SFArchiveExtractResult)extractFileItem:(NSString *)fileItem destPath:(NSString *)destPath destName:(NSString *)destName
{
    NSInteger retCode = SFArchiveExtractResult_OK;
    uLong i;
    unz_global_info64 gi;
    int err;
    
    unzFile uf = NULL;
    
    uf = unzOpen64([self.filePath UTF8String]);
    
    if (uf==NULL)
    {
        return SFArchiveExtractResult_OpenArchiveFileError;
    }
    
    err = unzGetGlobalInfo64(uf,&gi);
    if (err!=UNZ_OK)
    {
        retCode = SFArchiveExtractResult_ReadArchiveFileError;
    }
    
    for (i=0;i<gi.number_entry;i++)
    {
        
        char filename_inzip[256];
        unz_file_info64 file_info;
        
        err = unzGetCurrentFileInfo64(uf,&file_info,filename_inzip,sizeof(filename_inzip),NULL,0,NULL,0);
        if (err!=UNZ_OK)
        {
            retCode = SFArchiveExtractResult_ReadArchiveFileError;
            break;
        }
        
        NSString* name = [self CStringToNSString:filename_inzip];
        
        if([fileItem isEqualToString:name])
        {
            void* buf;
            uInt size_buf;
            FILE* fout;
            
            size_buf = WRITEBUFFERSIZE;
            buf = (void*)malloc(size_buf);
            
            const char* password = [self.password UTF8String];
            err = unzOpenCurrentFilePassword(uf,password);
            if (err!=UNZ_OK)
            {
                retCode = SFArchiveExtractResult_PasswordError;
            }
            
            if(destName == nil)
            {
                destName = [fileItem lastPathComponent];
            }
            NSString* destPathName = [destPath stringByAppendingPathComponent:destName];
            
            fout=fopen64([destPathName UTF8String],"wb");
            
            if (fout != NULL)
            {
                do
                {
                    err = unzReadCurrentFile(uf,buf,size_buf);
                    if (err<0)
                    {
                        retCode = SFArchiveExtractResult_ExtractFileError;
                        break;
                    }
                    if (err>0)
                        if (fwrite(buf,err,1,fout)!=1)
                        {
                            retCode = SFArchiveExtractResult_ExtractFileError;
                            break;
                        }
                }
                while (err>0);
                if (fout)
                    fclose(fout);
                
            }
            else
            {
                retCode = SFArchiveExtractResult_ExtractFileError;
            }
            
            unzCloseCurrentFile(uf);
            free(buf);
            
            break;
        }
        
        if ((i+1)<gi.number_entry)
        {
            err = unzGoToNextFile(uf);
            if (err!=UNZ_OK)
            {
                retCode = SFArchiveExtractResult_SearchFileError;
                break;
            }
        }
    }
    
    unzClose(uf);

    return retCode;
}

@end
