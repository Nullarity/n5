#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.SetupPrices.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	if ( simpleForm ( Parameters ) ) then
		StandardProcessing = false;
		SelectedForm = Metadata.Documents.SetupPrices.Forms.Simple;
	endif; 
	
EndProcedure

Function simpleForm ( Params )
	
	ref = undefined;
	if ( Params.Property ( "Key", ref )
		or Params.Property ( "CopyingValue", ref ) ) then
		return DF.Pick ( ref, "Simple" );
	else
		return false;
	endif;

EndFunction 

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makePrices ( Env );
	makePriceGroups ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )
	
	sqlFields ( Env );
	sqlPrices ( Env );
	sqlGroups ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure
 
Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as DateFrom, Documents.DateTo as DateTo
	|from Document.SetupPrices as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPrices ( Env )
	
	s = "
	|// #Prices
	|select Items.Item as Item, Items.Package as Package, Items.Feature as Feature, Items.PriceOrPercent as PriceOrPercent, Items.Prices as Prices, Organizations.Organization as Organization, Warehouses.Warehouse
	|from Document.SetupPrices.Items as Items
	|	//
	|	// TabularSection: Organizations
	|	//
	|	left join Document.SetupPrices.Organizations as Organizations
	|	on Organizations.Ref = &Ref
	|	and Items.Prices = Organizations.Prices
	|	//
	|	// TabularSection: Warehouses
	|	//
	|	left join Document.SetupPrices.Warehouses as Warehouses
	|	on Warehouses.Ref = &Ref
	|	and Items.Prices = Warehouses.Prices
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlGroups ( Env )
	
	s = "
	|// #Groups
	|select PriceGroups.PriceGroup as PriceGroup, PriceGroups.Percent as Percent, PriceGroups.Prices as Prices, Organizations.Organization as Organization, Warehouses.Warehouse
	|from Document.SetupPrices.PriceGroups as PriceGroups
	|	//
	|	// TabularSection: Organizations
	|	//
	|	left join Document.SetupPrices.Organizations as Organizations
	|	on Organizations.Ref = &Ref
	|	and PriceGroups.Prices = Organizations.Prices
	|	//
	|	// TabularSection: Warehouses
	|	//
	|	left join Document.SetupPrices.Warehouses as Warehouses
	|	on Warehouses.Ref = &Ref
	|	and PriceGroups.Prices = Warehouses.Prices
	|where PriceGroups.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure makePrices ( Env )

	recordset = Env.Registers.Prices;
	recordset.Write = true;
	fields = Env.Fields;
	dateStart = fields.DateFrom;
	dateEnd = fields.DateTo;
	for each row in Env.Prices do
		movement = recordset.Add ();
		movement.Period = dateStart;
		movement.DateTo = dateEnd;
		movement.Active = true;
		movement.Prices = row.Prices;
		movement.Item = row.Item;
		movement.Package = row.Package;
		movement.Feature = row.Feature;
		movement.Organization = row.Organization;
		movement.Warehouse = row.Warehouse;
		movement.PriceOrPercent = row.PriceOrPercent;
	enddo; 
	
EndProcedure

Procedure makePriceGroups ( Env )
	
	recordset = Env.Registers.PriceGroups;
	recordset.Write = true;
	fields = Env.Fields;
	dateStart = fields.DateFrom;
	dateEnd = fields.DateTo;
	for each row in Env.Groups do
		movement = recordset.Add ();
		movement.Period = dateStart;
		movement.DateTo = dateEnd;
		movement.Active = true;
		movement.Prices = row.Prices;
		movement.PriceGroup = row.PriceGroup;
		movement.Organization = row.Organization;
		movement.Warehouse = row.Warehouse;
		movement.Percent = row.Percent;
	enddo; 
	
EndProcedure

#endregion

Function Print ( Params, Env ) export
	
	setObject ( Params, Env );
	Print.OutputSchema ( Env.T, Params.TabDoc );
	Print.SetFooter ( Params.TabDoc );
	return true;
	
EndFunction

Procedure setObject ( Params, Env )
	
	Env.T.Parameters.Ref.Value = Params.Reference;
	
EndProcedure 

#endif