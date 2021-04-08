#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params, Env );
	getData ( Params, Env );
	DataProcessors.Inventory.PutTable ( Params, Env );
	return true;
	
EndFunction

Procedure setPageSettings ( Params, Env )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Landscape;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getData ( Params, Env )
	
	setContext ( Params, Env );
	sqlFields ( Env );
	SetPrivilegedMode ( true );
	getFields ( Params, Env );
	sqlItems ( Params, Env );
	sqlItemsTable ( Env );
	getTable ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure setContext ( Params, Env ) 

	if ( TypeOf ( Params.Reference ) = Type ( "DocumentRef.AssetsInventory" ) ) then
		Env.Insert ( "Table", "AssetsInventory" );
	else
		Env.Insert ( "Table", "IntangibleAssetsInventory" );
	endif;
	
EndProcedure

Procedure sqlFields ( Env ) 

	s = "
	|// @Fields
	|select Document.Number as Number, Document.Date as Date, Document.Company.FullDescription as Company
	|from Document." + Env.Table + " as Document
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure

Procedure getFields ( Params, Env )
	
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure sqlItems ( Params, Env )
	
	s = "
	|// Items
	|select Items.Item as Asset, Items.LineNumber as LineNumber, Items.Amount as Amount, Items.AmountBalance as AmountBalance, 
	|	Items.AmountDifference as AmountDifference, Items.Availability as Availability, Items.Balance as Balance, Items.Difference as Difference";
	if ( TypeOf ( Params.Reference ) = Type ( "DocumentRef.AssetsInventory" ) ) then
		s = s + ", Items.Item.Inventory";
	else
		s = s + ", """"";
	endif;
	s = s + " as Inventory  
	|into Items
	|from Document." + Env.Table + ".Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item
	|;
	|// General
	|select Items.Asset as Asset, max ( General.AmountBalanceDr ) as AmountInitial
	|into General
	|from Items as Items
	|	//
	|	// General
	|	//
	|	inner join AccountingRegister.General.Balance ( &Boundary ) as General
	|	on General.ExtDimension1 = Items.Asset
	|	and General.Account = Items.Asset.Account
	|group by Items.Asset 
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItemsTable ( Env )
	
	s = "
	|// #Items
	|select presentation ( Items.Asset ) as Asset, Items.Inventory as Inventory, isnull ( General.AmountInitial, 0 ) as AmountInitial,
	|	case when Items.Availability then 1 else 0 end as Availability, Items.AmountBalance as AmountBalance,
	|	case when Items.Balance then 1 else 0 end as Balance, 
	|	case when Items.Difference > 0 then 1 else 0 end as DifferencePositive, 
	|	case when Items.Difference < 0 then 1 else 0 end as DifferenceNegative, 
	|	case when Items.AmountDifference > 0 then 1 else 0 end as AmountDifferencePositive, 
	|	case when Items.AmountDifference < 0 then 1 else 0 end as AmountDifferenceNegative, Items.LineNumber as LineNumber
	|from Items as Items
	|	//
	|	// General
	|	//
	|	left join General as General
	|	on General.Asset = Items.Asset
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTable ( Env ) 

	Env.Q.SetParameter ( "Boundary", new Boundary ( Env.Fields.Date, BoundaryType.Including ) );
	SQL.Perform ( Env );

EndProcedure

#endif