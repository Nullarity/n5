Procedure ShowList ( Control, Item, StandardProcessing ) export
	
	StandardProcessing = false;
	if ( not checkItem ( Item ) ) then
		return;
	endif;
	p = new Structure ( "Owner", Item );
	OpenForm ( "Catalog.Series.ChoiceForm", new Structure ( "Filter", p ), Control );

EndProcedure

Function checkItem ( Item )
	
	if ( TypeOf ( Item ) <> Type ( "CatalogRef.Items" )
		or not DF.Pick ( Item, "Series" ) ) then
		Output.SeriesDisabled ();
		return false;
	endif;
	return true;
	
EndFunction

Procedure ShowBalances ( Control, Item, Warehouse, StandardProcessing ) export
	
	StandardProcessing = false;
	if ( not checkItem ( Item ) ) then
		return;
	endif;
	p = new Structure ();
	p.Insert ( "Filter", new Structure ( "Owner", Item ) );
	p.Insert ( "Item", Item );
	p.Insert ( "Warehouse", Warehouse );
	OpenForm ( "Catalog.Series.Form.Balances", p, Control );

EndProcedure

Procedure SetExpirationDate ( Object ) export
	
	if ( Object.Produced <> Date ( 1, 1, 1 ) ) then
		Object.ExpirationDate = AddMonth ( Object.Produced, Object.ExpirationPeriod );
	endif;
	
EndProcedure

Procedure SetExpirationPeriod ( Object ) export
	
	empty = Date ( 1 ,1, 1 );
	produced = Object.Produced;
	expiration = Object.ExpirationDate;
	if ( produced <> empty
		and expiration <> empty ) then
		start = Year ( produced ) * 12 + Month ( produced );
		end = Year ( expiration ) * 12 + Month ( expiration );
		Object.ExpirationPeriod  = end - start;
	endIf;
	
EndProcedure