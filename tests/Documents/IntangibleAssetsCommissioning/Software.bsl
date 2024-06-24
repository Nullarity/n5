// Commissioning of intangible asset in progress

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A19W" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region postCommissioning
Call ( "Documents.IntangibleAssetsCommissioning.ListByMemo", id );
With ();
if ( Call ( "Table.Count", Get ( "#List" ) ) ) then
	Click ( "#FormChange" );
	With ();
	Click ( "#FormPost" );
else
	Commando("e1cib/command/Document.IntangibleAssetsCommissioning.Create");
	Put("#Date", this.Date);
	Put("#Memo", id);
	Put("#Employee", "Director" );
	Activate ( "#GroupInProgress" );
	Click ( "#InProgressAdd" );
	With ();
	Set ( "#Item", this.Item );
	Set ( "#Account", "1110" );
	Next ();
	Check ( "#Amount", 520000 );
	Set ( "#IntangibleAsset", this.Asset );
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
	Commando ( "e1cib/data/Catalog.IntangibleAssets" );
	Set ( "#Description", this.Asset );
	Click ( "#FormWriteAndClose" );
	#endregion
	
	#region entry
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = "1110";
	row.AccountCr = "0";
	row.DimDr1 = this.Item;
	row.DimDr2 = "Others";
	row.Amount = 520000;
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = BegOfYear ( this.Date );
	p.Records.Add ( row );
	Call ( "Documents.Entry.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
