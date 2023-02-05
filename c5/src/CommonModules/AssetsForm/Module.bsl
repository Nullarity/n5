
Function CheckItems ( Object ) export
	
	doubles = Collections.GetDoubles ( Object.Items, "Item" );
	if ( doubles.Count () > 0 ) then
		for each row in doubles do
			Output.DoubleAssets ( , Output.Row ( "Items", row.LineNumber, "Item" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 

Function CheckDepreciation ( Object, Table ) export
	
	error = false;
	empty = Date ( 1, 1, 1 );
	begin = BegOfMonth ( Object.Date );
	ref = Object.Ref;
	introduction = introduction ( Object );
	for each row in Object [ Table ] do
		if ( row.Charge ) then
			starting = row.Starting;
			line = row.LineNumber;
			if ( not introduction
				and ( starting = empty
				or starting < begin ) ) then
				error = true;
				Output.InvalidAssetsAmortizationDate ( , Output.Row ( Table, line, "Starting" ), ref );
			endif; 
			if ( row.Expenses.IsEmpty () ) then
				error = true;
				Output.EmptyAssetsAmortizationExpenses ( , Output.Row ( Table, line, "Expenses" ), ref );
			endif;
		endif; 
	enddo; 
	return not error;

EndFunction 

Function introduction ( Object )

	type = TypeOf ( Object.Ref );
	return type = Type ( "DocumentRef.AssetsBalances" )
	or type = Type ( "DocumentRef.IntangibleAssetsBalances" );
	
EndFunction

Function CheckItemsFields ( Object ) export
	
	error = false;
	msg = new Structure ( "Field" );
	ref = Object.Ref;
	attributes = ref.Metadata ().TabularSections.Items.Attributes;
	account = attributes.Account.Presentation ();
	item = attributes.Item.Presentation ();
	for each row in Object.Items do
		if ( row.Posted ) then
			continue;
		endif;
		line = row.LineNumber;
		if ( row.Account.IsEmpty () ) then
			msg.Field = account;
			Output.FieldIsEmpty ( msg, Output.Row ( "Items", line, "Account" ), ref );
			error = true;
		endif; 
		if ( row.Item.IsEmpty () ) then
			msg.Field = item;
			Output.FieldIsEmpty ( msg, Output.Row ( "Items", line, "Item" ), ref );
			error = true;
		endif; 
	enddo; 
	return not error;
	
EndFunction 
