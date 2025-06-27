public with sharing class SAIDController {
    public class SAIDInfo {
        @AuraEnabled public Date dob;
        @AuraEnabled public String gender;
        @AuraEnabled public Boolean citizen;

        public SAIDInfo(Date dob, String gender, Boolean citizen) {
            this.dob = dob;
            this.gender = gender;
            this.citizen = citizen;
        }
    }

    private static Boolean isValidSAID(String idNumber) {
        if (String.isBlank(idNumber) || idNumber.length() != 13 || !idNumber.isNumeric()) {
            return false;
        }
        Integer sum = 0;
        for (Integer i = 0; i < 12; i++) {
            Integer digit = Integer.valueOf(idNumber.substring(i, i + 1));
            sum += Math.mod(i, 2) == 0 ? digit : (digit * 2 > 9 ? digit * 2 - 9 : digit * 2);
        }
        Integer checkDigit = Math.mod(10 - Math.mod(sum, 10), 10);
        return checkDigit == Integer.valueOf(idNumber.substring(12));
    }

    private static Date parseDOB(String idNumber) {
        String year = idNumber.substring(0, 2);
        String month = idNumber.substring(2, 4);
        String day = idNumber.substring(4, 6);
        Integer y = Integer.valueOf(year) > 24 ? Integer.valueOf('19' + year) : Integer.valueOf('20' + year);
        return Date.newInstance(y, Integer.valueOf(month), Integer.valueOf(day));
    }

    private static String parseGender(String idNumber) {
        Integer genderCode = Integer.valueOf(idNumber.substring(6, 10));
        return genderCode < 5000 ? 'Female' : 'Male';
    }

    private static Boolean parseCitizen(String idNumber) {
        return idNumber.substring(10, 11) == '0';
    }

    @AuraEnabled(cacheable=false)
    public static SAIDInfo processSAID(String idNumber) {
       
        if (!isValidSAID(idNumber)) {
            throw new AuraHandledException('Invalid South African ID Number');
        }

         if (!Schema.sObjectType.SA_ID__c.isAccessible()) {
            throw new AuraHandledException('Insufficient access to read SA ID records.');
        }

        Date dob = parseDOB(idNumber);
        String gender = parseGender(idNumber);
        Boolean citizen = parseCitizen(idNumber);

        List<SA_ID__c> existing = [
            SELECT Id, Search_Count__c
            FROM SA_ID__c
            WHERE ID_Number__c = :idNumber
            LIMIT 1
        ];

        if (existing.isEmpty()) {
            if (!Schema.sObjectType.SA_ID__c.isCreateable()) {
                throw new AuraHandledException('Insufficient access to create SA ID records.');
            }
            SA_ID__c rec = new SA_ID__c(
                ID_Number__c = idNumber,
                Date_of_Birth__c = dob,
                Gender__c = gender,
                Is_Citizen__c = citizen,
                Search_Count__c = 1
            );
            insert rec;
        } else {
            if (!Schema.sObjectType.SA_ID__c.isUpdateable()) {
                throw new AuraHandledException('Insufficient access to update SA ID records.');
            }
            SA_ID__c rec = existing[0];
            rec.Search_Count__c = (rec.Search_Count__c == null ? 1 : rec.Search_Count__c + 1);
            update rec;
        }

        return new SAIDInfo(dob, gender, citizen);
    }
} 