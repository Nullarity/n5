#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Env;

Procedure Exec () export
	
	init ();
	restore ();
	putToStorage ();
	
EndProcedure

Procedure init ()
	
	Company = Parameters.Company;
	Bound = Parameters.Bound;
	SQL.Init ( Env );
	
EndProcedure

Function restore ()
	
	SetPrivilegedMode ( true );
	selection = getDocuments ();
	invoiceType = Type ( "DocumentRef.Invoice" );
	transferType = Type ( "DocumentRef.Transfer" );
	writeOffType = Type ( "DocumentRef.WriteOff" );
	assemblingType = Type ( "DocumentRef.Assembling" );
	disassemblingType = Type ( "DocumentRef.Disassembling" );
	retailSalesType = Type ( "DocumentRef.RetailSales" );
	vendorReturnType = Type ( "DocumentRef.VendorReturn" );
	commissioningType = Type ( "DocumentRef.Commissioning" );
	intangibleCommissioningType = Type ( "DocumentRef.IntangibleAssetsCommissioning" );
	while ( selection.Next () ) do
		result = true;
		BeginTransaction ();
		document = selection.Recorder;
		type = TypeOf ( document );
		if ( type = invoiceType ) then
			result = postInvoice ( document );
		elsif ( type = transferType ) then
			result = postTransfer ( document );
		elsif ( type = writeOffType ) then
			result = postWriteOff ( document );
		elsif ( type = assemblingType ) then
			result = postAssembling ( document );
		elsif ( type = disassemblingType ) then
			result = postDisassembling ( document );
		elsif ( type = retailSalesType ) then
			result = postRetailSales ( document );
		elsif ( type = vendorReturnType ) then
			result = postVendorReturn ( document );
		elsif ( type = commissioningType ) then
			result = postCommissioning ( document );
		elsif ( type = commissioningType
			or type = intangibleCommissioningType ) then
			result = postCommissioning ( document );
		endif; 
		if ( result ) then
			CommitTransaction ();
		else
			RollbackTransaction ();
			return false;
		endif;
	enddo; 
	
EndFunction

Function getDocuments ()
	
	boundExists = ( Bound <> Date ( 1, 1, 1 ) );
	s = "
	|select RecordersTable.Recorder as Recorder
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

Function postTransfer ( Ref )
	
	env = Posting.GetParams ( Ref );
	env.RestoreCost = true;
	registers = new Structure ();
	registers.Insert ( "Cost", AccumulationRegisters.Cost.CreateRecordSet () );
	registers.Insert ( "General", AccountingRegisters.General.CreateRecordSet () );
	initRecords ( Ref, registers );
	env.Registers = registers;
	if ( not Documents.Transfer.Post ( env ) ) then
		return false;
	endif;
	writeRecords ( registers );
	return true;
	
EndFunction

Function postWriteOff ( Ref )
	
	env = Posting.GetParams ( Ref );
	env.RestoreCost = true;
	registers = new Structure ();
	registers.Insert ( "Cost", AccumulationRegisters.Cost.CreateRecordSet () );
	registers.Insert ( "General", AccountingRegisters.General.CreateRecordSet () );
	registers.Insert ( "Expenses", AccumulationRegisters.Expenses.CreateRecordSet () );
	initRecords ( Ref, registers );
	env.Registers = registers;
	if ( not Documents.WriteOff.Post ( env ) ) then
		return false;
	endif;
	writeRecords ( registers );
	return true;
	
EndFunction

Function postAssembling ( Ref )
	
	env = Posting.GetParams ( Ref );
	env.RestoreCost = true;
	registers = new Structure ();
	registers.Insert ( "Cost", AccumulationRegisters.Cost.CreateRecordSet () );
	registers.Insert ( "General", AccountingRegisters.General.CreateRecordSet () );
	initRecords ( Ref, registers );
	env.Registers = registers;
	if ( not Documents.Assembling.Post ( env ) ) then
		return false;
	endif;
	writeRecords ( registers );
	return true;
	
EndFunction

Function postDisassembling ( Ref )
	
	env = Posting.GetParams ( Ref );
	env.RestoreCost = true;
	registers = new Structure ();
	registers.Insert ( "Cost", AccumulationRegisters.Cost.CreateRecordSet () );
	registers.Insert ( "General", AccountingRegisters.General.CreateRecordSet () );
	initRecords ( Ref, registers );
	env.Registers = registers;
	if ( not Documents.Disassembling.Post ( env ) ) then
		return false;
	endif;
	writeRecords ( registers );
	return true;
	
EndFunction

Function postRetailSales ( Ref )
	
	env = Posting.GetParams ( Ref );
	env.RestoreCost = true;
	registers = new Structure ();
	registers.Insert ( "Cost", AccumulationRegisters.Cost.CreateRecordSet () );
	registers.Insert ( "Sales", AccumulationRegisters.Sales.CreateRecordSet () );
	registers.Insert ( "General", AccountingRegisters.General.CreateRecordSet () );
	registers.Insert ( "Expenses", AccumulationRegisters.Expenses.CreateRecordSet () );
	initRecords ( Ref, registers );
	env.Registers = registers;
	if ( not Documents.RetailSales.Post ( env ) ) then
		return false;
	endif;
	writeRecords ( registers );
	return true;
	
EndFunction

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

Function postCommissioning ( Ref )
	
	env = Posting.GetParams ( Ref );
	env.RestoreCost = true;
	registers = new Structure ();
	registers.Insert ( "Cost", AccumulationRegisters.Cost.CreateRecordSet () );
	registers.Insert ( "General", AccountingRegisters.General.CreateRecordSet () );
	initRecords ( Ref, registers );
	env.Registers = registers;
	if ( not RunCommissioning.Post ( env ) ) then
		return false;
	endif;
	writeRecords ( registers );
	return true;
	
EndFunction
	
Procedure putToStorage ()
	
	result = new Structure ();
	PutToTempStorage ( result, Parameters.Address );
	
EndProcedure

#endif