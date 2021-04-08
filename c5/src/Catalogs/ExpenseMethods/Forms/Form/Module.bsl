// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Expenses

&AtClient
Procedure ExpensesOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow and not Clone ) then
		setCoef ();
	endif; 
	
EndProcedure

&AtClient
Procedure setCoef ()
	
	Items.Expenses.CurrentData.Rate = 1;
	
EndProcedure 
