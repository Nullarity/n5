&AtServer
Function Features () export
	
	return GetFunctionalOption ( "Features" );
	
EndFunction
 
&AtServer
Function Series () export
	
	return GetFunctionalOption ( "Series" );
	
EndFunction
 
&AtServer
Function Packages () export
	
	return GetFunctionalOption ( "Packages" );
	
EndFunction

&AtServer
Function Barcodes () export
	
	return GetFunctionalOption ( "Barcodes" );
	
EndFunction

&AtServer
Function Discounts ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "Discounts", p );
	
EndFunction

&AtServer
Function VendorDiscounts ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "VendorDiscounts", p );
	
EndFunction

&AtServer
Function DeliveryInTable ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "DeliveryInTable", p );
	
EndFunction

&AtServer
Function WarehousesInTable ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "WarehousesInTable", p );
	
EndFunction
 
&AtServer
Function PricesInTable ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "PricesInTable", p );
	
EndFunction

&AtServer
Function CostOnline ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "CostOnline", p );
	
EndFunction

&AtServer
Function BalanceControl ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "BalanceControl", p );
	
EndFunction

&AtServer
Function SalesOrdersInTable ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "SalesOrdersInTable", p );
	
EndFunction

&AtServer
Function PurchaseOrdersInTable ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "PurchaseOrdersInTable", p );
	
EndFunction

&AtServer
Function ProductionOrdersInTable ( Company ) export
	
	p = new Structure ( "Company", Company );
	return GetFunctionalOption ( "ProductionOrdersInTable", p );
	
EndFunction

&AtServer
Procedure Company ( Form, Company ) export
	
	Form.Parameters.FunctionalOptionsParameters.Insert ( "Company", Company );

EndProcedure 

&AtServer
Procedure Organization ( Form, Organization ) export
	
	params = Form.Parameters;
	if ( params.Property ( "FunctionalOptionsParameters" ) ) then
		params.FunctionalOptionsParameters.Insert ( "Organization", Organization );
	endif;

EndProcedure 

&AtServer
Procedure ApplyOrganization ( Form, Organization ) export
	
	p = new Structure ();
	p.Insert ( "Organization", Organization );
	Form.SetFormFunctionalOptionParameters ( p );
	
EndProcedure

&AtClient
Procedure ApplyCompany ( Form ) export
	
	object = Form.Object;
	p = new Structure ();
	p.Insert ( "Company", object.Company );
	Form.SetFormFunctionalOptionParameters ( p );
	
EndProcedure

&AtServer
Procedure SetAccuracy ( Form, Fields, Format = true, EditFormat = true ) export
	
	accuracy = Application.Accuracy ();
	items = Form.Items;
	for each field in Conversion.StringToArray ( Fields ) do
		item = items [ field ];
		if ( Format = true ) then
			item.Format = accuracy;
		endif; 
		if ( EditFormat = true ) then
			item.EditFormat = accuracy;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function Production () export
	
	return GetFunctionalOption ( "Production" );
	
EndFunction

&AtServer
Function Russian () export
	
	p = new Structure ( "User", SessionParameters.User );
	return GetFunctionalOption ( "Russian", p );
	
EndFunction
