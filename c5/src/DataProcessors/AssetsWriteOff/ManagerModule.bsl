#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getData ( Params, Env );
	putHeader ( Params, Env );
	putTable ( Params, Env );
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
	setContext ( Params, Env );
	sqlFields ( Env );
	getFields ( Params, Env );
 	sqlData ( Env );
	getTables ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure setContext ( Params, Env ) 

	if ( TypeOf ( Params.Reference ) = Type ( "DocumentRef.AssetsWriteOff" ) ) then
		Env.Insert ( "Table", "AssetsWriteOff" );
	else
		Env.Insert ( "Table", "IntangibleAssetsWriteOff" );
	endif;

EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Document.Number as Number, Document.Date as Date, Document.Company.FullDescription as Company,
	|	presentation ( Document.Approved ) as Approved, presentation ( Document.ApprovedPosition ) as Position,
	|	presentation ( Document.Head ) as Head, presentation ( Document.HeadPosition ) as HeadPosition,
	|	Document.Memo as Memo
	|from Document." + Env.Table + " as Document
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Params, Env ) 

	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );

EndProcedure

Procedure sqlData ( Env )
	
	table = Env.Table;
	s = "
	|// Items
	|select Items.Item Item, Items.Item.Unit.Code as Unit, 1 as Quantity, min ( LineNumber ) as LineNumber
	|into Items
	|from Document." + table + ".Items as Items
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
	|;
	|// #Members
	|select presentation ( Members.Member ) as Member, presentation ( Members.Position ) as Position
	|from Document." + table + ".Members as Members
	|where Members.Ref = &Ref
	|order by Members.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env ) 

	Env.Q.SetParameter ( "Date", Env.Fields.Date );
	SQL.Perform ( Env );

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

#endif