//
//  MFLCoreDataEditorProjectLoader.m
//  CoreDataUtil
//
//  Created by Chris Wilson on 6/27/12.
//  Copyright (c) 2012 mFluent LLC. All rights reserved.
//

#import "MFLCoreDataEditorProjectLoader.h"
#import "MFLConstants.h"

@implementation MFLCoreDataEditorProjectLoader


- (NSFetchRequest*) fetchRequestForEntitiesOfType: (NSManagedObjectContext*) managedObjectContext: (NSString*) entityName {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext]];
    return fetchRequest;
}

- (NSArray*) executeFetchRequest: (NSManagedObjectContext*) managedObjectContext: (NSFetchRequest*) fetchRequest {
    NSError* error = nil;
    NSArray* results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil) {
        @throw [NSException exceptionWithName:@"Could not execute fetch request." reason:[NSString stringWithFormat:@"Trouble executing fetch request %@: %@", fetchRequest, error] userInfo:nil];
    }
    return results;
}

- (NSDictionary*) decodeProjectFile: (NSString*) projectFilePath {
    NSLog(@"TODO: decode core data editor project file...");
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreData" withExtension:@"ext"];
    NSManagedObjectModel* managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    if (!managedObjectModel) {
        return nil;
    }
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSError *error = nil;
    
    NSURL* projectURL = [NSURL fileURLWithPath:projectFilePath];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:projectURL options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    
    NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    NSFetchRequest* fetchRequest = [self fetchRequestForEntitiesOfType:managedObjectContext :@"CDEConfiguration"];
    NSArray* results = [self executeFetchRequest:managedObjectContext :fetchRequest];
    
    if (results != nil && [results count] > 0) {
        NSManagedObject* object = [results objectAtIndex:0];
        
        NSURL* modelURL = [object valueForKey:@"modelURL"];
        NSURL* storeURL = [object valueForKey:@"storeURL"];
        
        NSLog(@"modelURL: %@\nstoreURL: %@",modelURL, storeURL);
        NSDictionary* newValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:MFL_SQLiteStoreType], MFL_DB_FORMAT_KEY,
                                   [modelURL path], MFL_MOM_FILE_KEY,
                                   [storeURL path], MFL_DB_FILE_KEY,
                                   nil];
        
        return newValues;
    }
    
    
    return nil;
}

@end
