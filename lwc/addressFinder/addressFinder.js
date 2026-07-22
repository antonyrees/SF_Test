import { LightningElement, track, api } from 'lwc';

import getAddresses from '@salesforce/apex/AddressFinderController.getAddresses';
import getPreAddresses from '@salesforce/apex/AddressFinderController.getPreAddresses';

export default class AddressFinder extends LightningElement {

    @api selectedPropertyReference;
    @api hasError;

    @track addresses;

    postCodeNotFoundError = false;
    addressNotSelectedError = false;
    showSpinner = false;
    postcode;
    timerId;

    @api get validity() {
        return {'valid' : !this.hasError};;
    }

    @api reportValidity() {

        this.hasError=false;

        if (!this.postcode) {
            this.hasError=true;
        }
        if (this.addresses) {
            this.postCodeNotFoundError = false;
            if (this.selectedPropertyReference) {
                this.addressNotSelectedError = false;
            } else {
                this.addressNotSelectedError = true;
                this.hasError=true;
            }
        } else {
            this.postCodeNotFoundError = true;
            this.hasError=true;
        }
    }

    @api checkValidity() {
        return !this.hasError;
    }

    // If the selectedpropertyReference has been populated when the component is created then we should populate the postcode and address
    connectedCallback() {
        if (this.selectedPropertyReference) {
            getPreAddresses({propertyReference : this.selectedPropertyReference})
            .then(result => {
                for (let address of result) {
                    if (address.propertyReference == this.selectedPropertyReference) {
                        address.selected = true;
                        this.postcode = /[^,]*$/.exec(address.address)[0].trim();
                    }
                }
                this.addresses = result;
                if (this.addresses) {
                    this.postCodeNotFoundError = false;
                } else {
                    this.postCodeNotFoundError = true;
                }           
            })
            .catch(error => {
                console.log(error);
            });
        }
    }

    findAddresses() {
        window.clearTimeout(this.timerId);
        this.postcode = this.template.querySelector('[data-id="postcode"]').value;

        if (this.postcode && this.postcode.trim().length > 0 && this.postcode.trimStart().length > 3) {
            this.timerId = setTimeout(()=>{
                this.getAddresses()
            }, 1000)
        } else {
            this.addresses = null;
            this.postCodeNotFoundError = false;
        }
    }

    handleAddressSelected(event) {
        let selectedKey = event.currentTarget.selectedOptions[0].value;

        if (selectedKey) {
            this.selectedPropertyReference = selectedKey;
        } else {
            this.selectedPropertyReference = null;
        }

        this.reportValidity();
    }

    getAddresses() {
        this.showSpinner = true;
        getAddresses({postcode : this.postcode})
        .then(result => {
            addresses = result;
            if (addresses && addresses.length > 0) {
                this.postCodeNotFoundError = false;
            } else {
                this.postCodeNotFoundError = true;
            }           
        })
        .catch(error => {
            console.log(error);
        })
        .finally(() => {
            this.showSpinner = false;
        });
    }


}