#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.IntangibleAssetsCommissioning.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getData ( Params, Env );
	putHeader ( Params, Env );
	putRow ( Params, Env );
	putFooter ( Params, Env );
	putMembers ( Params, Env );
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
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company, presentation ( Documents.Approved ) as Approved, 
	|	presentation ( Documents.ApprovedPosition ) as ApprovedPosition, presentation ( Documents.Head ) as Head, 
	|	presentation ( Documents.HeadPosition ) as HeadPosition
	|from Document.IntangibleAssetsCommissioning as Documents
	|where Documents.Ref = &Ref 
	|;
	|// #Items
	|select presentation ( Items.IntangibleAsset ) as Item, Items.UsefulLife as UsefulLife, isnull ( General.Amount, 0 ) as Amount, Items.LineNumber as Line,
	|	Items.Method as Method, Items.Starting as Starting
	|from Document.IntangibleAssetsCommissioning.Items as Items
	|	//
	|	// General
	|	//
	|	left join AccountingRegister.General.RecordsWithExtDimensions as General
	|	on General.ExtDimensionDr1 = Items.IntangibleAsset
	|	and General.Recorder = &Ref
	|where Items.Ref = &Ref
	|and not Items.Posted
	|union all
	|select presentation ( Items.IntangibleAsset ), Items.UsefulLife, isnull ( General.Amount, 0 ), Items.LineNumber, Items.Method, Items.Starting
	|from Document.IntangibleAssetsCommissioning.Items as Items
	|	//
	|	// General
	|	//
	|	left join AccountingRegister.General.RecordsWithExtDimensions as General
	|	on General.ExtDimensionDr1 = Items.IntangibleAsset
	|	and General.Recorder = Items.Ref.Base
	|where Items.Ref = &Ref
	|and Items.Posted
	|order by Items.LineNumber
	|;
	|// #Members
	|select distinct presentation ( Members.Member ) as Member, presentation ( Members.Position ) as Position, Members.LineNumber as Line
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

Procedure putRow ( Params, Env )
	
	tabDoc = Params.TabDoc;
	area = Env.T.GetArea ( "Row" );
	p = area.Parameters;
	for each row in Env.Items do
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	items = Env.Items;
	amount = items.Total ( "Amount" );
	p.Amount = amount;
	p.AmountInWords = NumberInWords ( amount, ? ( Params.SelectedLanguage= "en", "L = en_EN", "L = ru_RU" ) );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putMembers ( Params, Env )
	
	table = Env.Members;
	if ( table.Count () = 0 ) then
		return;
	endif;
	t = Env.T;
	tabDoc = Params.TabDoc;
	tabDoc.Put ( t.GetArea ( "MembersHeader" ) );
	area = t.GetArea ( "MembersRow" );
	p = area.Parameters;
	for each row in table do
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

#endregion

#endif