# SA ID Holiday Checker

A Lightning Web Component + Apex solution that lets South African users enter their 13-digit South African ID number, validates and decodes it, stores search counts in Salesforce, and fetches public/banking holidays for their birth year via the Calendarific API.

## Functional Overview

This tool allows end users to:

1. **Enter** their South African ID number into a Lightning page.  
2. **Validate** the ID client-side (13 digits + Luhn check).  
3. **Decode** the ID to extract date of birth, gender, and citizenship.  
4. **Persist** each valid search in a custom object, incrementing a search-count for repeat queries.  
5. **Fetch** and **display** all public/banking holidays for the birth year using the Calendarific Holiday API.



- **Client-side (LWC `idSearch`)**  
  - Renders input, validation, button enablement  
  - Calls `@salesforce/apex/SAIDController.processSAID`  
  - Displays decoded info + holiday list  

- **Server-side (Apex `SAIDController`)**  
  - **`processSAID`** (Aura-enabled):  
    1. Validate using Luhn algorithm  
    2. Decode DOB / gender / citizen  
    3. CRUD-guarded upsert into custom object `SA_ID__c`  
    4. Imperative callout via Named Credential + External Credential  
    5. Parse JSON, return wrapper `SAIDResult`  

- **Custom Object (`SA_ID__c`)**  
  - Fields:  
    - `ID_Number__c` (Text, 13, External ID)  
    - `Date_of_Birth__c` (Date)  
    - `Gender__c` (Picklist: Male, Female)  
    - `Is_Citizen__c` (Checkbox)  
    - `Search_Count__c` (Number)  

- **External Integration**  
  - **Named Credential** `Calendarific` pointing to `https://calendarific.com`  
  - **External Credential** for API-key injection as a query parameter  
  - **Custom Metadata** `Calendarific_Config__mdt` storing `API_Key__c`  

---

## Salesforce Components

| Component                | API Name                                 | Purpose                                        |
|--------------------------|------------------------------------------|------------------------------------------------|
| Custom Object            | `SA_ID__c`                               | Store ID details + search count               |
| Apex Class               | `SAIDController`                         | Main logic + holiday callout                  |
| Apex Test Class          | `SAIDControllerTest`                     | Unit tests + HTTP callout mock                |
| LWC                      | `idSearch`                               | UI, validation, Apex integration               |
| Custom Metadata Type     | `Calendarific_Config__mdt`               | Store Calendarific API key                     |
| Named Credential         | `Calendarific`                           | Base URL for callout                           |
| External Credential      | `Calendarific_External_Cred`             | Inject API key as `api_key` query parameter    |

---

## Prerequisites

- **Salesforce Org** (Developer Edition or Sandbox)  
- **Salesforce CLI** (sfdx or `sf`)  
- **VS Code** with Salesforce Extensions  
- **Calendarific API Key** (free signup at calendarific.com)  

---

## Setup & Deployment

### 1. Configure Named & External Credentials

1. **Named Credential**  
   - Setup → Named Credentials → New  
   - Label/API Name: `Calendarific`  
   - URL: `https://calendarific.com`  
   - Identity Type: **Named Principal**  
   - Authentication Protocol: **API Key Authentication (Query Parameter)**  
   - External Credential: select `Calendarific_External_Cred`  

2. **External Credential**  
   - Setup → External Credentials → New  
   - Label/API Name: `Calendarific_External_Cred`  
   - Principal Type: **Named Principal**  
   - Authentication Protocol: **API Key Authentication**  
   - Parameter Name: `api_key`  
   - Value: **\<Your Calendarific API key\>**  

### 2. Create Custom Metadata Record

1. Setup → Custom Metadata Types → **Calendarific Config** → Manage Records  
2. New Record:  
   - Label: `Default`  
   - API_Key__c: **\<Your Calendarific API key\>**  



