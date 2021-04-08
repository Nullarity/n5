#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var DataReader;

Procedure Exec () export
	
	initDataReader ();
	read ();
	complete ();

EndProcedure

Procedure initDataReader ()
	
	s = "
	|select Invoices.Amount as Amount, Invoices.Customer.Description as Customer, Invoices.LoadingPoint as LoadingPoint,
	|	Invoices.Memo as Memo, Invoices.Ref as Invoice, Invoices.Number as CurrentNumber
	|from Document.InvoiceRecord as Invoices
	|where Invoices.Ref = &Ref
	|";
	DataReader = new Query ( s );
	
EndProcedure

Procedure read ()
	
	var seria, id, notes;
	
	SetPrivilegedMode ( true );
	xml = new XMLReader ();
	xml.SetString ( GetStringFromBinaryData ( GetFromTempStorage ( Parameters.Address ) ) );
	lastNode = undefined;	
	while ( xml.Read () ) do
		node = xml.Name;
		type = xml.NodeType;
		if ( type = XMLNodeType.Text ) then
			if ( lastNode = "Seria" ) then 
				seria = xml.Value;
			elsif ( lastNode = "Number" ) then 
				id = xml.Value;
			elsif ( lastNode = "Notes" ) then
				notes = xml.Value;
			endif;
		elsif ( type = XMLNodeType.EndElement
			and node = "Document" ) then
			data = readData ( notes );
			if ( data = undefined ) then
				continue;
			endif;
			row = Invoices.Add ();
			FillPropertyValues ( row, data );
			row.Series = seria;
			row.FormNumber = Conversion.StringToNumber ( id );
			row.Number = id;
			row.Load = ( id <> undefined ) and ( data.CurrentNumber = "" );
		endif;
		lastNode = node;
	enddo;	

EndProcedure

Function readData ( UID )
	
	try
		id = new UUID ( UID );
	except
		return undefined;
	endtry;
	ref = Documents.InvoiceRecord.GetRef ( id );
	DataReader.SetParameter ( "Ref", ref );
	table = DataReader.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );

EndFunction

Procedure complete ()
	
	PutToTempStorage ( Invoices.Unload (), Parameters.Address );
	
EndProcedure 

#endif