Procedure CheckParameters ( Form ) export
	
	var Date;
	var Company;
	
	p = Form.Parameters.FillingValues;
	p.Property ( "Date", Date );
	p.Property ( "Company", Company );
	if ( ValueIsFilled ( Date )
		and ValueIsFilled ( Company ) ) then
		return;
	endif;
	raise Output.OpeningBalancesError ();  
	
EndProcedure

Procedure FixDate ( Form ) export
	
	Form.Object.Date = DF.Pick ( Form.Parameters.CopyingValue, "Date" );

EndProcedure 