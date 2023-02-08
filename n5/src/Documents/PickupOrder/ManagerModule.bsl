#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.PickupOrder.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	putHeader ( Params, Env );
	putTable ( Params, Env );
	putFooter ( Params, Env );
	putTotals ( Params, Env );
	putMemo ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	sqlPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlPrintData ( Env )
	
	s = "
	|// @Fields
	|select Document.Number as DocumentNumber, Document.Date as DocumentDate, Document.Company.FullDescription as Company,
	|	Document.Required as Required, Document.Warehouse.Presentation as Warehouse, Document.Memo as Memo
	|from Document.PickupOrder as Document
	|where Document.Ref = &Ref
	|;
	|// #Items
	|select Items.Item.Description as Item, Items.Item.Code as Code, Items.Feature.Description as Feature, 
	|	Items.QuantityPkgPlan as QuantityPkgPlan,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Package
	|from Document.PickupOrder.Items as Items
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure
 
Procedure putTable ( Params, Env )
	
	t = Env.T;
	header = t.GetArea ( "Table" );
	area = t.GetArea ( "Row" );
	header.Parameters.Fill ( Env.Fields );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( header );
	table = Env.Items;
	accuracy = Application.Accuracy ();
	lineNumber = 0;
	p = area.Parameters;
	for each row in table do
		lineNumber = lineNumber + 1;
		p.Fill ( row );
		p.LineNumber = lineNumber;
		p.Item = Print.FormatItem ( row.Item, row.Package, row.Feature );
		p.QuantityPkgPlan = Format ( row.QuantityPkgPlan, accuracy );
		tabDoc.Put ( area );
	enddo; 
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putTotals ( Params, Env )
	
	accuracy = Application.Accuracy ();
	area = Env.T.GetArea ( "TotalQuantity" );
	area.Parameters.QuantityPkgPlan = Format ( Env.Items.Total ( "QuantityPkgPlan" ), accuracy );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putMemo ( Params, Env )
	
	area = Env.T.GetArea ( "Memo" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

#endregion

#endif