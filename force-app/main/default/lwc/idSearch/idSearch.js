import { LightningElement, track } from 'lwc';

export default class IdSearch extends LightningElement {
  @track idNumber = '';

  handleIdChange(event) {
    this.idNumber = event.target.value.trim();
  }

  handleSearch() {
    // For now just log to console
    console.log('Search clicked for ID:', this.idNumber);
    // Later: call Apex or REST
  }
}
