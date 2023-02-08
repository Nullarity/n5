&AtServer
var Copy;
&AtClient
var ItemsRow;
&AtServer
var Env;
&AtServer
var Base;
&AtServer
var InvoiceRecordExists;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceRecords.Read ( ThisObject );
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		DocumentForm.Init ( Object );
		fillNew ();
		updateChangesPermission ();
	endif;
	setAccount ();
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.Company ( ThisObject, Object.Company );
	setLinks ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormInvoice show filled ( InvoiceRecord );
	|NewInvoiceRecord show FormStatus = Enum.FormStatuses.Canceled or empty ( FormStatus );
	|Warning show ChangesDisallowed;
	|GroupItems Date Company Memo Number lock ChangesDisallowed;
	|ItemsCommandBar disable ChangesDisallowed;
	|Links show ShowLinks
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		return;
	endif; 
	Object.Company = Logins.Settings ( "Company" ).Company;
	
EndProcedure 

&AtServer
Procedure setAccount () 

	info = InformationRegisters.Settings.GetLast ( , new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.LVIExploitationAccount ) );
	Account = info.Value;

EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		Env.Q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( isNew () ) then
		return;
	endif;
	InvoiceRecordExists = not InvoiceRecord.IsEmpty ();
	if ( InvoiceRecordExists ) then
		s = "
		|// #InvoiceRecords
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.InvoiceRecord as Documents
		|where Documents.Base = &Ref
		|and not Documents.DeletionMark
		|";
		Env.Selection.Add ( s );
	endif;
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	if ( not isNew () ) then
		if ( InvoiceRecordExists ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.InvoiceRecords, Metadata.Documents.InvoiceRecord ) );
		endif;
	endif;
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Forms.DeleteLastRow ( Object.Items, "Item" );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.InvoiceRecordsWrite ()
		and Source.Ref = InvoiceRecord ) then
		readPrinted ();	
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure readPrinted ()
	
	InvoiceRecords.Read ( ThisObject );
	Appearance.Apply ( ThisObject, "FormStatus, ChangesDisallowed" );
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Object.Ref.IsEmpty () ) then
		return;
	endif;
	readPrinted ();
	Appearance.Apply ( ThisObject, "InvoiceRecord" );
	
EndProcedure

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	readNewInvoice ( NewObject );
	
EndProcedure

&AtServer
Procedure readNewInvoice ( NewObject ) 

	type = TypeOf ( NewObject );
	if ( type = Type ( "DocumentRef.InvoiceRecord" ) ) then
		InvoiceRecords.Read ( ThisObject );
		setLinks ();
		Appearance.Apply ( ThisObject, "InvoiceRecord, ShowLinks, FormStatus, ChangesDisallowed" );
	endif;

EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Item", ItemsRow.Item );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Account = Account;
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtServerNoContext
Function getItemData ( val Params )
	
	data = DF.Values ( Params.Item, "Package, Package.Capacity as Capacity" );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure PackageOnChange ( Item )

	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Package", ItemsRow.Package );
	data = getPackageData ( p );
	ItemsRow.Capacity = data.Capacity;
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtServerNoContext
Function getPackageData ( val Params )
	
	capacity = DF.Pick ( Params.Package, "Capacity", 1 );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	return data;
	
EndFunction 

&AtClient
Procedure QuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtClient
Procedure QuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	
EndProcedure