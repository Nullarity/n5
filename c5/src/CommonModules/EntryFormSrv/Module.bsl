
Function AccountsData ( val Dr, val Cr ) export
	
	data = new Structure ( "Dr, Cr" );
	data.Dr = GeneralAccounts.GetData ( Dr );
	data.Cr = GeneralAccounts.GetData ( Cr );
	return data;
	
EndFunction 

Function GetContract ( val Account, val Organization ) export
	
	data = DF.Values ( Organization, "Customer, Vendor, CustomerContract, VendorContract" );
	customerRequired = ( DF.Pick ( Account, "Type" ) = AccountType.Active );
	if ( customerRequired ) then
		if ( data.Customer ) then
			return data.CustomerContract;
		else
			return data.VendorContract;
		endif; 
	else
		if ( data.Vendor ) then
			return data.VendorContract;
		else
			return data.CustomerContract;
		endif; 
	endif; 
	
EndFunction 
