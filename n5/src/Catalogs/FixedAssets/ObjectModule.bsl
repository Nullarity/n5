#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	setInventoryNo ();
	if ( not checkInventoryNo () ) then
		Cancel = true;
		return;
	endif; 
	defaultName ();
	
EndProcedure

Procedure setInventoryNo ()
	
	if ( Inventory = "" ) then
		SetNewCode ();
		Inventory = Code;
	endif; 
	
EndProcedure 

Function checkInventoryNo ()
	
	existedItem = DF.GetOriginal ( Ref, "Inventory", Inventory );
	if ( existedItem = undefined ) then
		return true;
	endif; 
	Output.InventoryNoAlreadyExists ( new Structure ( "Code", DF.Pick ( existedItem, "Code" ) ), "Inventory" );
	return false;
	
EndFunction 

Procedure defaultName ()
	
	if ( Description = "" ) then
		Description = Output.WorkingDescription ();
	endif; 
	
EndProcedure 

#endif