// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	defineService ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure defineService ( Form )
	
	item = Form.Record.Item;
	if ( item.IsEmpty () ) then
		
	endif;
	data = DF.Values ( item, "Service, IsFolder" );
	Form.IsFolder = data.IsFolder;
	Form.Service = data.Service;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Record.SourceRecordKey.IsEmpty () ) then
		init ();
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|GroupExpense enable Service or IsFolder or not filled ( Record.Item );
	|ExpenseAccount enable not Service or IsFolder or not filled ( Record.Item )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	if ( not Record.Item.IsEmpty () ) then
		defineService ( ThisObject );
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ItemOnChange ( Item )
	
	defineService ( ThisObject );
	resetExpenses ();
	
EndProcedure

&AtClient
Procedure resetExpenses ()
	
	if ( Service ) then
		Record.ExpenseAccount = undefined;
	else
		Record.Expense = undefined;
		Record.Department = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Service" );
	
EndProcedure 
