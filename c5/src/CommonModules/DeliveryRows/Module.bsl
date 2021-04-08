&AtServer
Procedure SetByVendorContract ( Object ) export
	
	setByContract ( Object, "VendorDelivery" );
	
EndProcedure
 
&AtServer
Procedure SetByCustomerContract ( Object ) export
	
	setByContract ( Object, "CustomerDelivery" );
	
EndProcedure

&AtServer
Procedure setByContract ( Object, DelayOfDeliveryField )
	
	delayOfDelivery = DF.Pick ( Object.Contract, DelayOfDeliveryField );
	if ( delayOfDelivery > 0 ) then
		setDeliveryDateForTable ( Object.Date, delayOfDelivery, Object.Items );
		setDeliveryDateForTable ( Object.Date, delayOfDelivery, Object.Services );
	endif;
	
EndProcedure

&AtServer
Procedure setDeliveryDateForTable ( DocumentDate, DelayOfDelivery, Table )
	
	startDate = BegOfDay ( DocumentDate );
	for each row in Table do
		row.DeliveryDate = startDate + delayOfDelivery * 86400;
	enddo; 
	
EndProcedure

&AtClient
Procedure Set ( Table ) export
	
	deliveryDate = Date ( 1, 1, 1 );
	ShowInputDate ( new NotifyDescription ( "SetDeliveryDate", ThisObject, Table ), deliveryDate, Output.StrDate (), DateFractions.DateTime );
	
EndProcedure

&AtClient
Procedure SetDeliveryDate ( Date, Table ) export
	
	if ( Date = undefined ) then
		return;
	endif; 
	for each row in Table do
		row.DeliveryDate = date;
	enddo; 
		
EndProcedure 

&AtServer
Function Check ( Object, TableName ) export
	
	error = false;
	startDate = BegOfDay ( Object.Date );
	for each row in Object [ TableName ] do
		if ( not Periods.Ok ( startDate, row.DeliveryDate ) ) then
			Output.DeliveryDateError ( , Output.Row ( TableName, row.LineNumber, "DeliveryDate" ) );
			error = true;
		endif; 
	enddo; 
	return not error;
	
EndFunction

&AtServer
Function GetCustomerDeliveryDate ( DocumentDate, Contract, Cache = undefined ) export
	
	return getOrganizationDeliveryDate ( DocumentDate, Contract, "CustomerDelivery", Cache );
	
EndFunction 

&AtServer
Function GetVendorDeliveryDate ( DocumentDate, Contract, Cache = undefined ) export
	
	return getOrganizationDeliveryDate ( DocumentDate, Contract, "VendorDelivery", Cache );
	
EndFunction 

&AtServer
Function getOrganizationDeliveryDate ( DocumentDate, Contract, Field, Cache )
	
	delayOfDelivery = undefined;
	if ( Cache <> undefined ) then
		delayOfDelivery = Cache [ Contract ];
	endif;
	if ( delayOfDelivery = undefined ) then
		delayOfDelivery = DF.Pick ( Contract, Field );
		if ( Cache <> undefined ) then
			Cache [ Contract ] = delayOfDelivery;
		endif; 
	endif; 
	return DocumentDate + delayOfDelivery * 86400;
	
EndFunction 
