// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Object.Class.IsEmpty () ) then
		setType ( Object );
	endif;
	
EndProcedure

&AtClientAtServerNoContext
Procedure setType ( Object ) 

	class = Object.Class;
	if ( class = PredefinedValue ( "Enum.Accounts.NonPosting" ) ) then
		return;
	elsif ( class = PredefinedValue ( "Enum.Accounts.AccountsPayable" )
		or class = PredefinedValue ( "Enum.Accounts.Income" )
		or class = PredefinedValue ( "Enum.Accounts.OtherIncome" )
		or class = PredefinedValue ( "Enum.Accounts.LongTermLiability" )
		or class = PredefinedValue ( "Enum.Accounts.OtherCurrentLiability" )
		or class = PredefinedValue ( "Enum.Accounts.Equity" ) ) then
		Object.Type = PredefinedValue ( "AccountType.Passive" );
	else 
		Object.Type = PredefinedValue ( "AccountType.Active" );
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CodeOnChange ( Item )
	
	setOrder ();
	
EndProcedure

&AtClient
Procedure setOrder ()
	
	Object.Order = Object.Code;
	
EndProcedure 

&AtClient
Procedure ClassOnChange ( Item )
	
	setType ( Object );
	
EndProcedure

// *****************************************
// *********** Table ExtDimensionTypes

&AtClient
Procedure ExtDimensionTypesOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow and not Clone ) then
		setDefault ();
	endif; 
	
EndProcedure

&AtClient
Procedure setDefault ()
	
	currentData = Items.ExtDimensionTypes.CurrentData;
	currentData.Accrual = true;
	currentData.Currency = true;
	currentData.Quantitative = true;
	
EndProcedure 

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	DescriptionRu = CurrentObject.DescriptionRu;
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Object.DescriptionRo = Object.Description;
	Object.DescriptionRu = DescriptionRu;
	
EndProcedure
