//
//  SF7zArchive.m
//  ArchiveALL
//
//  Created by songfei on 14-2-13.
//  Copyright (c) 2014年 songfei. All rights reserved.
//

#include <stdio.h>

#include <sys/stat.h>
#include <sys/types.h>

#include "7z.h"
#include "7zAlloc.h"
#include "7zCrc.h"
#include "7zFile.h"

#import "SFArchiveFileItem.h"
#import "SF7zArchive.h"

static ISzAlloc g_Alloc = { SzAlloc, SzFree };

static int Buf_EnsureSize(CBuf *dest, size_t size)
{
    if (dest->size >= size)
        return 1;
    Buf_Free(dest, &g_Alloc);
    return Buf_Create(dest, size, &g_Alloc);
}

static Byte kUtf8Limits[5] = { 0xC0, 0xE0, 0xF0, 0xF8, 0xFC };

static Bool Utf16_To_Utf8(Byte *dest, size_t *destLen, const UInt16 *src, size_t srcLen)
{
    size_t destPos = 0, srcPos = 0;
    for (;;)
    {
        unsigned numAdds;
        UInt32 value;
        if (srcPos == srcLen)
        {
            *destLen = destPos;
            return True;
        }
        value = src[srcPos++];
        if (value < 0x80)
        {
            if (dest)
                dest[destPos] = (char)value;
            destPos++;
            continue;
        }
        if (value >= 0xD800 && value < 0xE000)
        {
            UInt32 c2;
            if (value >= 0xDC00 || srcPos == srcLen)
                break;
            c2 = src[srcPos++];
            if (c2 < 0xDC00 || c2 >= 0xE000)
                break;
            value = (((value - 0xD800) << 10) | (c2 - 0xDC00)) + 0x10000;
        }
        for (numAdds = 1; numAdds < 5; numAdds++)
            if (value < (((UInt32)1) << (numAdds * 5 + 6)))
                break;
        if (dest)
            dest[destPos] = (char)(kUtf8Limits[numAdds - 1] + (value >> (6 * numAdds)));
        destPos++;
        do
        {
            numAdds--;
            if (dest)
                dest[destPos] = (char)(0x80 + ((value >> (6 * numAdds)) & 0x3F));
            destPos++;
        }
        while (numAdds != 0);
    }
    *destLen = destPos;
    return False;
}

static SRes Utf16_To_Utf8Buf(CBuf *dest, const UInt16 *src, size_t srcLen)
{
    size_t destLen = 0;
    Bool res;
    Utf16_To_Utf8(NULL, &destLen, src, srcLen);
    destLen += 1;
    if (!Buf_EnsureSize(dest, destLen))
        return SZ_ERROR_MEM;
    res = Utf16_To_Utf8(dest->data, &destLen, src, srcLen);
    dest->data[destLen] = 0;
    return res ? SZ_OK : SZ_ERROR_FAIL;
}


static SRes Utf16_To_Char(CBuf *buf, const UInt16 *s, int fileMode)
{
    int len = 0;
    for (len = 0; s[len] != '\0'; len++);
    
    fileMode = fileMode;
    return Utf16_To_Utf8Buf(buf, s, len);
    
}

//static WRes MyCreateDir(const UInt16 *name)
//{
//    CBuf buf;
//    WRes res;
//    Buf_Init(&buf);
//    RINOK(Utf16_To_Char(&buf, name, 1));
//
//    res = mkdir((const char *)buf.data, 0777) == 0 ? 0 : 1;
//    Buf_Free(&buf, &g_Alloc);
//    return res;
//}
//
//static WRes OutFile_OpenUtf16(CSzFile *p, const UInt16 *name)
//{
//    CBuf buf;
//    WRes res;
//    Buf_Init(&buf);
//    RINOK(Utf16_To_Char(&buf, name, 1));
//    res = OutFile_Open(p, (const char *)buf.data);
//    Buf_Free(&buf, &g_Alloc);
//    return res;
//
//}

NSString* UInt16StrToNSString(const UInt16 *s)
{
    CBuf buf;
    SRes res;
    NSString* str = nil;
    Buf_Init(&buf);
    res = Utf16_To_Char(&buf, s, 0);
    if (res == SZ_OK)
    {
        str = [NSString stringWithCString:(char*)buf.data encoding:NSUTF8StringEncoding];
    }
    Buf_Free(&buf, &g_Alloc);
    return str;
}

