//
//  main.m
//  CocoaSQLMapper
//
//  Copyright 2010-2012 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

//
// $ sqlite3 ~/Documents/persons.sqlite
// > CREATE TABLE Person(key INTEGER PRIMARY KEY, name, age, dateOfBirth, married);
// > INSERT INTO Person(name, age, dateOfBirth, married) VALUES('Yamada', 25, NULL, 0);
// > INSERT INTO Person(name, age, dateOfBirth, married) VALUES('Satoh', NULL, 799599600.0, 1);
// > INSERT INTO Person(name, age, dateOfBirth, married) VALUES(NULL, 35, 971103600.0, 0);
//

#import "Person.h"
#import "Count.h"
#import "SMDatabase.h"

#import <Foundation/Foundation.h>

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths[0] stringByAppendingPathComponent:@"persons.sqlite"];
        
        __block NSError *error = nil;
        SMDatabase *database = [[SMDatabase alloc] initWithPath:path error:&error];
        if (!database) {
            NSLog(@"%@", error);
            return 1;
        }
        
        Person *parameter = [[Person alloc] init];
        parameter.name = @"Yamada";
        Person *person = [database selectObjectBySQL:@"SELECT * FROM Person WHERE name = :name" parameter:parameter resultClass:[Person class] error:&error];
        if (!person) {
            NSLog(@"%@", error);
            return 1;
        }
        NSLog(@"%@", person);
		
        if (![database transactionWithBlock:^(NSError **err) {
            parameter.name = @"Yamada";
            parameter.age = @30;
            int count = [database updateBySQL:@"UPDATE Person SET age = :age WHERE name = :name" parameter:parameter error:err];
            if (!count) {
                return NO;
            }
            NSLog(@"%i", count);
            
            parameter.name = @"Suzuki";
            parameter.age = @45;
            parameter.married = YES;
            long long int key = [database insertBySQL:@"INSERT INTO Person (name, age, dateOfBirth, married) VALUES(:name, :age, :dateOfBirth, :married)" parameter:parameter error:err];
            if (!key) {
                return NO;
            }
            NSLog(@"%qi", key);
            
            return YES;
        } error:&error]) {
            NSLog(@"%@", error);
            return 1;
        }
        
        parameter.age = @30;
        NSArray *persons = [database selectArrayBySQL:@"SELECT * FROM Person WHERE age > :age" parameter:parameter resultClass:[Person class] error:&error];
        if (!persons) {
            NSLog(@"%@", error);
            return 1;
        }
        for (Person* person in persons) {
            NSLog(@"%@", person);
        }
        
        if (![database selectWithBlock:^(id rst, NSError **err) {
            NSLog(@"%@", person);
            return YES;
        } bySQL:@"SELECT * FROM Person WHERE age > :age" parameter:parameter resultClass:[Person class] error:&error]) {
            NSLog(@"%@", error);
            return 1;
        }
        
        Count *count = [database selectObjectBySQL:@"SELECT COUNT(*) AS value FROM Person" parameter:parameter resultClass:[Count class] error:&error];
        if (!count) {
            NSLog(@"%@", error);
            return 1;
        }
        NSLog(@"%@", count);
    }
    return 0;
}
