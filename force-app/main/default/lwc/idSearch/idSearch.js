import { LightningElement, track } from 'lwc';
import processSAID from '@salesforce/apex/SAIDController.processSAID';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class IdSearch extends LightningElement {
    @track idNumber = '';
    @track errorMessage = '';
    @track isSearchDisabled = true;
    @track dob = '';
    @track gender = '';
    @track citizen = false;
    @track holidays = [];
    @track showResult = false;

    handleIdChange(event) {
        this.idNumber = event.target.value.trim();
        this.errorMessage = '';
        this.isSearchDisabled = true;
        this.showResult = false;

        if (!/^\d{13}$/.test(this.idNumber)) {
            if (this.idNumber.length > 0) {
                this.errorMessage = 'ID must be exactly 13 digits';
            }
            return;
        }

        if (!this.luhnCheck(this.idNumber)) {
            this.errorMessage = 'Invalid SA ID (failed Luhn check)';
            return;
        }

        this.isSearchDisabled = false;
    }

    luhnCheck(id) {
        let sum = 0;
        for (let i = 0; i < 12; i++) {
            let digit = parseInt(id[i]);
            sum += i % 2 === 0 ? digit : (digit * 2 > 9 ? digit * 2 - 9 : digit * 2);
        }
        let checkDigit = (10 - (sum % 10)) % 10;
        return checkDigit === parseInt(id[12]);
    }

    async handleSearch() {
        try {
            const result = await processSAID({ idNumber: this.idNumber });
            this.dob = result.dob;
            this.gender = result.gender;
            this.citizen = result.citizen;
            this.holidays = result.holidays;
            this.showResult = true;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'ID processed and holidays fetched successfully',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.errorMessage = error.body?.message || 'Error processing ID or fetching holidays';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.errorMessage,
                    variant: 'error'
                })
            );
        }
    }
}