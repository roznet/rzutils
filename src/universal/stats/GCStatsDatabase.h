//
//  GCStatsDatabase.h
//  RZUtils
//
//  Created by Brice Rosenzweig on 06/10/2019.
//  Copyright © 2019 Brice Rosenzweig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class GCStatsDataSerie;

NS_ASSUME_NONNULL_BEGIN

@interface GCStatsDatabase : NSObject

+(GCStatsDatabase*)database:(FMDatabase*)db table:(NSString*)tableName;

-(void)save:(GCStatsDataSerie*)serie keys:(NSDictionary*)keys;
-(GCStatsDataSerie*)loadForKeys:(NSDictionary*)keys;

@end

NS_ASSUME_NONNULL_END
