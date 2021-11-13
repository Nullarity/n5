
Function AccountsData ( val Dr, val Cr ) export
	
	data = new Structure ( "Dr, Cr" );
	data.Dr = GeneralAccounts.GetData ( Dr );
	data.Cr = GeneralAccounts.GetData ( Cr );
	return data;
	
EndFunction 

Function GetContract ( val Account, val Organization, val Company ) export
	
	data = DF.Values ( Organization, "Customer, Vendor, CustomerContract, VendorContract,
	|CustomerContract.Company, VendorContract.Company" );
	customerRequired = ( DF.Pick ( Account, "Type" ) = AccountType.Active );
	customerContract = ? ( data.CustomerContractCompany = Company, data.CustomerContract, undefined );
	vendorContract = ? ( data.VendorContractCompany = Company, data.VendorContract, undefined );
	if ( customerRequired ) then
		if ( data.Customer ) then
			return customerContract;
		else
			return vendorContract;
		endif; 
	else
		if ( data.Vendor ) then
			return vendorContract;
		else
			return customerContract;
		endif; 
	endif; 
	
EndFunction 
