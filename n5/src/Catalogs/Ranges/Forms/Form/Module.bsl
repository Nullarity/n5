&AtServer
var AccountData;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readData ();
	readAccount ();
	labelDims ();
	limitLength ( ThisObject );
	countForms ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readData ()
	
	data = getData ();
	if ( data = undefined ) then
		Status = undefined;
		LastNumber = 0;
		Warehouse = undefined;
	else
		Status = data.Status;
		LastNumber = data.Last;
		Warehouse = data.Warehouse;
	endif;
	
EndProcedure

&AtServer
Function getData ()
	
	s = "
	|select Statuses.Status as Status, Ranges.Last as Last, Locations.Warehouse as Warehouse
	|from InformationRegister.RangeStatuses.SliceLast ( , Range = &Ref ) as Statuses
	|	//
	|	// Ranges
	|	//
	|	left join InformationRegister.Ranges as Ranges
	|	on Ranges.Range = &Ref
	|	//
	|	// RangeLocations
	|	//
	|	left join InformationRegister.RangeLocations.SliceLast ( , Range = &Ref ) as Locations
	|	on true
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction

&AtServer
Procedure readAccount ()
	
	SetPrivilegedMode ( true );
	AccountData = GeneralAccounts.GetData ( Object.ExpenseAccount );
	ExpensesLevel = AccountData.Fields.Level;
	
EndProcedure 

&AtServer
Procedure labelDims ()
	
	i = 1;
	for each dim in AccountData.Dims do
		Items [ "Dim" + i ].Title = dim.Presentation;
		i = i + 1;
	enddo; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure limitLength ( Form, Value = undefined )
	
	min = ? ( Value = undefined, StrLen ( Format ( Form.Object.Finish, "NG=" ) ), Value );
	Form.Items.Length.MinValue = min;

EndProcedure

&AtClientAtServerNoContext
Procedure countForms ( Form )
	
	object = Form.Object;
	Form.Total = 1 + object.Finish - object.Start;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		lockOwner ();
		fillNew ();
		limitLength ( ThisObject );
	endif;
	setCommandBar ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Invoice GroupAccount Warehouse show filled ( Object.Item );
	|Company lock filled ( Object.Item ) or filled ( Status );
	|Dim1 show ExpensesLevel > 0;
	|Dim2 show ExpensesLevel > 1;
	|Dim3 show ExpensesLevel > 2;
	|GroupInfo show filled ( Status );
	|Type lock filled ( Status );
	|Prefix Start Finish Length Received lock filled ( Status );
	|Prefix Start Finish Total LastNumber hide Object.Online;
	|Description show Object.Online;
	|GroupWarning show empty ( Object.Ref ) and empty ( Object.Item );
	|Source show filled ( Object.Source );
	|Print show Object.Type = Enum.Forms.Invoices;
	|ProposeEnrollment show
	|	ProposeEnrollment
	|	and empty ( Object.Item )
	|	and empty ( Object.Ref )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure lockOwner ()
	
	WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;

EndProcedure

&AtServer
Procedure fillNew ()
	
	Parameters.AdditionalParameters.Property ( Enum.AdditionalPropertiesProposeEnrollment (), ProposeEnrollment );
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	checkCreation ();
	if ( Object.Company.IsEmpty () ) then
		settings = Logins.Settings ( "Company" );
		Object.Company = settings.Company;
	endif;
	if ( Parameters.AdditionalParameters.Property ( Enum.AdditionalPropertiesReceived () ) ) then
		Object.Received = Parameters.AdditionalParameters.AdditionalPropertiesReceived;
	endif;
	DocumentForm.SetCreator ( Object );
	Object.Real = not Object.Item.IsEmpty ();
	
EndProcedure

&AtServer
Procedure checkCreation ()
	
	item = Object.Item;
	if ( item.IsEmpty () ) then
		return;
	endif;
	if ( not DF.Pick ( item, "Form" ) ) then
		raise Output.ItemIsNotForm ( new Structure ( "Item", item ) );
	endif;
	
EndProcedure

&AtServer
Procedure setCommandBar ()
	
	if ( Object.Ref.IsEmpty () ) then
		CommandBarLocation = FormCommandBarLabelLocation.None;
		Items.WriteAndClose.DefaultButton = true;
	else
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.ShortCommandBar.Visible = false;
	endif;
	
EndProcedure

&AtClient
Procedure OnClose ( Exit )
	
	if ( not Exit
		and ProposeEnrollment
		and ValueIsFilled ( Object.Ref ) ) then
		enroll ();
	endif;
	
EndProcedure

&AtClient
Procedure enroll ()
	
	values = new Structure ( "Range", Object.Ref );
	OpenForm ( "Document.EnrollRange.ObjectForm", new Structure ( "FillingValues", values ) );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ExpenseAccountOnChange ( Item )
	
	applyExpenseAccount ();
	
EndProcedure

&AtServer
Procedure applyExpenseAccount ()
	
	readAccount ();
	adjustDims ( AccountData, Object );
	labelDims ();
	Appearance.Apply ( ThisObject, "ExpensesLevel" );
	      	
EndProcedure 

&AtClientAtServerNoContext
Procedure adjustDims ( Data, Target )
	
	fields = Data.Fields;
	dims = Data.Dims;
	level = fields.Level;
	if ( level = 0 ) then
		Target.Dim1 = null;
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 1 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 2 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = null;
	else
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = dims [ 2 ].ValueType.AdjustValue ( Target.Dim3 );
	endif; 

EndProcedure 

&AtClient
Procedure StartOnChange ( Item )
	
	countForms ( ThisObject );
	
EndProcedure

&AtClient
Procedure FinishOnChange ( Item )
	
	countForms ( ThisObject );
	adjustLength ();
	
EndProcedure

&AtClient
Procedure adjustLength ()
	
	min = StrLen ( Format ( Object.Finish, "NG=" ) );
	if ( Object.Length < min ) then
		Object.Length = min;
	endif;
	limitLength ( ThisObject, min );

EndProcedure

&AtClient
Procedure TypeOnChange ( Item )
	
	applyType ();
	
EndProcedure

&AtClient
Procedure applyType ()
	
	if ( Object.Type = PredefinedValue ( "Enum.Forms.InvoicesOnline" ) ) then
		Object.Description = "e-Factura";
		Object.Length = 9;
		Object.Start = 0;
		Object.Finish = 0;
		Object.Prefix = "";
		Object.Online = true;
	else
		Object.Online = false;
	endif;
	Appearance.Apply ( ThisObject, "Object.Online, Object.Type" );
	
EndProcedure
