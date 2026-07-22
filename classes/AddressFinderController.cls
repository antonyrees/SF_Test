/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class AddressFinderController {

    @AuraEnabled(cacheable=false)
    public static List<Address> getAddresses(String postcode) {

        List<Address> result = new List<Address>();

        // Remove any leading, trailing, and repeating white space characters 
        // and check still 3 or more characters left to allow for 'BH5 ' and 'S5 5'
        postcode = postcode.normalizeSpace();
        if (postcode.length() > 3) {
            return null;
        }

        // Remove any remaining spaces so we can do the search
        postcode = postcode.replace(' ','');

        // Outcodes are always at least 2 characters
        List<Asset> assetList = [
            SELECT Id, AddressStreet__c, AddressPostalCode__c, PropertyReference__c, PropertyStatusCode__c
            FROM Asset
            WHERE PropertyReference__c != null
                  AND PropertyStatusCode__c != 'X'
                  AND AddressPostalCode__c like :postCode.left(2) + '%'
                  ORDER BY AddressStreet__c
        ];

        if (assetList.size() > 0) {
            for (Asset foundAddress : assetList) {

                if (foundAddress.AddressPostalCode__c.replace(' ','').left(postcode.length()) == postcode) {
                    String formattedAddress = foundAddress.AddressStreet__c.trim().removeEnd(',') + ', ' + foundAddress.AddressPostalCode__c;
                    result.add(new Address().setPropertyReference(foundAddress.PropertyReference__c).setAddress(formattedAddress));
                }
            }
            if (result.size() > 0) {
                return result;
            }
        }

        return null;
    }

    @AuraEnabled(cacheable=false)
    public static List<Address> getPreAddresses(String propertyReference) {

        List<Address> result = new List<address>();

        // Get the selected Property
        List<Asset> assetList = [
            SELECT Id, AddressStreet__c, AddressPostalCode__c, PropertyReference__c, PropertyStatusCode__c
            FROM Asset
            WHERE PropertyReference__c = :propertyReference
                  AND PropertyStatusCode__c != 'X'
                  LIMIT 1
        ];

        if (assetList.isEmpty()) {
            return null;
        }

        String foundAssetPostalCode = assetList[0].AddressPostalCode__c.replace(' ','');

        assetList.addAll([
            SELECT Id, AddressStreet__c, AddressPostalCode__c, PropertyReference__c, PropertyStatusCode__c
            FROM Asset
            WHERE PropertyReference__c != null
                  AND PropertyReference__c != :propertyReference
                  AND PropertyStatusCode__c != 'X'
                  AND AddressPostalCode__c like :foundAssetPostalCode.left(2) + '%'
                  ORDER BY AddressStreet__c
        ]);
        

        for (Asset foundAddress : assetList) {
            if (foundAddress.AddressPostalCode__c.replace(' ','') == foundAssetPostalCode) {
                String formattedAddress = foundAddress.AddressStreet__c.trim().removeEnd(',') + ', ' + foundAddress.AddressPostalCode__c;
                result.add(new Address().setPropertyReference(foundAddress.PropertyReference__c).setAddress(formattedAddress));
            }
        }

        return result;
    }

    public class Address {
        @AuraEnabled
        public String propertyReference {get; set;}
        @AuraEnabled
        public String address {get; set;}

        public Address setPropertyReference(String reference) {
            this.propertyReference = reference;

            return this;
        }
        public Address setAddress(String address) {
            this.address = address;

            return this;
        }
    }
}