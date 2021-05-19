#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.AssetsWriteOff.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
EndProcedure
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	if ( Params.Name = "MF3" ) then
		putHeader1Page1 ( Params, Env );
		putMemberRow ( Params, Env, 1 );
		putRowPage1 ( Params, Env );
		putFooterPage1 ( Params, Env );
		putHeader1Page2 ( Params, Env );
		putMemberRow ( Params, Env, 2 );
		putFooterPage2 ( Params, Env );
	else
		putHeader ( Params, Env );
		putTable ( Params, Env );
		putFooter ( Params, Env );
	endif;
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	SetPrivilegedMode ( true );
	ref = Params.Reference;
	if ( Params.Name = "MF3" ) then
		sqlDataMF3 ( Env );
	else
		sqlPrintData ( Env );
	endif;
	sqlMembers ( Env );
	q = Env.Q;
	q.SetParameter ( "Ref", ref );
	q.SetParameter ( "Date", ref.Date );
	SQL.Perform ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure sqlPrintData ( Env )
	
	s = "
	|// @Fields
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company,
	|	presentation ( Documents.Approved ) as Approved, presentation ( Documents.ApprovedPosition ) as Position,
	|	presentation ( Documents.Head ) as Head, presentation ( Documents.HeadPosition ) as HeadPosition,
	|	Documents.Memo as Memo
	|from Document.AssetsWriteOff as Documents
	|where Documents.Ref = &Ref
	|;
	|select Items.Item Item, Items.Item.Unit.Code as Unit, 1 as Quantity, min ( LineNumber ) as LineNumber
	|into Items
	|from Document.AssetsWriteOff.Items as Items
	|where Items.Ref = &Ref
	|group by Items.Item, Items.Item.Unit.Code	
	|;
	|// #Items
	|select Items.LineNumber as LineNumber, Items.Item.Description as Item, Items.Item.Code as Code,
	|	Items.Unit as Unit, Items.Quantity as Quantity, General.AmountBalanceDr as Cost, General.AmountBalanceDr as Amount
	|from Items as Items
	|	//
	|	// General
	|	//
	|	left join AccountingRegister.General.Balance ( &Date ) as General
	|	on Items.Item = General.ExtDimension1
	|	and Items.Item.Account = General.Account
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
	Print.Repeat ( tabDoc );
	table = Env.Items;
	accuracy = Application.Accuracy ();
	p = area.Parameters;
	for each row in table do
		p.Fill ( row );
		p.Quantity = Format ( row.Quantity, accuracy );
		tabDoc.Put ( area );
	enddo;
	Env.Insert ( "AmountTotal", table.Total ( "Amount" ) );
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	putTotals ( Params, Env );
	tabDoc = Params.TabDoc;
	startStaing = tabDoc.TableHeight + 1;
	putHead ( Params, Env );
	putMembers ( Params, Env );
	tabDoc.Area ( startStaing, , tabDoc.TableHeight ).StayWithNext = true;
	
EndProcedure

