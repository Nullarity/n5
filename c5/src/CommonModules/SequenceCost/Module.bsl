	
Function Restore ( Bound, Company ) export
	
	SetPrivilegedMode ( true );
	selection = getDocuments ( Bound, Company );
	while ( selection.Next () ) do
		result = true;
		BeginTransaction ();
		if ( selection.DocumentType = "Invoice" ) then
			result = postInvoice ( selection.Recorder );
		elsif ( selection.DocumentType = "VendorReturn" ) then
			result = postVendorReturn ( selection.Recorder );
		//elsif ( selection.DocumentType = "Transfer" ) then
			//result = postTansfer ( selection.Recorder );
		endif; 
		if ( result ) then
			CommitTransaction ();
		else
			RollbackTransaction ();
			return false;
		endif;
	enddo; 
	
EndFunction

Function getDocuments ( Bound, Company )
	
	boundExists = ( Bound <> Date ( 1, 1, 1 ) );
	s = "
	|select RecordersTable.Recorder as Recorder,
	|	case when RecordersTable.Recorder refs Document.Invoice then ""Invoice""
	|	end as DocumentType
	|from ( select distinct CostRecorders.Period as Period, CostRecorders.Recorder as Recorder
	|		from Sequence.Cost as CostRecorders
	|			join Sequence.Cost.Boundaries as Boundaries
	|			on CostRecorders.Item = Boundaries.Item
	|			and Boundaries.Company = &Company
	|			and CostRecorders.Company = &Company
	|			and CostRecorders.PointInTime > Boundaries.PointInTime
	|";
	if ( boundExists ) then
		s = s + "
		|and CostRecorders.Period <= &Bound
		|";
	endif; 
	s = s + "
	|		union
	|		select distinct Cost.Period, Cost.Recorder
	|		from Sequence.Cost as Cost
	|		where Cost.Company = &Company
	|		and Cost.Item not in ( select distinct Item from Sequence.Cost.Boundaries )
	|";
	if ( boundExists ) then
		s = s + "
		|and Period <= &Bound
		|";
	endif; 
	s = s + " ) as RecordersTable
	|order by RecordersTable.Period, RecordersTable.Recorder.PointInTime
	|";
	q = new Query ( s );
	q.SetParameter ( "Bound", Bound );
	q.SetParameter ( "Company", Company );
	return q.Execute ().Select ();
	
EndFunction

Function postInvoice ( Ref )
	
	env = Posting.GetParams ( Ref );
	env.RestoreCost = true;
	registers = new Structure ();
	registers.Insert ( "Cost", AccumulationRegisters.Cost.CreateRecordSet () );
	registers.Insert ( "Sales", AccumulationRegisters.Sales.CreateRecordSet () );
	registers.Insert ( "General", AccountingRegisters.General.CreateRecordSet () );
	registers.Insert ( "Expenses", AccumulationRegisters.Expenses.CreateRecordSet () );
	initRecords ( Ref, registers );
	env.Registers = registers;
	if ( not Documents.Invoice.Post ( env ) ) then
		return false;
	endif;
	writeRecords ( registers );
	return true;
	
EndFunction

Procedure initRecords ( Ref, Registers )
	
	for each item in Registers do
		register = item.Value;
		register.Write = false;
		register.Filter.Recorder.Set ( Ref );
	enddo; 
	
EndProcedure
 
Procedure writeRecords ( Registers )
	
	for each item in Registers do
		register = item.Value;
		if ( register.Write ) then
			register.Write ();
		endif; 
	enddo; 
	
EndProcedure

Function postVendorReturn ( Ref )
	
	env = Posting.GetParams ( Ref );
	env.RestoreCost = true;
	registers = new Structure ();
	registers.Insert ( "Cost", AccumulationRegisters.Cost.CreateRecordSet () );
	registers.Insert ( "General", AccountingRegisters.General.CreateRecordSet () );
	initRecords ( Ref, registers );
	env.Registers = registers;
	if ( not Documents.VendorReturn.Post ( env ) ) then
		return false;
	endif;
	writeRecords ( registers );
	return true;
	
EndFunction

Procedure Rollback ( Document, Company, Timestamp, UnresolvedItems = undefined ) export
	
	SetPrivilegedMode ( true );
	table = findVictims ( Document, UnresolvedItems, Company, Timestamp );
	for each row in table do
		Sequences.Cost.SetBound ( ? ( row.ThrowDate = null, Timestamp, row.ThrowDate ), new Structure ( "Company, Item", Company, row.Item ) );
	enddo;
	
EndProcedure

Function findVictims ( Document, UnresolvedItems, Company, Timestamp )
	
	env = new Structure ();
	env.Insert ( "Company", Company );
	env.Insert ( "Document", Document );
	env.Insert ( "UnresolvedExists", ( UnresolvedItems <> undefined ) and ( UnresolvedItems.Count () > 0 ) );
	SQL.Init ( env );
	sqlItems ( Env );
	q = Env.Q;
	q.SetParameter ( "Ref", Document );
	q.SetParameter ( "Company", Company );
	q.SetParameter ( "Timestamp", Timestamp );
	if ( Env.UnresolvedExists ) then
		q.SetParameter ( "ItemsArray", UnresolvedItems );
	endif; 
	SQL.Perform ( Env );
	lockSequnce ( Env );
	sqlVictims ( Env );
	SQL.Perform ( Env );
	return Env.Victims;
	
EndFunction

Procedure sqlItems ( Env )
	
	document = Env.Document;
	name = document.Metadata ().Name;
	type = TypeOf ( document );
	if ( type = Type ( "DocumentRef.WriteOffForm" ) ) then
		s = "
		|select Documents.Item as Item
		|into AllItems
		|from Document.WriteOffForm as Documents
		|where Documents.Ref = &Ref
		|";
	else
		s = "
		|select Items.Item as Item
		|into AllItems
		|from Document." + name + ".Items as Items
		|where Items.Ref = &Ref
		|union
		|select Items.Item
		|from AccumulationRegister.Items as Items
		|where Items.Recorder = &Ref
		|";
		if ( type = Type ( "DocumentRef.Assembling" )
			or type = Type ( "DocumentRef.Disassembling" ) ) then
			s = s + "
			|union
			|select Document.Set
			|from Document." + name + " as Document
			|where Items.Ref = &Ref
			|";
		endif; 
		s = s + "
		|index by Item
		|";
	endif;
	if ( Env.UnresolvedExists ) then
		s = s + ";
		|select Items.Ref as Item
		|into UnresolvedItems
		|from Catalog.Items as Items
		|where Items.Ref in (&ItemsArray)
		|index by Items.Ref
		|;
		|select Items.Item as Item
		|into ItemsWithoutUnresolvedItems
		|from AllItems as Items
		|where Items.Item not in ( select distinct Item from UnresolvedItems )
		|";
	endif; 
	s = s + ";
	|// #Items
	|select Items.Item as Item
	|from AllItems as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure lockSequnce ( Env )
	
	lockData = new DataLock ();
	lockItem = lockData.Add ( "Sequence.Cost");
	lockItem.Mode = DataLockMode.Exclusive;
	lockItem.DataSource = Env.Items;
	lockItem.UseFromDataSource ( "Item", "Item" );
	//@skip-warning
	lockItem.SetValue ( "Company", Env.Company );
	lockData.Lock ();
	
EndProcedure

Procedure sqlVictims ( Env )
	
	s = "
	|//
	|// Select Items to set Boundary = &Timestamp
	|//
	|// #Victims
	|select Items.Item as Item, null as ThrowDate
	|from " + ? ( Env.UnresolvedExists, "ItemsWithoutUnresolvedItems", "AllItems" ) + " as Items
	|	//
	|	// Boundaries
	|	//
	|	join Sequence.Cost.Boundaries as Boundaries
	|	on Boundaries.Company = &Company
	|	and Boundaries.Item = Items.Item
	|	and Boundaries.PointInTime > &Timestamp
	|";
	if ( Env.UnresolvedExists ) then
		s = s + "
		|union
		|//
		|// Select Items to set Boundary < &Timestamp
		|//
		|select SequenceCost.Item, case when ( Boundaries.PointInTime is null ) then datetime ( 1, 1, 1 ) else SequenceCost.Period end
		|from ( select Cost.Item as Item, max ( Cost.Period ) as Period
		|		from Sequence.Cost as Cost
		|		where Cost.PointInTime < &Timestamp
		|		and Cost.Company = &Company
		|		and Cost.Item in ( select Item from UnresolvedItems )
		|		group by Cost.Item ) as SequenceCost
		|		//
		|		// Actual bounds
		|		//
		|		left join Sequence.Cost.Boundaries as Boundaries
		|		on Boundaries.Company = &Company
		|		and Boundaries.Item = SequenceCost.Item
		|		and Boundaries.PointInTime >= &Timestamp
		|";
	endif; 
	Env.Selection.Add ( s );
	
EndProcedure 
