&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setTitle ();
	filterHistory ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	SetupDate = Parameters.SetupDate;
	Value = Parameters.Parameter.ValueType.AdjustValue ();
	
EndProcedure

&AtServer
Procedure setTitle ()
	
	Title = Parameters.Parameter;
	
EndProcedure 

&AtServer
Procedure filterHistory ()
	
	DC.SetFilter ( History, "Parameter", Parameters.Parameter );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( CheckFilling () ) then
		save ();
		NotifyChanged ( Parameters.Parameter );
		Close ();
	endif; 
	
EndProcedure

&AtServer
Procedure save ()
	
	r = InformationRegisters.Settings.CreateRecordManager ();
	r.Parameter = Parameters.Parameter;
	r.Period = SetupDate;
	r.Value = Value;
	r.Write ();
	
EndProcedure 

&AtClient
Procedure SetupDateOnChange ( Item )
	
	adjustDate ();
	
EndProcedure

&AtClient
Procedure adjustDate ()
	
	if ( SetupDate = Date ( 1, 1, 1 ) ) then
		SetupDate = BegOfYear ( SessionDate () );
	else
		SetupDate = BegOfMonth ( SetupDate );
	endif; 
	
EndProcedure 

// *****************************************
// *********** Table History

&AtClient
Procedure HistoryOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	loadRecord ();
	
EndProcedure

&AtClient
Procedure loadRecord ()
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	Value = TableRow.Value;
	SetupDate = TableRow.Period;
	
EndProcedure 

&AtClient
Procedure HistoryBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure HistoryBeforeRowChange ( Item, Cancel)
	
	Cancel = true;
	
EndProcedure
