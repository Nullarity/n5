
Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Company" );
	p.Insert ( "Dim1" );
	p.Insert ( "Dim2" );
	p.Insert ( "Dim3" );
	p.Insert ( "Level" );
	return p;
	
EndFunction 

Procedure Choose ( Params, Item, StandardProcessing ) export
	
	value = Params [ "Dim" + Params.Level ];
	valueType = TypeOf ( value );
	if ( valueType = Type ( "CatalogRef.Departments" ) ) then
		redefined = chooseDepartment ( Params, Item, value );
	elsif ( valueType = Type ( "CatalogRef.Contracts" ) ) then
		redefined = chooseContract ( Params, Item, value );
	elsif ( valueType = Type ( "CatalogRef.BankAccounts" ) ) then
		redefined = chooseBankAccount ( Params, Item, value );
	elsif ( valueType = Type ( "CatalogRef.Warehouses" ) ) then
		redefined = chooseWarehouse ( Params, Item, value );
	else
		return;
	endif; 
	StandardProcessing = not redefined;
	
EndProcedure 

Function chooseDepartment ( Params, Item, Value )
	
	p = formParams ();
	p.CurrentRow = Value;
	p.Filter.Insert ( "Owner", Params.Company );
	OpenForm ( "Catalog.Departments.ChoiceForm", p, Item );
	return true;
	
EndFunction

Function formParams ()
	
	return new Structure ( "Filter, CurrentRow", new Structure () );
	
EndFunction 

Function chooseContract ( Params, Item, Value )
	
	p = formParams ();
	p.CurrentRow = Value;
	filter = p.Filter;
	setFilter ( filter, "Owner", findValue ( Params, Type ( "CatalogRef.Organizations" ) ) );
	setFilter ( filter, "Company", Params.Company );
	OpenForm ( "Catalog.Contracts.ChoiceForm", p, Item );
	return true;
	
EndFunction

Function findValue ( Params, Type )
	
	if ( Type = TypeOf ( Params.Dim1 ) ) then
		return Params.Dim1;
	elsif ( Type = TypeOf ( Params.Dim2 ) ) then
		return Params.Dim2;
	elsif ( Type = TypeOf ( Params.Dim3 ) ) then
		return Params.Dim3;
	endif; 
	
EndFunction 

Procedure setFilter ( Filter, Name, Value )

	if ( ValueIsFilled ( Value ) ) then
		Filter.Insert ( Name, Value );
	endif;
	
EndProcedure 

Function chooseBankAccount ( Params, Item, Value )
	
	p = formParams ();
	p.CurrentRow = Value;
	setFilter ( p.Filter, "Owner", Params.Company );
	OpenForm ( "Catalog.BankAccounts.ChoiceForm", p, Item );
	return true;
	
EndFunction

Function chooseWarehouse ( Params, Item, Value )
	
	p = formParams ();
	p.CurrentRow = Value;
	setFilter ( p.Filter, "Owner", Params.Company );
	OpenForm ( "Catalog.Warehouses.ChoiceForm", p, Item );
	return true;
	
EndFunction
