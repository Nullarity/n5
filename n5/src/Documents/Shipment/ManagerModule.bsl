#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Shipment.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

Function ShowPrices () export

	return IsInRole ( "PricesInShipment" )
	or Logins.Admin ();
	
EndFunction 

Function CreateInvoice ( Object ) export
	
	if ( Object.Items.Total ( "Quantity" ) = 0 ) then
		return true;
	endif; 
	SetPrivilegedMode ( true );
	obj = Documents.Invoice.CreateDocument ();
	obj.Fill ( Object );
	obj.AdditionalProperties.Insert ( Enum.AdditionalPropertiesInteractive (), false );
	if ( not obj.CheckFilling () ) then
		Output.InvoiceCheckFillingErrors ();
		return false;
	endif;
	if ( TransactionActive () ) then
		obj.Write ( DocumentWriteMode.Posting );
	else
		try
			obj.Write ( DocumentWriteMode.Posting );
		except
			return false;
		endtry;
	endif; 
	SetPrivilegedMode ( false );
	return true;
	
EndFunction

Procedure CreateBackOrder ( Object ) export
	
	if ( Object.Items.Total ( "QuantityBack" ) = 0 ) then
		return;
	endif; 
	Documents.Shipment.Create ( Object );
	
EndProcedure
	
Procedure Create ( Object ) export
	
	obj = Documents.Shipment.CreateDocument ();
	obj.Fill ( Object );
	obj.Write ();
	r = InformationRegisters.ShipmentStatuses.CreateRecordManager ();
	r.Document = obj.Ref;
	r.Status = Enums.ShipmentPoints.New;
	r.Write ();
	
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
	
	Params.TabDoc.PageOrientation = PageOrientation.Portrait;
	Params.TabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	SetPrivilegedMode ( true );
	sqlPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure sqlPrintData ( Env )
	
	s = "
	|// @Fields
	|select Document.Number as DocumentNumber, Document.Date as DocumentDate, Document.Company.FullDescription as Company,
	|	Document.Company.PaymentAddress.Presentation as PaymentAddress, Document.Creator.Description as Salesman, Document.PO as PO,
	|	Document.Customer.FullDescription as Customer, Document.Customer.ShippingAddress.Presentation as ShippingAddress,
	|	case when Document.SalesOrder = value ( Document.SalesOrder.EmptyRef ) then """" else Document.SalesOrder.Number end as SalesOrderNumber,
	|	case when Document.SalesOrder = value ( Document.SalesOrder.EmptyRef ) then datetime ( 1, 1, 1 ) else Document.SalesOrder.Date end as SalesOrderDate,
	|	Document.DeliveryDate as DeliveryDate, Document.Memo as Memo
	|from Document.Shipment as Document
	|where Document.Ref = &Ref
	|;
	|// #Items
	|select Items.Item.Description as Item, Items.Item.Code as Code, Items.Feature.Description as Feature, 
	|	Items.QuantityPkgPlan as QuantityPkgPlan,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Package
	|from Document.Shipment.Items as Items
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
	
	header = Env.T.GetArea ( "Table" );
	area = Env.T.GetArea ( "Row" );
	header.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( header );
	table = Env.Items;
	accuracy = Application.Accuracy ();
	lineNumber = 0;
	for each row in table do
		lineNumber = lineNumber + 1;
		area.Parameters.Fill ( row );
		area.Parameters.LineNumber = lineNumber;
		area.Parameters.Item = Print.FormatItem ( row.Item, row.Package, row.Feature );
		area.Parameters.QuantityPkgPlan = Format ( row.QuantityPkgPlan, accuracy );
		Params.TabDoc.Put ( area );
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