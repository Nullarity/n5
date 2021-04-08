#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getData ( Params, Env );
	putHeaderPage1 ( Params, Env );
	putMember ( Params, Env, true );
	putTable ( Params, Env );
	putHeaderPage2 ( Params, Env );
	putMember ( Params, Env, false );
	putFooterPage2 ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getData ( Params, Env )
	
	setContext ( Params, Env );
	sqlFields ( Env );
	SetPrivilegedMode ( true );
	getFields ( Params, Env );
	if ( TypeOf ( Params.Reference ) = Type ( "DocumentRef.Commissioning" ) ) then
		sqlItemsCommissioning ( Env );
	else
		sqlItemsAssetsTransfer ( Env );
		Env.Q.SetParameter ( "Boundary", new Boundary ( Env.Fields.Date, BoundaryType.Including ) );
	endif;
	sqlMembers ( Env );
	SQL.Perform ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure setContext ( Params, Env ) 

	if ( TypeOf ( Params.Reference ) = Type ( "DocumentRef.Commissioning" ) ) then
		Env.Insert ( "Table", "Commissioning" );
	else
		Env.Insert ( "Table", "AssetsTransfer" );
	endif;

EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company, Documents.Company.CodeFiscal as CodeFiscal,
	|	Contacts.Name as Accountant, presentation ( Documents.Head ) as Head, presentation ( Documents.HeadPosition ) as HeadPosition,
	|	presentation ( Documents.Approved ) as Approved, presentation ( Documents.ApprovedPosition ) as ApprovedPosition
	|from Document." + Env.Table + " as Documents
	|	//
	|	// Contacts
	|	//
	|	left join Catalog.Contacts as Contacts
	|	on Contacts.ContactType = value ( Catalog.ContactTypes.Accountant )
	|	and Contacts.Owner = Documents.Company
	|where Documents.Ref = &Ref 
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure getFields ( Params, Env )
	
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure sqlItemsCommissioning ( Env )
	
	s = "
	|// #Items
	|select Items.FixedAsset.Description as Asset, Items.FixedAsset.Inventory as Inventory, Items.UsefulLife as UsefulLife, 
	|	Items.LiquidationValue as LiquidationValue, Items.FixedAsset.AssetType.Code as AssetTypeCode, Items.FixedAsset.TaxCode as TaxCode,
	|	Items.FixedAsset.Produced as Produced, Items.FixedAsset.Certificate as Certificate, isnull ( General.Amount, 0 ) as InitialCost,
	|	( isnull ( General.Amount, 0 ) - Items.LiquidationValue ) / Items.UsefulLife as Amortization, Items.Ref.Date as ExploitationDate,
	|	Items.FixedAsset.AssetType.Name as AssetType, Items.LineNumber as LineNumber
	|from Document.Commissioning.Items as Items
	|	//
	|	// General
	|	//
	|	left join AccountingRegister.General.RecordsWithExtDimensions as General
	|	on Items.Item = General.ExtDimensionCr1
	|	and General.ExtDimensionDr1 = Items.FixedAsset
	|	and General.Recorder = &Ref
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlItemsAssetsTransfer ( Env )
	
	s = "
	|// #Items
	|select Items.Item.Description as Asset, Items.Item.Inventory as Inventory, Depreciation.UsefulLife as UsefulLife, 
	|	Depreciation.LiquidationValue as LiquidationValue, Items.Item.AssetType.Code as AssetTypeCode, Items.Item.TaxCode as TaxCode,
	|	Items.Item.Produced as Produced, Items.Item.Certificate as Certificate, isnull ( General.AmountBalanceDr, 0 ) as InitialCost,
	|	( isnull ( General.AmountBalanceDr, 0 ) - Depreciation.LiquidationValue ) / Depreciation.UsefulLife as Amortization, 
	|	Depreciation.Recorder.Date as ExploitationDate,	Items.Item.AssetType.Name as AssetType, Items.LineNumber as LineNumber
	|from Document.AssetsTransfer.Items as Items
	|	//
	|	// Depreciation
	|	//
	|	left join InformationRegister.Depreciation.SliceLast ( &Boundary ) as Depreciation
	|	on Depreciation.Asset = Items.Item
	|	//
	|	// General
	|	//
	|	left join AccountingRegister.General.Balance ( &Boundary ) as General
	|	on General.ExtDimension1 = Items.Item
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlMembers ( Env )
	
	s = "
	|// #Members
	|select presentation ( Members.Member ) as Member, presentation ( Members.Position ) as Position
	|from Document." + Env.Table + ".Members as Members
	|where Members.Ref = &Ref
	|order by Members.LineNumber
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure putHeaderPage1 ( Params, Env )
	
	area = Env.T.GetArea ( "HeaderPage1" );
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill ( fields );
	p.Date = Format ( fields.Date, "L=ro_RO; DLF=DD" );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putMember ( Params, Env, Title )
	
	table = Env.Members;
	if ( table.Count () = 0 ) then
		return;
	endif;
	t = Env.T;
	if ( Title ) then
		name1 = "MemberHeader1";
		name2 = "MemberHeader2";
	else
		name1 = "Member1";
		name2 = "Member2";
	endif;
	area1 = t.GetArea ( name1 );
	p1 = area1.Parameters;
	area2 = t.GetArea ( name2 );
	p2 = area2.Parameters;
	tabDoc = Params.TabDoc;
	first = true;
	for each row in table do
		if ( first ) then
			area = area1;
			p = p1;
			first = false
		else
			area = area2;
			p = p2;
		endif;
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

Procedure putTable ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	tabDoc.Put ( t.GetArea ( "TableHeader1" ) );
	area = t.GetArea ( "Row1" );
	table = Env.Items;
	p = area.Parameters;
	amount = 0;
	for each row in table do
		p.Fill ( row );
		tabDoc.Put ( area );
		amount = amount + row.InitialCost;
	enddo;
	tabDoc.Put ( t.GetArea ( "TableHeader2" ) );
	area = t.GetArea ( "Row2" );
	p = area.Parameters;
	for each row in table do
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo;
	tabDoc.Put ( t.GetArea ( "Footer" ) );        
	Env.Insert ( "Amount", amount );
	
EndProcedure

Procedure putHeaderPage2 ( Params, Env ) 

	tabDoc = Params.TabDoc;
	tabDoc.PutHorizontalPageBreak ();
	area = Env.T.GetArea ( "HeaderPage2" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Amount = Env.Amount;
	p.AmountWords = Conversion.AmountToWords ( p.Amount );
	tabDoc.Put ( area );

EndProcedure

Procedure putFooterPage2 ( Params, Env )
	
	area = Env.T.GetArea ( "FooterPage2" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

#endif