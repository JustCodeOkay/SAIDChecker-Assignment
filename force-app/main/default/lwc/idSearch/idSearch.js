import { LightningElement, track } from 'lwc';

export default class IdSearch extends LightningElement {
  @track idNumber = '';
  @track errorMessage = '';
  @track isSearchDisabled = true;

  handleIdChange(event) {
    this.idNumber = event.target.value.trim();
    this.errorMessage = '';
    this.isSearchDisabled = true;

    // must be exactly 13 digits
    if (!/^\d{13}$/.test(this.idNumber)) {
      if (this.idNumber.length > 0) {
        this.errorMessage = 'ID must be exactly 13 digits';
      }
      return;
    }

    // Luhn check
    if (!this.luhnCheck(this.idNumber)) {
      this.errorMessage = 'Invalid SA ID (failed Luhn check)';
      return;
    }

    // all good!
    this.isSearchDisabled = false;
  }

  luhnCheck(id) {
    let sum = 0;
    // iterate from rightmost digit
    for (let i = 0; i < id.length; i++) {
      let digit = parseInt(id.charAt(12 - i), 10);
      // double every 2nd digit
      if (i % 2 === 1) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }
    return sum % 10 === 0;
  }

  handleSearch() {
    // at this point idNumber is valid
    // for now just log; in US3 we'll call Apex
    console.log('Searching for SA ID:', this.idNumber);
  }
}
