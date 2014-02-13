//
//  SFRarArchive.m
//  ArchiveALL
//
//  Created by songfei on 14-2-13.
//  Copyright (c) 2014年 songfei. All rights reserved.
//

#import "SFRarArchive.h"

#import "SFArchiveFileItem.h"

int CALLBACK CallbackProc(UINT msg, long UserData, long P1, long P2)
{
	FILE* fp;
	
	switch(msg) {
			
		case UCM_CHANGEVOLUME:
			break;
		case UCM_PROCESSDATA:
			fp = (FILE*)UserData;
            if(fp)
            {
                fwrite((UInt8 *)P1, P2, 1, fp);
            }
			break;
		case UCM_NEEDPASSWORD:
			break;
	}
	return(0);
}


@implementation SFRarArchive

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

-(BOOL) _unrarOpenFile:(NSString*)rarFile inMode:(NSInteger)mode
{
    return [self _unrarOpenFile:rarFile inMode:mode withPassword:nil];
}

- (BOOL)_unrarOpenFile:(NSString *)rarFile inMode:(NSInteger)mode withPassword:(NSString *)aPassword
{
	header = new RARHeaderDataEx;
    bzero(header, sizeof(RARHeaderDataEx));
	flags = new RAROpenArchiveDataEx;
    bzero(flags, sizeof(RAROpenArchiveDataEx));
	
	const char *filenameData = (const char *) [rarFile UTF8String];
	flags->ArcName = new char[strlen(filenameData) + 1];
	strcpy(flags->ArcName, filenameData);
	flags->OpenMode = mode;
	
	_rarFile = RAROpenArchiveEx(flags);
	if (_rarFile == 0 || flags->OpenResult != 0) {
        [self _unrarCloseFile];
		return NO;
    }
	
    if(aPassword != nil) {
        char *_password = (char *) [aPassword UTF8String];
        RARSetPassword(_rarFile, _password);
    }
    
	return YES;
}

-(BOOL) _unrarCloseFile {
	if (_rarFile)
		RARCloseArchive(_rarFile);
    _rarFile = 0;
    
    if (flags)
        delete flags->ArcName;
	delete flags, flags = 0;
    delete header, header = 0;
	return YES;
}

-(NSArray *) listFileItem
{
	int RHCode = 0, PFCode = 0;
    
	if ([self _unrarOpenFile:self.filePath inMode:RAR_OM_LIST_INCSPLIT withPassword:self.password] == NO)
        return nil;
	
	NSMutableArray *array = [NSMutableArray array];
	while ((RHCode = RARReadHeaderEx(_rarFile, header)) == 0) {
        
        SFArchiveFileItem* item = [[SFArchiveFileItem alloc] init];
        
        NSString *name= [self CStringToNSString:header->FileName];
        
        item.isFolder = header->FileAttr & 0x10;
        item.fullPathName = name;
        
        if(item.isFolder)
        {
            item.fullPathName = [name stringByAppendingString:@"/"];
        }
        
        item.fileSize = header->UnpSize;
        
        item.createDate = [NSDate dateWithTimeIntervalSince1970:header->FileTime];
        
		[array addObject:item];
		
		if ((PFCode = RARProcessFile(_rarFile, RAR_SKIP, NULL, NULL)) != 0) {
			[self _unrarCloseFile];
			return nil;
		}
	}
    
	[self _unrarCloseFile];
    
	return array;
}

- (SFArchiveExtractResult)extractFileItem:(NSString *)fileItem destPath:(NSString *)destPath destName:(NSString *)destName
{
    int RHCode = 0, PFCode = 0;
	
	if ([self _unrarOpenFile:self.filePath inMode:RAR_OM_EXTRACT withPassword:self.password] == NO)
        return SFArchiveExtractResult_OpenArchiveFileError;
	
	size_t length = 0;
	while ((RHCode = RARReadHeaderEx(_rarFile, header)) == 0) {
        
        NSString* name = [self CStringToNSString:header->FileName];
        if([fileItem isEqualToString:name])
        {
			length = header->UnpSize;
			break;
		}
		else {
			if ((PFCode = RARProcessFile(_rarFile, RAR_SKIP, NULL, NULL)) != 0) {
				[self _unrarCloseFile];
				return SFArchiveExtractResult_SearchFileError;
			}
		}
	}
	
	if (length == 0) {
		[self _unrarCloseFile];
		return SFArchiveExtractResult_SearchFileError;
	}
    
    if(destName == nil)
    {
        destName = [fileItem lastPathComponent];
    }
    
    NSString* destPathName = [destPath stringByAppendingPathComponent:destName];
    
    FILE* fp = fopen([destPathName UTF8String], "wb");
	
	RARSetCallback(_rarFile, CallbackProc, (long)fp);
	
	PFCode = RARProcessFile(_rarFile, RAR_TEST, NULL, NULL);
    
    fclose(fp);
    fp = NULL;
    
    [self _unrarCloseFile];
    if(PFCode == ERAR_MISSING_PASSWORD) {
        return SFArchiveExtractResult_PasswordError;
    }
    if(PFCode != 0)
    {
        return SFArchiveExtractResult_UnknowError;
    }
    
    return SFArchiveExtractResult_OK;
}

@end