static char *UIntToStr(char *s, unsigned value, int numDigits)
{
    char temp[16];
    int pos = 0;
    do
        temp[pos++] = (char)('0' + (value % 10));
    while (value /= 10);
    for (numDigits -= pos; numDigits > 0; numDigits--)
        *s++ = '0';
    do
        *s++ = temp[--pos];
    while (pos);
    *s = '\0';
    return s;
}

#define PERIOD_4 (4 * 365 + 1)
#define PERIOD_100 (PERIOD_4 * 25 - 1)
#define PERIOD_400 (PERIOD_100 * 4 + 1)

static void ConvertFileTimeToString(const CNtfsFileTime *ft, char *s)
{
    unsigned year, mon, day, hour, min, sec;
    UInt64 v64 = (ft->Low | ((UInt64)ft->High << 32)) / 10000000;
    Byte ms[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    unsigned t;
    UInt32 v;
    sec = (unsigned)(v64 % 60); v64 /= 60;
    min = (unsigned)(v64 % 60); v64 /= 60;
    hour = (unsigned)(v64 % 24); v64 /= 24;
    
    v = (UInt32)v64;
    
    year = (unsigned)(1601 + v / PERIOD_400 * 400);
    v %= PERIOD_400;
    
    t = v / PERIOD_100; if (t ==  4) t =  3; year += t * 100; v -= t * PERIOD_100;
    t = v / PERIOD_4;   if (t == 25) t = 24; year += t * 4;   v -= t * PERIOD_4;
    t = v / 365;        if (t ==  4) t =  3; year += t;       v -= t * 365;
    
    if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0))
        ms[1] = 29;
    for (mon = 1; mon <= 12; mon++)
    {
        unsigned s = ms[mon - 1];
        if (v < s)
            break;
        v -= s;
    }
    day = (unsigned)v + 1;
    s = UIntToStr(s, year, 4); *s++ = '-';
    s = UIntToStr(s, mon, 2);  *s++ = '-';
    s = UIntToStr(s, day, 2);  *s++ = ' ';
    s = UIntToStr(s, hour, 2); *s++ = ':';
    s = UIntToStr(s, min, 2);  *s++ = ':';
    s = UIntToStr(s, sec, 2);
}

void PrintError(char *sz)
{
    printf("\nERROR: %s\n", sz);
}

NSArray* list7zFileItem(NSString* filePath)
{
    const char* inputPath;
    if(filePath == nil)
    {
        return nil;
    }
    inputPath = [filePath UTF8String];
    
    CFileInStream archiveStream;
    CLookToRead lookStream;
    CSzArEx db;
    SRes res;
    ISzAlloc allocImp;
    ISzAlloc allocTempImp;
    UInt16 *temp = NULL;
    size_t tempSize = 0;
    
    allocImp.Alloc = SzAlloc;
    allocImp.Free = SzFree;
    
    allocTempImp.Alloc = SzAllocTemp;
    allocTempImp.Free = SzFreeTemp;
    
    if (InFile_Open(&archiveStream.file, inputPath))
    {
        PrintError("can not open input file");
        return nil;
    }
    
    FileInStream_CreateVTable(&archiveStream);
    LookToRead_CreateVTable(&lookStream, False);
    
    lookStream.realStream = &archiveStream.s;
    LookToRead_Init(&lookStream);
    
    CrcGenerateTable();
    
    SzArEx_Init(&db);
    res = SzArEx_Open(&db, &lookStream.s, &allocImp, &allocTempImp);
    
    NSMutableArray* array = [[NSMutableArray alloc] init];
    if (res == SZ_OK)
    {
        UInt32 i;
        
        Byte *outBuffer = 0;
        
        char tdate[32];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
        
        for (i = 0; i < db.db.NumFiles; i++)
        {
            
            const CSzFileItem *f = db.db.Files + i;
            
            SFArchiveFileItem* item = [[SFArchiveFileItem alloc] init];
            
            size_t len;
            len = SzArEx_GetFileNameUtf16(&db, i, NULL);
            
            if (len > tempSize)
            {
                SzFree(NULL, temp);
                tempSize = len;
                temp = (UInt16 *)SzAlloc(NULL, tempSize * sizeof(temp[0]));
                if (temp == 0)
                {
                    res = SZ_ERROR_MEM;
                    break;
                }
            }
            
            SzArEx_GetFileNameUtf16(&db, i, temp);
            
            item.fullPathName = UInt16StrToNSString(temp);
            
            if(f->IsDir)
            {
                item.fullPathName = [item.fullPathName stringByAppendingString:@"/"];
            }
            
            item.fileSize = f->Size;
            item.isFolder = f->IsDir;
            
            if (f->MTimeDefined)
            {
                ConvertFileTimeToString(&f->MTime, tdate);
                item.createDate = [dateFormatter dateFromString:[NSString stringWithUTF8String:tdate]];
            }
            else
            {
                item.createDate = nil;
            }
            
            [array addObject:item];
        }
        
        IAlloc_Free(&allocImp, outBuffer);
    }
    
    SzArEx_Free(&db, &allocImp);
    SzFree(NULL, temp);
    
    File_Close(&archiveStream.file);
    if (res == SZ_OK)
    {
        return array;
    }
    
    return nil;
}


