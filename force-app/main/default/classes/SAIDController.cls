public with sharing class SAIDController {
    public class Holiday {
        @AuraEnabled public String name;
        @AuraEnabled public String date;
        public Holiday(String n, String d) {
            this.name = n;
            this.date = d;
        }
    }

    public class SAIDResultParams {
        public Date dob;
        public String gender;
        public Boolean citizen;
        public Integer birthYear;
        public List<Holiday> holidays;
    }

    public class SAIDResult {
        @AuraEnabled public Date dob;
        @AuraEnabled public String gender;
        @AuraEnabled public Boolean citizen;
        @AuraEnabled public Integer birthYear;
        @AuraEnabled public List<Holiday> holidays;
        public SAIDResult(SAIDResultParams params) {
            this.dob = params.dob;
            this.gender = params.gender;
            this.citizen = params.citizen;
            this.birthYear = params.birthYear;
            this.holidays = params.holidays;
        }
    }
    private static Boolean isValidSaid(String id) {
        if (String.isBlank(id) || id.length() != 13 || !id.isNumeric()) {
            return false;
        }
        Integer sum = 0;
        for (Integer i = 0; i < 12; i++) {
            Integer d = Integer.valueOf(id.substring(i, i + 1));
            sum += (Math.mod(i, 2) == 0) ? d : (d * 2 > 9 ? d * 2 - 9 : d * 2);
        }
        Integer check = Math.mod(10 - Math.mod(sum, 10), 10);
        return check == Integer.valueOf(id.substring(12));
    }

    private static Date parseDob(String id) {
        try {
            Integer yy = Integer.valueOf(id.substring(0, 2));
            Integer mm = Integer.valueOf(id.substring(2, 4));
            Integer dd = Integer.valueOf(id.substring(4, 6));
            if (mm < 1 || mm > 12 || dd < 1 || dd > 31) {
                throw new IllegalArgumentException('Invalid date in ID number');
            }
            Integer cutoff = Math.mod(Date.today().year(), 100);
            Integer fullYear = (yy <= cutoff ? 2000 + yy : 1900 + yy);
            return Date.newInstance(fullYear, mm, dd);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid date in ID number: ' + e.getMessage());
        }
    }

    private static String parseGender(String id) {
        Integer seq = Integer.valueOf(id.substring(6, 10));
        return (seq < 5000 ? 'Female' : 'Male');
    }

    private static Boolean parseCitizen(String id) {
        return id.substring(10, 11) == '0';
    }

    @AuraEnabled(cacheable=false)
    public static SAIDResult processSAID(String idNumber) {
        if (!isValidSaid(idNumber)) {
            throw new AuraHandledException('Invalid South African ID Number');
        }

        if (!Schema.sObjectType.SA_ID__c.isAccessible()) {
            throw new AuraHandledException('Insufficient access to read SA_ID__c');
        }

        Date dob = parseDob(idNumber);
        String gender = parseGender(idNumber);
        Boolean citizen = parseCitizen(idNumber);
        Integer birthYear = dob.year();

        List<SA_ID__c> existing = [
            SELECT Id, Search_Count__c
            FROM SA_ID__c
            WHERE ID_Number__c = :idNumber
            LIMIT 1
        ];
        if (existing.isEmpty()) {
            if (!Schema.sObjectType.SA_ID__c.isCreateable()) {
                throw new AuraHandledException('Insufficient access to create SA_ID__c');
            }
            insert new SA_ID__c(
                ID_Number__c = idNumber,
                Date_of_Birth__c = dob,
                Gender__c = gender,
                Is_Citizen__c = citizen,
                Search_Count__c = 1
            );
        } else {
            if (!Schema.sObjectType.SA_ID__c.isUpdateable()) {
                throw new AuraHandledException('Insufficient access to update SA_ID__c');
            }
            SA_ID__c rec = existing[0];
            rec.Search_Count__c = (rec.Search_Count__c == null ? 1 : rec.Search_Count__c + 1);
            update rec;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Calendarific/api/v2/holidays?country=ZA&year=' + birthYear);
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Holiday API error: ' + res.getBody());
        }

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> raw = (List<Object>) ((Map<String, Object>) payload.get('response')).get('holidays');
        List<Holiday> holidays = new List<Holiday>();
        for (Object o : raw) {
            Map<String, Object> h = (Map<String, Object>) o;
            String name = (String) h.get('name');
            String date = (String) ((Map<String, Object>) h.get('date')).get('iso');
            holidays.add(new Holiday(name, date));
        }

        return new SAIDResult(dob, gender, citizen, birthYear, holidays);
    }
}