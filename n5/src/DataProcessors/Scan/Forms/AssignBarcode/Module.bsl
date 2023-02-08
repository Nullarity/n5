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
	
	Unit = Application.Unit ();
	VAT = Application.ItemsVAT ();
	ExpirationPeriod = 12;
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	ScanResult = Parameters.ScanResult;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Description SeriesControl Unit NewPackage VAT show Variant = 0;
	|Item Package show Variant = 1;
	|SeriesVariant show SeriesRequired and Variant = 1;
	|Series show SeriesRequired and Variant = 1 and SeriesVariant = 1;
	|Produced ExpirationPeriod ExpirationDate LotNumber show ( SeriesControl and Variant = 0 )
	|	or ( SeriesRequired and SeriesVariant = 0 and Variant = 1 );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( Variant = 0 ) then
		if ( not checkPackage () ) then
			Cancel = true;
		endif;
		CheckedAttributes.Add ( "Description" );
		CheckedAttributes.Add ( "Unit" );
		if ( SeriesControl ) then
			CheckedAttributes.Add ( "LotNumber" );
			CheckedAttributes.Add ( "ExpirationDate" );
		endif;
	else
		CheckedAttributes.Add ( "Item" );
		if ( SeriesRequired ) then
			if ( SeriesVariant = 0 ) then
				CheckedAttributes.Add ( "LotNumber" );
				CheckedAttributes.Add ( "ExpirationDate" );
			else
				CheckedAttributes.Add ( "Lot" );
			endif;
		endif;
	endif;
	
EndProcedure

&AtServer
Function checkPackage ()
	
	if ( usePackages () ) then
		return true;
	endif;
	obj = FormAttributeToValue ( "NewPackage" );
	obj.AdditionalProperties.Insert ( Enum.AdditionalPropertiesDontCheckOwner (), true );
	return Forms.CheckEmbedded ( obj, "NewPackage" );

EndFunction

&AtServer
Function usePackages ()

	return not NewPackage.Unit.IsEmpty ();

EndFunction

// *****************************************
// *********** Group Form

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
		saveItem ();
		if ( SeriesControl ) then
			if ( not saveSeries () ) then
				return false;
			endif;
		endif;
	elsif ( SeriesRequired
		and SeriesVariant = 0 ) then
		if ( not saveSeries () ) then
			return false;
		endif;
	endif;
	saveBarcode ();
	CommitTransaction ();
	prepareResult ();
	return true;
	
EndFunction

&AtServer
Procedure saveItem ()
	
	obj = Catalogs.Items.CreateItem ();
	Metafields.Constructor ( obj );
	obj.Parent = Application.NewItems ();
	obj.Description = Description;
	obj.FullDescription = Description;
	obj.Unit = Unit;
	obj.VAT = VAT;
	obj.Series = SeriesControl;
	obj.CostMethod = Application.ItemsCost ();
	obj.SetNewCode ();
	withPackage = usePackages ();
	if ( withPackage ) then
		packageRef = Catalogs.Packages.GetRef ( new UUID () );
		obj.Package = packageRef;
	endif;
	obj.Write ();
	Item = obj.Ref;
	if ( withPackage ) then
		obj = FormAttributeToValue ( "NewPackage" );
		obj.Owner = Item;
		obj.SetNewObjectRef ( packageRef );
		obj.SetNewCode ();
		obj.Write ();
		Package = obj.Ref;
	endif;
	
EndProcedure

&AtServer
Function saveSeries ()
	
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
	
	r = InformationRegisters.Barcodes.CreateRecordManager ();
	r.Item = Item;
	r.Package = Package;
	r.Feature = Feature;
	r.Barcode = ScanResult.Barcode;
	r.Write ();
	if ( SeriesControl ) then
		r = InformationRegisters.Barcodes.CreateRecordManager ();
		r.Item = Item;
		r.Package = Package;
		r.Feature = Feature;
		r.Series = Series;
		r.Barcode = Goods.NewEAN13 ();
		r.Write ();
	endif;
	
EndProcedure

&AtServer
Procedure prepareResult ()
	
	ScanResult.Item = Item;
	ScanResult.Package = Package;
	ScanResult.Feature = Feature;
	ScanResult.Series = Series;
	ScanResult.BarcodeFound = false;
	
EndProcedure

&AtClient
Procedure VariantOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Variant" );
	
EndProcedure

&AtClient
Procedure ItemOnChange ( Item )
	
	if ( itemBarcoded ( ThisObject.Item ) ) then
		Output.AssignNewBarcode ( ThisObject );
	else
		applyItem ();
	endif;
	
EndProcedure

&AtServerNoContext
Function itemBarcoded ( val Item )
	
	s = "
	|select top 1 1
	|from InformationRegister.Barcodes as Barcodes
	|where Barcodes.Item = &Item
	|";
	q = new Query ( s );
	q.SetParameter ( "Item", Item );
	return not q.Execute ().IsEmpty ();
	
EndFunction

&AtClient
Procedure AssignNewBarcode ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		Item = undefined;
		CurrentItem = Items.Variant;
	else
		applyItem ();
	endif;
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	data = DF.Values ( Item, "Series, Package" );
	SeriesRequired = data.Series;
	Package = data.Package;
	Appearance.Apply ( ThisObject, "SeriesRequired" );
	
EndProcedure

&AtClient
Procedure SeriesControlOnChange ( Item )
	
	applySeriesControl ();
	
EndProcedure

&AtClient
Procedure applySeriesControl ()
	
	if ( not SeriesControl ) then
		LotNumber = undefined;
		ExpirationDate = undefined;
	endif;
	Appearance.Apply ( ThisObject, "SeriesControl" );
	
EndProcedure

&AtClient
Procedure SeriesVariantOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "SeriesVariant" );
	
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

&AtClient
Procedure NewPackageUnitOnChange ( Item )

	setPackageName ();
	
EndProcedure

&AtClient
Procedure setPackageName ()
	
	NewPackage.Description = TrimR ( "" + NewPackage.Unit );
	
EndProcedure 
