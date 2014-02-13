//
//  SFRarArchive.h
//  ArchiveALL
//
//  Created by songfei on 14-2-13.
//  Copyright (c) 2014年 songfei. All rights reserved.
//

#import "SFBaseArchive.h"

#import "raros.hpp"
#import "dll.hpp"

@interface SFRarArchive : SFBaseArchive
{
    HANDLE	 _rarFile;
	struct	 RARHeaderDataEx *header;
	struct	 RAROpenArchiveDataEx *flags;
}

@end
