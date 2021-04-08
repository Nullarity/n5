#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getData ( Params, Env );
	putHeader ( Params, Env );
	putMembers ( Params, Env );
	putRow ( Params, Env );
	putTotal ( Params, Env );
	putMembers ( Params, Env );
	putFooter ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getData ( Params, Env )
	
	SetPrivilegedMode ( true );
	sqlData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure sqlData ( Env )
	
	s = "
	|// @Fields
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company, Documents.Company.CodeFiscal as CodeFiscal,
	|	Contacts.Name as Accountant, presentation ( Documents.Approved ) as Approved, presentation ( Documents.ApprovedPosition ) as ApprovedPosition, 
	|	presentation ( Documents.Head ) as Head, presentation ( Documents.HeadPosition ) as HeadPosition 
	|from Document.IntangibleAssetsCommissioning as Documents
	|	//
	|	// Contacts
	|	//
	|	left join Catalog.Contacts as Contacts
	|	on Contacts.ContactType = value ( Catalog.ContactTypes.Accountant )
	|	and Contacts.Owner = Documents.Company
	|where Documents.Ref = &Ref 
	|;
	|// #Items
	|select Items.IntangibleAsset.Description as Item, Items.UsefulLife as UsefulLife, isnull ( General.Amount, 0 ) as Cost,
	|	case when Items.UsefulLife = 0 then 0 else isnull ( General.Amount, 0 ) / Items.UsefulLife end as Amortization, Items.Starting as Starting, 
	|	Items.LineNumber as LineNumber, dateadd ( Items.Starting, month, Items.UsefulLife ) as WriteOffDate
	|from Document.IntangibleAssetsCommissioning.Items as Items
	|	//
	|	// General
	|	//
	|	left join AccountingRegister.General.RecordsWithExtDimensions as General
	|	on General.ExtDimensionCr1 = Items.Item
	|	and General.ExtDimensionDr1 = Items.IntangibleAsset
	|	and General.Recorder = &Ref
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|;
	|// #Members
	|select presentation ( Members.Member ) as Member, presentation ( Members.Position ) as Position, Members.LineNumber as LineNumber
	|from Document.IntangibleAssetsCommissioning.Members as Members
	|where Members.Ref = &Ref
	|order by Members.LineNumber
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putMembers ( Params, Env )
	
	table = Env.Members;
	if ( table.Count () = 0 ) then
		return;
	endif;
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "Members" );
	p = area.Parameters;
	for each row in table do
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

Procedure putRow ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	tabDoc.Put ( t.GetArea ( "TableHeader" ) );
	area = t.GetArea ( "Row" );
	p = area.Parameters;
	for each row in Env.Items do
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

Procedure putTotal ( Params, Env ) 

	area = Env.T.GetArea ( "Total" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	items = Env.Items;
	p.Amortization = items.Total ( "Amortization" );
	cost = items.Total ( "Cost" );
	p.Cost = cost;
	s = Conversion.AmountToWords ( cost );
	s = StrReplace ( s, "Noăzeci", "Nouăzeci" );
	p.CostInWords = StrReplace ( s, "o sută", "una sută" ); 
	Params.TabDoc.Put ( area );

EndProcedure

Procedure putFooter ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

#endif