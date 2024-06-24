// Commissioning of construction object

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A19S" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region postCommissioning
Call ( "Documents.Commissioning.ListByMemo", id );
With ();
if ( Call ( "Table.Count", Get ( "#List" ) ) ) then
	Click ( "#FormChange" );
	With ();
	Click ( "#FormPost" );
else
	Commando("e1cib/command/Document.Commissioning.Create");
	Put("#Date", this.Date);
	Put("#Memo", id);
	Put("#Employee", "Director" );
	Activate ( "#GroupInProgress" );
	Click ( "#InProgressAdd" );
	With ();
	Set ( "#Item", this.Item );
	Set ( "#ItemAccount", "1211" );
	Next ();
	Check ( "#Amount", 120000 );
	Set ( "#FixedAsset", this.Asset );
	Set ( "#UsefulLife", 60 );
	Get ( "#Charge" ).SetCheck ();
	Click ( "#FormOK" );
	With ();
	Click ( "#FormPost" );
endif;
#endregion

#region checkRecords
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Asset", "Asset " + id );
	this.Insert ( "Item", "Item " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
//	goto ~a;
//	~a:

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.CreatePackage = false;
	Call ( "Catalogs.Items.Create", p );
	#endregion
	
	#region createAssest
	Commando ( "e1cib/data/Catalog.FixedAssets" );
	Set ( "#Description", this.Asset );
	Set ( "#Inventory", id );
	Click ( "#FormWriteAndClose" );
	#endregion
	
	#region entry
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = "1211";
	row.AccountCr = "0";
	row.DimDr1 = this.Item;
	row.DimDr2 = "Others";
	row.Amount = 120000;
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = BegOfYear ( this.Date );
	p.Records.Add ( row );
	Call ( "Documents.Entry.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
