#import <Foundation/Foundation.h>
#import "SMDatabase.h"
#import "Person.h"

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	/*
CREATE TABLE Person(key INTEGER PRIMARY KEY, name, age, dateOfBirth);
INSERT INTO Person(name, age, dateOfBirth) VALUES('Yamada', 25, NULL);
INSERT INTO Person(name, age, dateOfBirth) VALUES('Satoh', NULL, 799599600.0);
INSERT INTO Person(name, age, dateOfBirth) VALUES(NULL, 35, 971103600.0);
	 */
	
	NSError *error = nil;
	SMDatabase *database = [[[SMDatabase alloc] initWithPath:@"./Test.db"
													   error:&error] autorelease];
	
	Person *parameter = [[[Person alloc] init] autorelease];
	parameter.name = @"Yamada";
	Person *person = [database queryObjectBySQL:@"SELECT * FROM Person WHERE name = :name"
									  parameter:parameter
									resultClass:[Person class]
										  error:&error];
    NSLog(@"%@", person);
		
	parameter.name = @"Yamada";
	parameter.age = 30;
	int count = [database updateBySQL:@"UPDATE Person SET age = :age WHERE name = :name"
							parameter:parameter
								error:&error];
	NSLog(@"%i", count);
	
	parameter.name = @"Tanaka";
	parameter.age = 45;
	parameter.dateOfBirth = [NSDate date];
	long long key = [database insertBySQL:@"INSERT INTO Person (name, age, dateOfBirth) VALUES(:name, :age, :dateOfBirth)"
								parameter:parameter
									error:&error];
	NSLog(@"%qi", key);
	
	parameter.age = 20;
	NSArray *persons = [database queryArrayBySQL:@"SELECT * FROM Person WHERE age > :age"
									   parameter:parameter
									 resultClass:[Person class]
										   error:&error];
	for (Person* aPerson in persons) {
		NSLog(@"%@", aPerson);
	}
	
    [database close];
	
	[pool drain];
	return 0;
}
