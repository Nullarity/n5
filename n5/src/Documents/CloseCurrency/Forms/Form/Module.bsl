&AtClient
var FillDocument; 
&AtClient
var Recalculate;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	filterList ();
	filterDeleted ();
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure filterList ()
	
	ref = ? ( Object.Ref.IsEmpty (), Documents.CloseCurrency.GetRef ( new UUID () ), Object.Ref );
	DC.ChangeFilter ( List, "Base", ref, true );
	
EndProcedure

&AtServer
Procedure filterDeleted ()
	
	DC.ChangeFilter ( List, "DeletionMark", ShowDeleted, not ShowDeleted );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		updateChangesPermission ();
		filterList ();
		filterDeleted ();
	endif; 
	Options.Company ( ThisObject, Object.Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Calculate ShowDeleted HideDeleted DrCr show filled ( Object.Ref );
	|ShowDeleted press ShowDeleted;
	|HideDeleted press not ShowDeleted;
	|ShowHideDeleted title/Output.HideDeletedAdjustments ShowDeleted;
	|ShowHideDeleted title/Output.ShowDeletedAdjustments not ShowDeleted;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	setOperationDate ( Object );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setOperationDate ( Object )
	
	objectDate = Object.Date;
	if ( objectDate = Date ( 1, 1, 1 ) ) then
		#if ( Client ) then
			date = SessionDate ();
		#else
			date = CurrentSessionDate ();
		#endif
	else
		date = objectDate;
	endif;
	Object.OperationDate = Date ( Year ( date ) - 1, 12, 31, 23, 59, 59 );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	filterList ();
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	setOperationDate ( Object );

EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure Fill ( Command )
	
	runCalculations ( FillDocument );
	
EndProcedure

&AtClient
Procedure runCalculations ( Variant )
	
	if ( not Forms.Check ( ThisObject, "Company" ) ) then
		return;
	endif;
	if ( Object.Ref.IsEmpty ()
		and not Write () ) then
		return;
	endif;
	CalculationVariant = Variant;
	params = fillingParams ();
	if ( CalculationVariant = FillDocument ) then
		Filler.Open ( params, ThisObject );
	else
		Filler.ProcessData ( params, ThisObject );
	endif; 
	
EndProcedure 

&AtClient
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "CloseCurrencyFilling";
	p.Filters = getFilters ();
	p.Background = true;
	p.Batch = true;
	p.CloseOnErrors = true;
	return p;
	
EndFunction

&AtClient
Function getFilters ()
	
	filters = new Array ();
	item = DC.CreateParameter ( "Date", Object.OperationDate );
	filters.Add ( item );
	item = DC.CreateParameter ( "Company", Object.Company );
	filters.Add ( item );
	ref = Object.Ref;
	item = DC.CreateParameter ( "Base", ref );
	filters.Add ( item );
	item = DC.CreateParameter ( "PaymentOption", Object.PaymentOption );
	filters.Add ( item );
	item = DC.CreateParameter ( "PaymentDate", Object.PaymentDate );
	filters.Add ( item );
	if ( CalculationVariant = Recalculate ) then
		item = DC.CreateParameter ( "CalculatingDocument", ref );
		filters.Add ( item );
	endif;
	return filters;
	
EndFunction

&AtClient
Procedure Calculate ( Command )
	
	if ( Modified ) then
		Output.SaveModifiedObject ( ThisObject, Recalculate );
	else
		runCalculations ( Recalculate );
	endif; 

EndProcedure

&AtClient
Procedure SaveModifiedObject ( Answer, Variant ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( Write () ) then
		runCalculations ( Variant );
	endif; 
	
EndProcedure

&AtClient
Procedure Filling ( Result, Params ) export
	
	Items.List.Refresh ();
	
EndProcedure 

&AtClient
Procedure HideDeleted ( Command )
	
	switchShowDeleted ( false );
	
EndProcedure

&AtClient
Procedure switchShowDeleted ( Show )
	
	ShowDeleted = Show;
	filterDeleted ();
	Appearance.Apply ( ThisObject, "ShowDeleted" );
	
EndProcedure

&AtClient
Procedure ShowDeleted ( Command )
	
	switchShowDeleted ( true );
	
EndProcedure

// *****************************************
// *********** Variables Initialization

FillDocument = 1; 
Recalculate = 2;
