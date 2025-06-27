@IsTest
private class SAIDControllerTest {
    @IsTest
    static void testValidNewInsert() {
        String validId = '8001015009087';
        Test.setMock(HttpCalloutMock.class, new MockCalendarificResponse());
        Test.startTest();
        SAIDController.SAIDResult info = SAIDController.processSAID(validId);
        Test.stopTest();

        System.assertEquals(Date.newInstance(1980, 1, 1), info.dob, 'DOB should parse as 1980-01-01');
        System.assertEquals('Male', info.gender, 'Gender should parse as Male');
        System.assertEquals(true, info.citizen, 'Citizen flag should be true for SA citizen');
        System.assertEquals(1980, info.birthYear, 'Birth year should be 1980');
        System.assert(!info.holidays.isEmpty(), 'Holidays should be returned');
        System.assert(info.holidays[0].name.contains('New Year'), 'Should include New Year');

        SA_ID__c rec = [SELECT Search_Count__c FROM SA_ID__c WHERE ID_Number__c = :validId LIMIT 1];
        System.assertEquals(1, rec.Search_Count__c, 'New record should start with search count = 1');
    }

    @IsTest
    static void testSearchCountIncrement() {
        String validId = '8001015009087';
        insert new SA_ID__c(
            ID_Number__c = validId,
            Date_of_Birth__c = Date.newInstance(1980, 1, 1),
            Gender__c = 'Male',
            Is_Citizen__c = true,
            Search_Count__c = 5
        );
        Test.setMock(HttpCalloutMock.class, new MockCalendarificResponse());
        Test.startTest();
        SAIDController.processSAID(validId);
        Test.stopTest();

        SA_ID__c rec = [SELECT Search_Count__c FROM SA_ID__c WHERE ID_Number__c = :validId LIMIT 1];
        System.assertEquals(6, rec.Search_Count__c, 'Search count should increment from 5 to 6');
    }

    @IsTest
    static void testInvalidThrows() {
        String badId = '123';
        Test.startTest();
        try {
            SAIDController.processSAID(badId);
            System.assert(false, 'Expected AuraHandledException for invalid ID "' + badId + '"');
        } catch (AuraHandledException ex) {
            System.debug('Exception message: ' + ex.getMessage());
            System.assert(
                ex.getMessage().containsIgnoreCase('Invalid South African ID Number'),
                'Exception message should contain "Invalid South African ID Number", but got: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testDOB2001FemaleNonCitizen() {
        String id = '0101014001180';
        Test.setMock(HttpCalloutMock.class, new MockCalendarificResponse());
        Test.startTest();
        SAIDController.SAIDResult info = SAIDController.processSAID(id);
        Test.stopTest();

        System.assertEquals(Date.newInstance(2001, 1, 1), info.dob, 'DOB should parse as 2001-01-01');
        System.assertEquals('Female', info.gender, 'Gender should parse as Female');
        System.assertEquals(false, info.citizen, 'Citizen flag should be false for permanent resident');
        System.assertEquals(2001, info.birthYear, 'Birth year should be 2001');
        System.assert(!info.holidays.isEmpty(), 'Holidays should be returned');

        SA_ID__c rec = [
            SELECT Date_of_Birth__c, Gender__c, Is_Citizen__c, Search_Count__c
            FROM SA_ID__c
            WHERE ID_Number__c = :id
            LIMIT 1
        ];
        System.assertEquals(Date.newInstance(2001, 1, 1), rec.Date_of_Birth__c, 'Stored DOB should match');
        System.assertEquals('Female', rec.Gender__c, 'Stored Gender should match');
        System.assertEquals(false, rec.Is_Citizen__c, 'Stored citizen flag should match');
        System.assertEquals(1, rec.Search_Count__c, 'Search count should initialize to 1');
    }

    @IsTest
    static void testNullInput() {
        Test.startTest();
        try {
            SAIDController.processSAID(null);
            System.assert(false, 'Expected AuraHandledException for null ID');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().containsIgnoreCase('Invalid South African ID Number'),
                'Exception message should contain "Invalid South African ID Number", but got: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testNonNumericInput() {
        String badId = '8001015009abc';
        Test.startTest();
        try {
            SAIDController.processSAID(badId);
            System.assert(false, 'Expected AuraHandledException for non-numeric ID');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().containsIgnoreCase('Invalid South African ID Number'),
                'Exception message should contain "Invalid South African ID Number", but got: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testInvalidDate() {
        String invalidId = '8013015009082'; // Invalid month '13'
        Test.setMock(HttpCalloutMock.class, new MockCalendarificResponse());
        Test.startTest();
        try {
            SAIDController.processSAID(invalidId);
            System.assert(false, 'Expected exception for invalid date');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().containsIgnoreCase('Invalid date'),
                'Exception message should indicate invalid date, but got: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testPermissionDenied() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Read Only' LIMIT 1];
        User u = new User(
            Alias = 'testu',
            Email = 'testuser@cloudsmith.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Africa/Johannesburg',
            Username = 'testuser' + Math.random() + '@cloudsmith.com'
        );
        insert u;

        System.runAs(u) {
            Test.startTest();
            try {
                SAIDController.processSAID('8001015009087');
                System.assert(false, 'Expected AuraHandledException for permission denied');
            } catch (AuraHandledException ex) {
                System.assert(
                    ex.getMessage().containsIgnoreCase('Insufficient access'),
                    'Exception message should indicate insufficient access, but got: ' + ex.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testHolidayApiError() {
        String validId = '8001015009087';
        Test.setMock(HttpCalloutMock.class, new MockCalendarificErrorResponse());
        Test.startTest();
        try {
            SAIDController.processSAID(validId);
            System.assert(false, 'Expected AuraHandledException for API error');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().containsIgnoreCase('Holiday API error'),
                'Exception message should indicate API error, but got: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    private class MockCalendarificResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"response":{"holidays":[{"name":"New Year\'s Day","date":{"iso":"1980-01-01"}}]}}');
            return res;
        }
    }

    private class MockCalendarificErrorResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Invalid request"}');
            return res;
        }
    }
}