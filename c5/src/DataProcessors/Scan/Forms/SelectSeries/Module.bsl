&AtServer
var MixedUp;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	loadParams ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	ExpirationPeriod = 12;
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	ScanResult = Parameters.ScanResult;
	Item = ScanResult.Item;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|LotNumber Produced ExpirationPeriod ExPirationDate show Variant = 0;
	|Series show Variant = 1;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( Variant = 0 ) then
		CheckedAttributes.Add ( "LotNumber" );
		CheckedAttributes.Add ( "ExpirationDate" );
	else
		CheckedAttributes.Add ( "Series" );
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure VariantOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Variant" );
	
EndProcedure

&AtClient
Procedure OK ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	if ( not applyAction () ) then
		return;
	endif;
	Close ( ScanResult );
	
EndProcedure

&AtServer
Function applyAction ()
	
	BeginTransaction ( DataLockControlMode.Managed );
	if ( Variant = 0 ) then
		if ( not saveLot () ) then
			return false;
		endif;
	endif;
	saveBarcode ();
	CommitTransaction ();
	prepareResult ();
	return true;
	
EndFunction

&AtServer
Function saveLot ()
	
	obj = Catalogs.Series.CreateItem ();
	obj.Owner = Item;
	obj.Description = LotNumber;
	obj.Lot = LotNumber;
	obj.Produced = Produced;
	obj.ExpirationPeriod = ExpirationPeriod;
	obj.ExpirationDate = ExpirationDate;
	if ( obj.CheckFilling () ) then
		obj.Write ();
		Series = obj.Ref;
		return true;
	else
		return false;
	endif;
	
EndFunction

&AtServer
Procedure saveBarcode ()
	
	MixedUp = ( Variant = 1 ) and barcodeExists ();
	if ( MixedUp ) then
		return;
	endif;
	r = InformationRegisters.Barcodes.CreateRecordManager ();
	r.Barcode = Goods.NewEAN13 ();
	r.Item = Item;
	r.Feature = ScanResult.Feature;
	r.Series = Series;
	r.Package = ScanResult.Package;
	r.Write ();
	
EndProcedure

&AtServer
Function barcodeExists ()
	
	s = "
	|select top 1 1
	|from InformationRegister.Barcodes as Barcodes
	|where Barcodes.Item = &Item
	|and Barcodes.Package = &Package
	|and Barcodes.Feature = &Feature
	|and Barcodes.Series = &Series
	|";
	q = new Query ( s );
	q.SetPaRameter ( "Item", Item );
	q.SetPaRameter ( "Package", ScanResult.Package );
	q.SetPaRameter ( "Feature", ScanResult.Feature );
	q.SetPaRameter ( "Series", Series );
	return not q.Execute ().IsEmpty ();
	
EndFunction

&AtServer
Procedure prepareResult ()
	
	ScanResult.Series = Series;
	ScanResult.BarcodeFound = MixedUp;
	
EndProcedure

&AtClient
Procedure ProducedOnChange ( Item )
	
	SeriesForm.SetExpirationDate ( ThisObject );
	
EndProcedure

&AtClient
Procedure ExpirationPeriodOnChange ( Item )
	
	SeriesForm.SetExpirationDate ( ThisObject );
	
EndProcedure

&AtClient
Procedure ExpirationDateOnChange ( Item )
	
	SeriesForm.SetExpirationPeriod ( ThisObject );
	
EndProcedure
