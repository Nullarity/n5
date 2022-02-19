// Create a new document and scan an item with different options

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0NH" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

MainWindow.ExecuteCommand("e1cib/command/Document.InventoryStockman.Create");
Pause(1);
With("Scan"); // Will appear automatically after document creation
if ( Fetch ( "#Autoclose" ) = "Yes" ) then
	Click ("#Autoclose");
endif;
if ( Fetch ( "#AskQuantity" ) = "Yes" ) then
	Click ("#AskQuantity");
endif;

#region assignNewBarcode
barcode = TestingID ();
Set ( "#Barcode", barcode );
Pause ( 1 );
With ();
Set ( "#Description", "Item " + barcode );
Click ( "#SeriesControl" );
With ( "Item is not found" );
Set ( "#LotNumber", barcode );
Set ( "#ExpirationPeriod", 13 );
Set ( "#Produced", " 7/01/2021" );
Set ( "#Unit", "UT" );
Click ( "#NewPackage" );
Set ( "#NewPackageUnit", "Box" );
Set ( "#NewPackageCapacity", 5 );
Set ( "#VAT", "20%" );
Click ( "#FormOK" );
#endregion

#region checkPackage
Close ( "Scan" );
With();
Check ( "#Items / #ItemsPackage [ 1 ]", "BX" );
Click("#ItemsScan");
#endregion

#region newLotForExistedItem
Pause ( 1 );
With ();
barcode = this.ItemWithBarcodeCode;
Set ( "#Barcode", barcode );
Pause ( 1 );
// System will find the item but without series (series is enabled for this item)
With ();
newLot = TestingID ();
Set ( "#LotNumber", newLot );
Set ( "#ExpirationDate", Format ( CurrentDate () + 86400, "DLF=D" ) );
Click ( "#FormOK" );
#endregion

#region selectExistedItem
Pause(1);
With ();
unexistedBarcode = "Item " + TestingID ();
Set ( "#Barcode", unexistedBarcode );
Pause ( 1 );
With ();
Set ( "#Variant", "Select" );
Activate("#Item");
// Items list form will be automatically opened
Close("Items");
Set ( "#Item", this.Item);
Next ();
Click("#FormOK");
#endregion

#region addWithQuantity
With ();
Click ( "#AskQuantity" );
Set ( "#Barcode", unexistedBarcode );
Pause(1);
With ();
Set ("#Quantity", 5);
Click("#FormOK");
Pause(1);
With ();
// Set back the quantity flag
Click ( "#AskQuantity" );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Item", "Item " + id );
	this.Insert ( "ItemWithBarcodeCode", id + id );
	this.Insert ( "ItemWithBarcodeName", "Nobarcode " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region newItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	Call ( "Catalogs.Items.Create", p );
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.ItemWithBarcodeName;
	p.Barcode = this.ItemWithBarcodeCode;
	p.Series = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
