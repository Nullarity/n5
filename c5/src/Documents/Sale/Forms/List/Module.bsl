
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	filterByWarehouse ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	settings = Logins.Settings ( "Warehouse" );
	WarehouseFilter = settings.Warehouse;
	
EndProcedure

&AtServer
Procedure filterByWarehouse ()
	
	set = not WarehouseFilter.IsEmpty ();
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, set );
	DC.ChangeFilter ( Accounting, "Warehouse", WarehouseFilter, set );
	Appearance.Apply ( ThisObject, "WarehouseFilter" );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Warehouse AccountingWarehouse show empty ( WarehouseFilter );
	|Creator AccountingCreator show empty ( CreatorFilter );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure CreatorFilterOnChange ( Item )
	
	filterByCreator ();

EndProcedure

&AtServer
Procedure filterByCreator ()
	
	set = not CreatorFilter.IsEmpty ();
	DC.ChangeFilter ( List, "Creator", CreatorFilter, set );
	DC.ChangeFilter ( Accounting, "Creator", CreatorFilter, set );
	Appearance.Apply ( ThisObject, "CreatorFilter" );
	
EndProcedure

// *****************************************
// *********** Accounting

&AtClient
Procedure Calculate ( Command )
	
	OpenForm ( "DataProcessor.RetailSales.Form", , Items.Accounting );

EndProcedure

&AtClient
Procedure AccountingChoiceProcessing ( Item, ValueSelected, StandardProcessing )
	
	go ( ValueSelected );
	Progress.Open ( UUID, ThisObject, new NotifyDescription ( "Complete", ThisObject ) );
	
EndProcedure

&AtServer
Procedure go ( val Data )

	p = DataProcessors.RetailSales.GetParams ();
	p.Company = Data.Company;
	p.Warehouse = Data.Warehouse;
	p.Department = Data.Department;
	p.Location = Data.Location;
	p.Method = Data.Method;
	p.Day = Data.Day;
	p.Memo = Data.Memo;
	ResultAddress = PutToTempStorage ( undefined, UUID );
	p.Address = ResultAddress;
	args = new Array ();
	args.Add ( "RetailSales" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, UUID, , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure Complete ( Result, Params ) export
	
	notifyChanges ();
	if ( Result ) then
		Output.ProcessCompleted ();
	endif;

EndProcedure

&AtClient
Procedure notifyChanges ()
	
	changes = GetFromTempStorage ( ResultAddress );
	if ( changes <> undefined ) then
		for each ref in changes do
			NotifyChanged ( ref );
		enddo;
	endif;

EndProcedure
