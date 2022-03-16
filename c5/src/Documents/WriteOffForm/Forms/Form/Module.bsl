&AtServer
var AccountData;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readAccount ();
	labelDims ();
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure readAccount ()
	
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

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Output.InteractiveCreationRestricted ();
		Cancel = true;
	endif; 
	Options.Company ( ThisObject, Object.Company );
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

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure
