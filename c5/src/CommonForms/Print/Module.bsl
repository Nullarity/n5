&AtClient
var PreviousArea;
&AtClient
var TotalsEnv;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	result = PrintSrv.Print ( Parameters.Params, Parameters.Language );
	if ( result = undefined ) then
		Cancel = true;
		return;
	endif; 
	applyResult ( result );
	setEditModeButton ( Items );
	
EndProcedure

&AtServer
Procedure applyResult ( Result )
	
	TabDoc = Result.TabDoc;
	Reference = result.Reference;
	params = Parameters.Params;
	if ( params.Caption = undefined ) then
		Title = PrintSrv.GetFormCaption ( params.Name + Parameters.Language, params.Manager, params.Objects [ 0 ] );
	else
		Title = Parameters.Caption;
	endif; 
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	setCommandBarButtonsVisibility ();

EndProcedure

&AtClient
Procedure setCommandBarButtonsVisibility ()
	
	#if ( WebClient ) then
		Items.TabDocShowHeaders.Visible = false;
		Items.TabDocShowGrid.Visible = false;
	#endif 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure SendFormByEmail ( Command )
	
	organizeDelivery ();
	
EndProcedure

&AtClient
Procedure organizeDelivery ()
	
	info = deliveryInfo ( Reference );
	params = Mailboxes.GetEmailParams ();
	params.To = info.To;
	params.Subject = "" + Reference + ", " + info.From;
	params.TableDescription = Title;
	params.TableAddress = PutToTempStorage ( TabDoc, UUID );
	p = new Structure ( "Delivery", params );
	if ( info.EmailClient ) then
		OpenForm ( "Document.OutgoingEmail.ObjectForm", p );
	else
		OpenForm ( "CommonForm.Send", p );
	endif;
	
EndProcedure 

&AtServerNoContext
Function deliveryInfo ( val Reference )
	
	info = new Structure ( "EmailClient, To, From" );
	info.EmailClient = IsInRole ( Metadata.Roles.Email )
	and not ( Environment.MobileClient () or MailboxesSrv.Default ().IsEmpty () );
	if ( Reference = undefined ) then
		info.To = "";
	elsif ( Metafields.Exists ( Reference, "Customer" ) ) then
		info.To = DF.Pick ( Reference, "Customer.Email" );
	elsif ( Metafields.Exists ( Reference, "Vendor" ) ) then
		info.To = DF.Pick ( Reference, "Vendor.Email" );
	else
		info.To = "";
	endif;
	if ( Reference <> undefined
		and Metafields.Exists ( Reference, "Company" ) ) then
		info.From = DF.Pick ( Reference, "Company" );
	else
		info.From = Application.Company ();
	endif;
	return info;

EndFunction 

&AtClient
Procedure ChangeEditMode ( Command )
	
	setTabDocEdit ();
	setEditModeButton ( Items );
	
EndProcedure

&AtClient
Procedure setTabDocEdit ()
	
	Items.TabDoc.Edit = not Items.TabDoc.Edit;
	
EndProcedure

&AtClientAtServerNoContext
Procedure setEditModeButton ( Items )
	
	Items.TabDocChangeEditMode.Check = Items.TabDoc.Edit;
	
EndProcedure

&AtClient
Procedure ShowHeaders ( Command )
	
	setShowHeadersMode ();
	setShowHeadersButton ();
	
EndProcedure

&AtClient
Procedure setShowHeadersMode ()
	
	Items.TabDoc.ShowHeaders = not Items.TabDoc.ShowHeaders;

EndProcedure

&AtClient
Procedure setShowHeadersButton ()
	
	Items.TabDocShowHeaders.Check = Items.TabDoc.ShowHeaders;
	
EndProcedure

&AtClient
Procedure ShowGrid ( Command )
	
	setShowGridMode ();
	setShowGridButton ();
	
EndProcedure

&AtClient
Procedure setShowGridMode ()
	
	Items.TabDoc.ShowGrid = not Items.TabDoc.ShowGrid;

EndProcedure

&AtClient
Procedure setShowGridButton ()
	
	Items.TabDocShowGrid.Check = Items.TabDoc.ShowGrid;
	
EndProcedure

&AtClient
Procedure SaveToDocuments ( Command )
	
	openDocument ();
	
EndProcedure

&AtClient
Procedure openDocument ()
	
	values = new Structure ();
	values.Insert ( "Object", Reference );
	values.Insert ( "Subject", String ( Reference ) );
	values.Insert ( "TabDoc", TabDoc );
	p = new Structure ( "FillingValues", values );
	p.Insert ( "Command", Enum.DocumentCommandsUploadPrintForm () );
	p.Insert ( "TabDoc", TabDoc );
	OpenForm ( "Document.Document.ObjectForm", p );
	
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
 
