//
//  main.m
//  CocoaSQLMapper
//
//  Copyright 2010-2011 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

//
// $ sqlite3 Test.db
// > CREATE TABLE Person(key INTEGER PRIMARY KEY, name, age, dateOfBirth);
// > INSERT INTO Person(name, age, dateOfBirth) VALUES('Yamada', 25, NULL);
// > INSERT INTO Person(name, age, dateOfBirth) VALUES('Satoh', NULL, 799599600.0);
// > INSERT INTO Person(name, age, dateOfBirth) VALUES(NULL, 35, 971103600.0);
//

#import "Person.h"
#import "SMDatabase.h"

#import <Foundation/Foundation.h>

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        NSError *error = nil;
        SMDatabase *database = [[SMDatabase alloc] initWithPath:@"/Users/marvel/Test.db" error:&error];
        
        Person *parameter = [[Person alloc] init];
        parameter.name = @"Yamada";
        Person *person = [database queryObjectBySQL:@"SELECT * FROM Person WHERE name = :name" parameter:parameter resultClass:[Person class] error:&error];
        NSLog(@"%@", person);
		
        parameter.name = @"Yamada";
        parameter.age = 30;
        int count = [database updateBySQL:@"UPDATE Person SET age = :age WHERE name = :name" parameter:parameter error:&error];
        NSLog(@"%i", count);
        
        parameter.name = nil;
        parameter.age = 45;
        parameter.dateOfBirth = nil;
        long long key = [database insertBySQL:@"INSERT INTO Person (name, age, dateOfBirth) VALUES(:name, :age, :dateOfBirth)" parameter:parameter error:&error];
        NSLog(@"%qi", key);
        
        parameter.age = 25;
        NSArray *persons = [database queryArrayBySQL:@"SELECT * FROM Person WHERE age > :age" parameter:parameter resultClass:[Person class] error:&error];
        for (Person* person in persons) {
            NSLog(@"%@", person);
        }
        
        [database close];
    }
    return 0;
}
