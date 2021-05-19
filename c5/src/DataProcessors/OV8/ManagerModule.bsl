#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getData ( Params, Env );
	if ( Env.Items.Count () = 0 ) then
		OutputCont.PrintFormsTabularSectionIsEmpty ();
		return false;
	endif;
	header ( Params, Env );
	row ( Params, Env );
	backHeader ( Params, Env );
	back ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	tabDoc.PerPage = 1;
	
EndProcedure 

Procedure getData ( Params, Env )
	
	setContext ( Params, Env );
	sqlFields ( Env );
	sqlItems ( Env );
	sqlItemsTable ( Env );
	sqlMembers ( Env );
	SetPrivilegedMode ( true );
	getTables ( Params, Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure setContext ( Params, Env )

	if ( TypeOf ( Params.Reference ) = Type ( "DocumentRef.Startup" ) ) then
		table = "Startup";
		startup = true;
	else
		table = "LVIWriteOff";
		startup = false;
	endif;
	Env.Insert ( "Table", table );
	Env.Insert ( "Startup", startup );

EndProcedure

Procedure sqlFields ( Env )

	s = "
	|// @Fields
	|select Document.Number as Number, Document.Date as Date, Document.Company.FullDescription as Company,
	|	presentation ( Document.Head ) as Head, presentation ( Document.HeadPosition ) as HeadPosition,
	|	presentation ( Document.Approved ) as Approved, presentation ( Document.ApprovedPosition ) as ApprovedPosition,
	|	Document.Memo as Memo, Document.Company.CodeFiscal as CodeFiscal
	|from Document." + Env.Table + " as Document
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure

Procedure sqlItems ( Env )

	startup = Env.Startup;
	s = "
	|// Items
	|select Items.Item Item, Items.Feature as Feature, Items.Account as Account, Items.Series as Series,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Unit,
	|	case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit.Code else Items.Package.Code end as UnitCode,
	|	case when Items.Item.CountPackages then 1 else Items.Capacity end as UnitsInside,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package";
	if ( startup ) then
		s = s + ",
		|	case when Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) then Items.Ref.Warehouse else Items.Warehouse end as Warehouse,";
	else
		s = s + ",
		|	Items.Ref.Department as Department, Items.Employee.Individual as Employee, ";
	endif;
	s = s + "
	|	sum ( Items.QuantityPkg ) as Quantity, min ( LineNumber ) as LineNumber
	|into Items
	|from Document." + Env.Table + ".Items as Items
	|where Items.Ref = &Ref
	|group by Items.Item, Items.Feature, Items.Account, Items.Series, Items.Package, Items.Ref, Items.Capacity";	
	if ( startup ) then
		s = s + ", Items.Warehouse
		|";
	else
		s = s + ", Items.Employee
		|";
	endif;
	Env.Selection.Add ( s );

EndProcedure

Procedure sqlItemsTable ( Env )

	s = "
	|// #Items
	|select Items.LineNumber as LineNumber, Items.Item.Description as Item, Items.Item.Code as Code,
	|	Items.Unit as Unit, isnull ( Items.Quantity, 0 ) as Quantity, Items.UnitCode as UnitCode,
	|	isnull ( Cost.Price, 0 ) * Items.UnitsInside as Cost,
	|	isnull ( Cost.Price, 0 ) * Items.Quantity * Items.UnitsInside as Amount
	|from Items as Items";
	if ( Env.Startup ) then
		s = s + "
		|	//
		|	// Details
		|	//
		|	left join InformationRegister.ItemDetails as Details
		|	on Details.Item = Items.Item
		|	and Details.Package = Items.Package
		|	and Details.Feature = Items.Feature
		|	and Details.Series = Items.Series
		|	and Details.Warehouse = Items.Warehouse
		|	and Details.Account = Items.Account
		|	//
		|	// Cost
		|	//
		|	left join (
		|		select Cost.ItemKey as ItemKey, sum ( Cost.Amount ) / sum ( Cost.Quantity ) as Price
		|		from AccumulationRegister.Cost as Cost
		|		where Recorder = &Ref
		|		group by Cost.ItemKey
		|		having sum ( Cost.Quantity ) <> 0 ) as Cost
		|	on Cost.ItemKey = Details.ItemKey";
	else
		s = s + "
		|	//
		|	// Cost
		|	//
		|	left join (
		|		select Cost.AccountCr as AccountCr, Cost.ExtDimensionCr1 as ExtDimensionCr1, Cost.ExtDimensionCr2 as ExtDimensionCr2, 
		|			Cost.ExtDimensionCr3 as ExtDimensionCr3,
		|			case when sum ( Cost.QuantityCr ) = 0 then 0 else sum ( Cost.Amount ) / max ( Cost.QuantityCr ) end as Price
		|		from AccountingRegister.General.RecordsWithExtDimensions as Cost
		|		where Recorder = &Ref
		|		group by Cost.AccountCr, Cost.ExtDimensionCr1, Cost.ExtDimensionCr2, Cost.ExtDimensionCr3 ) as Cost
		|	on Cost.AccountCr = Items.Account
		|	and Cost.ExtDimensionCr1 = Items.Item
		|	and Cost.ExtDimensionCr2 = Items.Department
		|	and Cost.ExtDimensionCr3 = Items.Employee";
	endif;
	s = s + "
	|order by LineNumber
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

Procedure getTables ( Params, Env ) 

	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );

EndProcedure

Procedure header ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	fields = Env.Fields;
	p = area.Parameters;
	p.Fill ( fields );
	p.Date = Format ( fields.Date, "DLF=D" );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure row ( Params, Env )

	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "Row" );
	p = area.Parameters;
	for each row in Env.Items do
		p.Fill ( row );
		p.Price = ? ( row.Quantity = 0, 0, row.Amount / row.Quantity );
		tabDoc.Put ( area );
	enddo;
	tabDoc.Put ( t.GetArea ( "Footer" ) );
	tabDoc.PutHorizontalPageBreak ();
	
EndProcedure

Procedure backHeader ( Params, Env )

	area = Env.T.GetArea ( "BackHeader" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure back ( Params, Env ) 

	t = Env.T;
	tabDoc = Params.TabDoc;
	first = true;
	area1 = t.GetArea ( "MemberRowFirst" );
	p1 = area1.Parameters;
	area2 = t.GetArea ( "MemberRow" );
	p2 = area2.Parameters;
	for each row in Env.Members do
		if ( first ) then
			area = area1;
			p = p1;
			first = false;
		else
			area = area2;
			p = p2;
		endif;
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo;
	tabDoc.Put ( t.GetArea ( "BackFooter" ) );

EndProcedure

#endif