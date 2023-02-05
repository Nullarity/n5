
&AtClient
async Procedure CommandProcessing ( Contract, CommandParameters )

	answer = await Output.SetDefaultContractConfirmation ();
	if ( answer = DialogReturnCode.Yes ) then
		setContract ( Contract );
	endif;

EndProcedure

&AtServer
Procedure setContract ( val Default )
	
	organization = undefined;
	data = DF.Values ( Default, "Owner, Customer, Vendor,
	|Owner.CustomerContract as CustomerContract, Owner.VendorContract as VendorContract" );
	if ( data.Customer ) then
		if ( data.CustomerContract = Default ) then
			return;
		endif;
		organization = data.Owner.GetObject ();
		organization.Lock ();
		organization.CustomerContract = Default;
	endif;
	if ( data.Vendor ) then
		if ( data.VendorContract <> Default ) then
			if ( organization = undefined ) then
				organization = data.Owner.GetObject ();
				organization.Lock ();
			endif;
			organization.VendorContract = Default;
		endif;
	endif;
	if ( organization <> undefined ) then
		organization.Write ();
	endif;
	
EndProcedure