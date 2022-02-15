#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Sale.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( Env.Fields.Sale ) then
		makeItems ( Env );
	endif;
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	sqlItems ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Base = undefined as Sale
	|from Document.Sale as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package
	|from Document.Sale.Items as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure makeItems ( Env )

	recordset = Env.Registers.Items;
	fields = Env.Fields;
	date = fields.Date;
	warehouse = fields.Warehouse;
	for each row in Env.Items do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Warehouse = Warehouse;
		movement.Package = row.Package;
		movement.Series = row.Series;
		movement.Quantity = row.QuantityPkg;
	enddo; 
	
EndProcedure

Procedure flagRegisters ( Env )
	
	Env.Registers.Items.Write = true;
	
EndProcedure

#endregion

#endif