&AtServer
var AccountData;
&AtClient
var AccountData;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readAccount ();
	labelDims ();
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAccount ()
	
	AccountData = GeneralAccounts.GetData ( Object.AccountNegative );
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

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Dim1 show ExpensesLevel > 0;
	|Dim2 show ExpensesLevel > 1;
	|Dim3 show ExpensesLevel > 2
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
	data = getData ();
	if ( data <> undefined ) then
		FillPropertyValues ( Object, data );
		applyExpenseAccount ();
	endif;

EndProcedure

&AtServer
Function getData () 

	s = "
	|select top 1 Documents.AccountNegative as AccountNegative, Documents.AccountPositive as AccountPositive, Documents.CashFlow as CashFlow,
	|	Documents.Dim1 as Dim1, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3
	|from Document.CalculationRatesDifferences as Documents
	|where Documents.Posted
	|order by Documents.Date desc
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );

EndFunction

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
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure AccountNegativeOnChange(Item)
	
	applyExpenseAccount ();
	
EndProcedure
