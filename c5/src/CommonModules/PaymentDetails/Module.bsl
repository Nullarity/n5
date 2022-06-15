Procedure Init ( Env ) export
	
	Env.Insert ( "PaymentDetails", new Structure ( "Option, Date" ) );
	Env.Insert ( "NewPaymentKeys", getTable () );
	Env.Insert ( "PaymentDetailsRecordset", InformationRegisters.PaymentDetails.CreateRecordSet () );
	
EndProcedure

Function getTable ()
	
	table = new ValueTable ();
	columns = table.Columns;
	columns.Add ( "Option", new TypeDescription ( "CatalogRef.PaymentOptions" ) );
	columns.Add ( "Date", new TypeDescription ( "Date" ) );
	columns.Add ( "PaymentKey", new TypeDescription ( "CatalogRef.PaymentKeys" ) );
	table.Indexes.Add ( "Option, Date" );
	return table;
	
EndFunction

Function GetKey ( Env ) export
	
	item = findKey ( Env );
	if ( item = undefined ) then
		item = fetchKey ( Env );
		if ( item = undefined ) then
			item = newKey ( Env );
		endif;
		addKey ( Env, item );
	endif; 
	return item;
	
EndFunction

Function findKey ( Env )
	
	search = Env.NewPaymentKeys.FindRows ( Env.PaymentDetails );
	if ( search.Count () = 0 ) then
		return undefined;
	endif; 
	return search [ 0 ].PaymentKey;
	
EndFunction

Function fetchKey ( Env )
	
	lock ( Env );
	q = new Query ( "
	|select Details.PaymentKey as Key
	|from InformationRegister.PaymentDetails as Details
	|where Details.Option = &Option
	|and Details.Date = &Date
	|" );
	fields = Env.PaymentDetails;
	q.SetParameter ( "Option", fields.Option );
	q.SetParameter ( "Date", fields.Date );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table.Key );
	
EndFunction

Procedure lock ( Env )
	
	fields = Env.PaymentDetails;
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.PaymentDetails" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Option", fields.Option );
	item.SetValue ( "Date", fields.Date );
	lock.Lock ();

EndProcedure
 
Function newKey ( Env )
	
	fields = Env.PaymentDetails;
	item = Catalogs.PaymentKeys.CreateItem ();
	FillPropertyValues ( item, fields );
	item.Write ();
	record = Env.PaymentDetailsRecordset.Add ();
	FillPropertyValues ( record, fields );
	record.PaymentKey = item.Ref;
	return item.Ref;
	
EndFunction
 
Procedure addKey ( Env, PaymentKey )
	
	row = Env.NewPaymentKeys.Add ();
	FillPropertyValues ( row, Env.PaymentDetails );
	row.PaymentKey = PaymentKey;
	
EndProcedure

Procedure Save ( Env ) export
	
	if ( Env.PaymentDetailsRecordset.Count () > 0 ) then
		Env.PaymentDetailsRecordset.Write ( false );
	endif; 
	
EndProcedure
