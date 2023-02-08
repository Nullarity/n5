&AtClient
var TableRow export;
&AtClient
var DrData export;
&AtClient
var CrData export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	disableAccounts ();
	InvoiceForm.SetLocalCurrency ( ThisObject );
	Options.Company ( ThisObject, Object.Company );
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Object.Company = Parameters.Company;
	
EndProcedure 

&AtServer
Procedure disableAccounts ()
	
	Items.AccountDr.ReadOnly = Parameters.DisableDr;
	Items.AccountCr.ReadOnly = Parameters.DisableCr;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	loadData ();
	EntryForm.EnableAnalytics ( ThisObject );
	EntryForm.DisableCurrency ( ThisObject, "Dr" );
	EntryForm.DisableCurrency ( ThisObject, "Cr" );
	activateAccount ();
	
EndProcedure

&AtClient
Procedure loadData ()
	
	TableRow = Object.Records.Add ();
	FillPropertyValues ( TableRow, FormOwner.Items.Records.CurrentData );
	EntryForm.FixAccounts ( ThisObject );
	EntryForm.InitAccounts ( ThisObject );
	
EndProcedure 

&AtClient
Procedure activateAccount ()
	
	if ( Parameters.NewRow ) then
		return;
	endif;
	if ( not AccountDr.IsEmpty ()
		and not Parameters.DisableDr ) then
		CurrentItem = Items.AccountDr;
	elsif ( not AccountCr.IsEmpty ()
		and not Parameters.DisableCr ) then
		CurrentItem = Items.AccountCr;
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	applyCommand ( Enum.ChoiceOperationsEntryRecord () );
	
EndProcedure

&AtClient
Procedure applyCommand ( Command )
	
	FormOwner.Modified = true;
	Close ( new Structure ( "Operation, Value", Command, TableRow ) );
	
EndProcedure 

&AtClient
Procedure SaveAndNew ( Command )
	
	applyCommand ( Enum.ChoiceOperationsEntrySaveAndNew () );
	
EndProcedure

&AtClient
Procedure AccountDrOnChange ( Item )
	
	EntryForm.AccountDrOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure DimDr1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimDr1StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DimDr1OnChange ( Item )
	
	EntryForm.DimDr1OnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DimDr2StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimDr2StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DimDr2OnChange ( Item )
	
	EntryForm.DimDr2OnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DimDr3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimDr3StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure CurrencyDrOnChange ( Item )
	
	EntryForm.CurrencyDrOnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure RateDrOnChange ( Item )
	
	EntryForm.RateDrOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure FactorDrOnChange ( Item )
	
	EntryForm.FactorDrOnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure CurrencyAmountDrOnChange ( Item )
	
	EntryForm.CurrencyAmountDrOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure AccountCrOnChange ( Item )
	
	EntryForm.AccountCrOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure DimCr1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimCr1StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DimCr1OnChange ( Item )
	
	EntryForm.DimCr1OnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DimCr2StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimCr2StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DimCr2OnChange ( Item )
	
	EntryForm.DimCr2OnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DimCr3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimCr3StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure CurrencyCrOnChange ( Item )
	
	EntryForm.CurrencyCrOnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure RateCrOnChange ( Item )
	
	EntryForm.RateCrOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure FactorCrOnChange ( Item )
	
	EntryForm.FactorCrOnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure CurrencyAmountCrOnChange ( Item )
	
	EntryForm.CurrencyAmountCrOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	EntryForm.AmountOnChange ( ThisObject, Item );
	
EndProcedure
