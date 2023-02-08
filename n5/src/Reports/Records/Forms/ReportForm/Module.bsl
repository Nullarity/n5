&AtClient
var PreviousArea;
&AtClient
var TotalsEnv;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	applyParams ();
	
EndProcedure

&AtServer
Procedure applyParams ()
	
	if ( Parameters.Property ( "Document", Report.Document ) ) then
		Items.Document.Visible = false;
		makeReport ( ThisObject );
	endif; 
	
EndProcedure 

&AtClient
Procedure OnReopen ()

	makeReport ( ThisObject );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Make ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	makeReport ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure makeReport ( ThisObject )
	
	makeTabDoc ( ThisObject.TabDoc, ThisObject.Report.Document );
	setTitle ( ThisObject );
	setCurrentItem ( ThisObject );
	
EndProcedure

&AtServerNoContext
Procedure makeTabDoc ( TabDoc, Document )
	
	Reports.Records.Make ( TabDoc, Document );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setTitle ( Form )
	
	Form.Title = Output.DocumentMovementsPresentation ( new Structure ( "Document", Form.Report.Document ) );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setCurrentItem ( Form )
	
	Form.CurrentItem = Form.Items.TabDoc;
	
EndProcedure 

&AtClient
Procedure Rollup ( Command )
	
	TabDoc.ShowRowGroupLevel ( 0 );
	
EndProcedure

&AtClient
Procedure Collapse ( Command )
	
	TabDoc.ShowRowGroupLevel ( 1 );
	
EndProcedure

&AtClient
Procedure TabDocOnChange ( Item )

	PreviousArea = undefined;

EndProcedure

&AtClient
Procedure TabDocOnActivateArea ( Item )

	if ( drawing ()
		or sameArea () ) then
		return;
	endif;
	startCalculation ();
	
EndProcedure

&AtClient
Function drawing ()
	
	return TypeOf ( TabDoc.CurrentArea ) <> Type ( "SpreadsheetDocumentRange" );
	
EndFunction 

&AtClient
Function sameArea ()
	
	currentName = TabDoc.CurrentArea.Name;
	if ( PreviousArea = currentName ) then
		return true;
	else
		PreviousArea = currentName;
		return false;
	endif; 
	
EndFunction

&AtClient
Procedure startCalculation ()
	
	DetachIdleHandler ( "startUpdating" );
	AttachIdleHandler ( "startUpdating", 0.2, true );
	
EndProcedure 

&AtClient
Procedure startUpdating ()
	
	updateTotals ( true );
	
EndProcedure

&AtClient
Procedure updateTotals ( CheckSquare )
	
	if ( TotalsEnv = undefined ) then
		SpreadsheetTotals.Init ( TotalsEnv );	
	endif;
	TotalsEnv.Spreadsheet = TabDoc;
	TotalsEnv.CheckSquare = CheckSquare;
	SpreadsheetTotals.Update ( TotalsEnv );
	Items.CalcTotals.Visible = CheckSquare and TotalsEnv.HugeSquare;
	TotalInfo = TotalsEnv.Result; 
	
EndProcedure

&AtClient
Procedure CalcTotals ( Command )
	
	updateTotals ( false );
	
EndProcedure
