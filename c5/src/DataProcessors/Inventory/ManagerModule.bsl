#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params, Env );
	getData ( Params, Env );
	PutTable ( Params, Env );
	return true;
	
EndFunction

Procedure setPageSettings ( Params, Env )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getData ( Params, Env )
	
	setContext ( Params, Env );
	sqlFields ( Params, Env );	
	sqlItems ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SetPrivilegedMode ( true );
	SQL.Perform ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure setContext ( Params, Env ) 

	if ( TypeOf ( Params.Reference ) = Type ( "DocumentRef.Inventory" ) ) then
		Env.Insert ( "Table", "Inventory" );
	else
		Env.Insert ( "Table", "LVIInventory" );
	endif;
	
EndProcedure

Procedure sqlFields ( Params, Env )
	
	s = "
	|// @Fields
	|select Document.Date as Date, Document.Company.FullDescription as Company";
	if ( TypeOf ( Params.Reference ) = Type ( "DocumentRef.Inventory" ) ) then
		s = s + ", presentation ( Document.Warehouse )";
	else
		s = s + ", presentation ( Document.Department )";
	endif;
	s = s + " as Warehouse
	|from Document." + Env.Table + " as Document
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|// #Items
	|select Items.Item.Description as Item, Items.Item.Code as Code, Items.Item.Unit.Code as Unit,
	|	Items.Amount as Amount, Items.QuantityPkg as Quantity, Items.LineNumber as LineNumber, Items.Price as Price, 	
	|	Items.Series.Description as Series, Items.Feature.Description as Feature,
	|	Items.QuantityPkgBalance as QuantityBalance, Items.AmountBalance as AmountBalance,
	|	case when Items.QuantityPkgDifference > 0 then Items.QuantityPkgDifference else 0 end as QuantitySurplus,
	|	case when Items.QuantityPkgDifference < 0 then - Items.QuantityPkgDifference else 0 end as QuantityShortage,
	|	case when Items.AmountDifference > 0 then Items.AmountDifference else 0 end as AmountSurplus,
	|	case when Items.AmountDifference < 0 then - Items.AmountDifference else 0 end as AmountShortage
	|from Document." + Env.Table + ".Items as Items
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure PutTable ( Params, Env ) export

	t = Env.T;
	header1 = header1 ( Env );
	header2 = t.GetArea ( "Header2" );
	footer1 = t.GetArea ( "Footer1" );
	footer2 = t.GetArea ( "Footer2" );
	emptyRow = t.GetArea ( "EmptyRow" );
	page = 1;
	header1Params = header1.Parameters;
	header1Params.Page = 1;
	tabDoc = Params.TabDoc;
	tabDoc.Put ( header1 );
	table = Env.Items;
	totals = new Structure ();
	setTotals ( totals, table.Columns );
	pageTotals = getPageTotals ( totals );
	areas = new Array ();
	areas.Add ( footer1 );
	lastIndex = table.Count () - 1;
	pageRows = new Array ();
	footer1Params = footer1.Parameters;
	footer2Params = footer2.Parameters;
	for i = 0 to lastIndex do
		row = table [ i ];
		areaRow = getAreaRow ( t, row );
		fillTotals ( totals, row );
		pageRows.Add ( row );
		areas.Insert ( areas.UBound (), areaRow );
		if ( i = lastIndex ) then
			footer2Params.Fill ( totals );
			if ( tabDoc.CheckPut ( areas ) ) then
				if ( page > 1 ) then
					areas.Set ( 0, header2 );
				endif;
				areas.Set ( areas.UBound (), footer2 );
				if ( tabDoc.CheckPut ( areas ) ) then
					putAreas ( areas, tabDoc, emptyRow );
					return;
				else
					if ( page > 1 ) then
						areas.Set ( 0, header1 );
					endif;
					areas.Set ( areas.UBound (), footer1 );
				endif;
			endif;
			setPage ( page, header1Params );
			fillPage1Totals ( pageTotals, pageRows, footer1Params );
			putPage1 ( areas, tabDoc );
			putPage2 ( tabDoc, header2, areaRow, footer2 );
		elsif ( not tabDoc.CheckPut ( areas ) ) then
			setPage ( page, header1Params );
			fillPage1Totals ( pageTotals, pageRows, footer1Params );
			pageRows.Add ( row );
			putPage1 ( areas, tabDoc, emptyRow );
			areas = new Array ();
			areas.Add ( header1 );
			areas.Add ( areaRow );
			areas.Add ( footer1 );
		endif;
	enddo;

EndProcedure

Function header1 ( Env )
	
	area = Env.T.GetArea ( "Header1" );
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill ( fields );
	p.Date = Format ( fields.Date, "DLF=D" );
	return area;
	
EndFunction

Procedure setTotals ( Totals, Columns ) 

	typeNumber = Type ( "Number" );
	for each column in Columns do
		if ( column.ValueType.ContainsType ( typeNumber ) ) then
			Totals.Insert ( column.Name, 0 );
		endif;
	enddo;

EndProcedure

Function getPageTotals ( Totals ) 

	pageTotals = new Structure ();
	for each item in Totals do
		pageTotals.Insert ( item.Key, 0 );
	enddo;
	return pageTotals;

EndFunction

Function getAreaRow ( Template, Row )

	area = Template.GetArea ( "Row" );
	p = area.Parameters;
	p.Fill ( Row );
	p.Item = Print.FormatItem ( Row.Item, , Row.Feature, Row.Series );
	return area;

EndFunction

Procedure fillTotals ( Totals, Row ) 

	for each item in Totals do
		itemKey = item.Key;
		Totals [ itemKey ] = Totals [ itemKey ] + Row [ itemKey ];
	enddo;

EndProcedure

Procedure setPage ( Page, HeaderParams ) 

	HeaderParams.Page = Page;
	Page = Page + 1;

EndProcedure

Procedure putAreas ( Areas, TabDoc, EmptyRow ) 

	if ( EmptyRow <> undefined ) then
		while ( TabDoc.CheckPut ( Areas ) ) do
			Areas.Insert (  Areas.UBound (), EmptyRow );	
		enddo;
		Areas.Delete (  Areas.UBound () - 1 );
	endif;
	for each area in Areas do
		TabDoc.Put ( area );
	enddo;

EndProcedure

Procedure fillPage1Totals ( Totals, Rows, Params ) 

	Totals = getPageTotals ( Totals );
	Rows.Delete ( Rows.UBound () );
	for each row in Rows do
		fillTotals ( Totals, row );
	enddo;
	Params.Fill ( Totals );
	Rows = new Array ();

EndProcedure

Procedure putPage1 ( Areas, TabDoc, EmptyRow = undefined ) 

	Areas.Delete ( Areas.UBound () - 1 );
	putAreas ( Areas, TabDoc, EmptyRow );
	TabDoc.PutHorizontalPageBreak ();

EndProcedure

Procedure putPage2 ( TabDoc, Header, Row, Footer ) 

	TabDoc.Put ( Header );
	TabDoc.Put ( Row );
	TabDoc.Put ( Footer );

EndProcedure

#endif