int extract7zFileItem(NSString* filePath, NSString* fileItem, NSString* destFilePath)
{
    const char* inputPath;
    if(filePath == nil)
    {
        return 1;
    }
    inputPath = [filePath UTF8String];
    
    const char* outputPath;
    if(destFilePath == nil)
    {
        return 1;
    }
    outputPath = [destFilePath UTF8String];
    
    CFileInStream archiveStream;
    CLookToRead lookStream;
    CSzArEx db;
    SRes res;
    ISzAlloc allocImp;
    ISzAlloc allocTempImp;
    UInt16 *temp = NULL;
    size_t tempSize = 0;
    
    allocImp.Alloc = SzAlloc;
    allocImp.Free = SzFree;
    
    allocTempImp.Alloc = SzAllocTemp;
    allocTempImp.Free = SzFreeTemp;
    
    if (InFile_Open(&archiveStream.file, inputPath))
    {
        PrintError("can not open input file");
        return 1;
    }
    
    FileInStream_CreateVTable(&archiveStream);
    LookToRead_CreateVTable(&lookStream, False);
    
    lookStream.realStream = &archiveStream.s;
    LookToRead_Init(&lookStream);
    
    CrcGenerateTable();
    
    SzArEx_Init(&db);
    res = SzArEx_Open(&db, &lookStream.s, &allocImp, &allocTempImp);
    
    if (res == SZ_OK)
    {
        UInt32 i;
        
        UInt32 blockIndex = 0xFFFFFFFF;
        Byte *outBuffer = 0;
        size_t outBufferSize = 0;
        
        for (i = 0; i < db.db.NumFiles; i++)
        {
            size_t offset = 0;
            size_t outSizeProcessed = 0;
            const CSzFileItem *f = db.db.Files + i;
            size_t len;
            if (f->IsDir) continue;
            len = SzArEx_GetFileNameUtf16(&db, i, NULL);
            
            if (len > tempSize)
            {
                SzFree(NULL, temp);
                tempSize = len;
                temp = (UInt16 *)SzAlloc(NULL, tempSize * sizeof(temp[0]));
                if (temp == 0)
                {
                    res = SZ_ERROR_MEM;
                    break;
                }
            }
            
            SzArEx_GetFileNameUtf16(&db, i, temp);
            
            NSString* findItem = UInt16StrToNSString(temp);
            
            if(![findItem isEqualToString:findItem])
            {
                continue;
            }
            
            res = SzArEx_Extract(&db, &lookStream.s, i,
                                 &blockIndex, &outBuffer, &outBufferSize,
                                 &offset, &outSizeProcessed,
                                 &allocImp, &allocTempImp);
            if (res != SZ_OK)
                break;
            
            CSzFile outFile;
            size_t processedSize;
            
            if (OutFile_Open(&outFile, outputPath))
            {
                PrintError("can not open output file");
                res = SZ_ERROR_FAIL;
                break;
            }
            processedSize = outSizeProcessed;
            if (File_Write(&outFile, outBuffer + offset, &processedSize) != 0 || processedSize != outSizeProcessed)
            {
                PrintError("can not write output file");
                res = SZ_ERROR_FAIL;
                break;
            }
            if (File_Close(&outFile))
            {
                PrintError("can not close output file");
                res = SZ_ERROR_FAIL;
                break;
            }
            
        }
        IAlloc_Free(&allocImp, outBuffer);
    }
    
    SzArEx_Free(&db, &allocImp);
    SzFree(NULL, temp);
    
    File_Close(&archiveStream.file);
    if (res == SZ_OK)
    {
        return 0;
    }
    return 2;
}

@implementation SF7zArchive

- (NSArray*)listFileItem
{
    return list7zFileItem(self.filePath);
}

- (SFArchiveExtractResult)extractFileItem:(NSString*)fileItem destPath:(NSString*)destPath destName:(NSString *)destName
{
    if(destName == nil)
    {
        destName = [fileItem lastPathComponent];
    }
    
    NSString* destPathName = [destPath stringByAppendingPathComponent:destName];
    
    return extract7zFileItem(self.filePath,fileItem,destPathName);
}

@end