Procedure putTotals ( Params, Env )
	
	area = Env.T.GetArea ( "Totals" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Amount = Env.AmountTotal;
	Params.TabDoc.Put ( area );        
	
EndProcedure 

Procedure putHead ( Params, Env )
	
	area = Env.T.GetArea ( "Head" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.AmountInWords = NumberInWords ( Env.AmountTotal, ? ( Params.SelectedLanguage = "en", "L = en_EN", "L = ru_RU" ) );
	Params.TabDoc.Put ( area );        
	
EndProcedure 

Procedure putMembers ( Params, Env )
	
	members = Env.Members;
	if ( members.Count () = 0 ) then
		return;
	endif; 
	tabDoc = Params.TabDoc;
	t = Env.T;
	tabDoc.Put ( t.GetArea ( "MembersHeader" ) );
	area = t.GetArea ( "MembersRow" );
	p = area.Parameters;
	for each row in members do
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo; 
	
EndProcedure

Procedure sqlDataMF3 ( Env )
	
	s = "
	|// @Fields
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company, Documents.Company.CodeFiscal as CodeFiscal,
	|	Contacts.Name as Accountant, presentation ( Documents.Approved ) as Approved, presentation ( Documents.ApprovedPosition ) as ApprovedPosition, 
	|	presentation ( Documents.Head ) as Head, presentation ( Documents.HeadPosition ) as HeadPosition
	|from Document.AssetsWriteOff as Documents
	|	//
	|	// Contacts
	|	//
	|	left join Catalog.Contacts as Contacts
	|	on Contacts.ContactType = value ( Catalog.ContactTypes.Accountant )
	|	and Contacts.Owner = Documents.Company
	|where Documents.Ref = &Ref
	|;
	|// Items
	|select Items.Item as Asset, Items.Item.Inventory as Inventory, Items.LineNumber as LineNumber
	|into Items
	|from Document.AssetsWriteOff.Items as Items
	|where Items.Ref = &Ref
	|;
	|// General
	|select Items.Asset as Asset, General.Account as Account, General.AmountBalanceDr as InitialCost, General.AmountBalanceCr as AccumulatedAmortization
	|into General
	|from Items as Items
	|	//
	|	// General
	|	//
	|	inner join AccountingRegister.General.Balance ( &Date ) as General
	|	on Items.Asset = General.ExtDimension1
	|	and ( Items.Asset.Account = General.Account or Items.Asset.DepreciationAccount = General.Account )
	|;
	|// GeneralGrouped
	|select General.Asset as Asset, sum ( General.InitialCost ) as InitialCost, sum ( General.AccumulatedAmortization ) as AccumulatedAmortization
	|into GeneralGrouped
	|from General
	|group by General.Asset
	|;
	|// #Items
	|select Items.Asset.Description as Asset, Items.Inventory as Inventory, Depreciation.UsefulLife as UsefulLife, 
	|	isnull ( General.InitialCost, 0 ) as InitialCost, isnull ( General.AccumulatedAmortization, 0 ) as AccumulatedAmortization,
	|	( isnull ( General.InitialCost, 0 ) - Depreciation.LiquidationValue ) / Depreciation.UsefulLife as Amortization, 
	|	Depreciation.Recorder.Date as ExploitationDate
	|from Items as Items
	|	//
	|	// Depreciation
	|	//
	|	left join InformationRegister.Depreciation.SliceLast ( &Date ) as Depreciation
	|	on Items.Asset = Depreciation.Asset
	|	//
	|	// General
	|	//
	|	left join GeneralGrouped as General
	|	on Items.Asset = General.Asset
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlMembers ( Env ) 

	s = "
	|// #Members
	|select presentation ( Members.Member ) as Member, presentation ( Members.Position ) as Position
	|from Document.AssetsWriteOff.Members as Members
	|where Members.Ref = &Ref
	|order by Members.LineNumber
	|";
	Env.Selection.Add ( s );    

EndProcedure

Procedure putHeader1Page1 ( Params, Env ) 

	area = Env.T.GetArea ( "Header1Page1" );
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill ( fields );
	p.Date = Format ( fields.Date, "L=ro_RO; DLF=DD" );
	Params.TabDoc.Put ( area );

EndProcedure

Procedure putMemberRow ( Params, Env, Page )
	
	members = Env.Members;
	if ( members.Count () = 0 ) then
		return;
	endif;
	t = Env.T;
	if ( Page = 1 ) then
		areaFirst = t.GetArea ( "MemberRow1First" );
		area = t.GetArea ( "MemberRow1" );
	else
		areaFirst = t.GetArea ( "MemberRow2First" );
		area = t.GetArea ( "MemberRow2" );
	endif;
	tabDoc = Params.TabDoc;
	first = true;
	for each row in members do
		if ( first ) then
			areaToPut = areaFirst;
			first = false;
		else
			areaToPut = area;
		endif;
		areaToPut.Parameters.Fill ( row );
		tabDoc.Put ( areaToPut );
	enddo;
	
EndProcedure

Procedure putRowPage1 ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	tabDoc.Put ( t.GetArea ( "Header2Page1" ) );
	area = t.GetArea ( "RowPage1" );
	p = area.Parameters;
	table = Env.Items;
	line = 1;
	initialCost = 0;
	accumulatedAmortization = 0;
	amortization = 0;
	for each row in table do
		p.Fill ( row );
		p.LineNumber = line;
		line = line + 1;
		tabDoc.Put ( area );
		initialCost = initialCost + row.InitialCost;
		accumulatedAmortization = accumulatedAmortization + row.AccumulatedAmortization;
		amortization = amortization + row.Amortization;
	enddo;
	Env.Insert ( "InitialCost", initialCost );
	Env.Insert ( "AccumulatedAmortization", accumulatedAmortization );
	Env.Insert ( "Amortization", amortization );
	
EndProcedure

Procedure putFooterPage1 ( Params, Env ) 

	area = Env.T.GetArea ( "FooterPage1" );
	p = area.Parameters;
	p.Fill ( Env );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( area );
	tabDoc.PutHorizontalPageBreak ();

EndProcedure

Procedure putHeader1Page2 ( Params, Env ) 

	area = Env.T.GetArea ( "Header1Page2" );
	p = area.Parameters;
	p.Head = Env.Fields.Head;
	cost = Env.InitialCost;
	amount = Conversion.AmountToWords ( cost );
	amount = StrReplace ( amount, "Noăzeci", "Nouăzeci" );
	amount = StrReplace ( amount, "o sută",	"una sută" );
	p.SumInWordsAndNumbers = Format ( cost, "NFD=2" ) + "  (" + amount + ")"; 
	Params.TabDoc.Put ( area );

EndProcedure

Procedure putFooterPage2 ( Params, Env ) 

	area = Env.T.GetArea ( "FooterPage2" );
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill ( fields );
	Params.TabDoc.Put ( area );

EndProcedure

#endregion

#endif
