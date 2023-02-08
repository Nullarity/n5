&AtClient
Procedure Choose ( Item, Object, Row, Warehouse ) export
	
	filter = new Structure ();
	filter.Insert ( "Warehouse", Warehouse );
	date = Periods.GetBalanceDate ( Object );
	if ( date <> undefined
		and Object.Posted ) then
		date = date - 1;
	endif;
	filter.Insert ( "Date", date );
	filter.Insert ( "Item", Row.Item );
	filter.Insert ( "Feature", Row.Feature );
	filter.Insert ( "Series", Row.Series );
	OpenForm ( "Catalog.Ranges.Form.Balances", new Structure ( "Filter", filter ), Item );
	
EndProcedure

&AtServer
Procedure Check ( Object, Cancel, CheckedAttributes ) export
	
	if ( Object.Range.IsEmpty () ) then
		CheckedAttributes.Add ( "Number" );
	endif; 
	
EndProcedure 
