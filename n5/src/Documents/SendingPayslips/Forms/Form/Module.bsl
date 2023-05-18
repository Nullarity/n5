// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	stillActual ();
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure stillActual ()
	
	Outdated = ( Object.Date <= CurrentSessionDate () );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing)
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		updateChangesPermission ();
	endif; 
	Options.Company ( ThisObject, Object.Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ThisObject lock Outdated;
	|Warning show Outdated;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	Object.Date = EndOfDay ( CurrentSessionDate () ); 
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	setMonth ( Object, lastPayment () );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setMonth ( Object, Date )
	
	Object.Month = EndOfMonth ( Date );
	
EndProcedure

&AtServer
Function lastPayment ()
	
	s = "
	|select allowed Payments.Date as Date
	|from (
	|	select Payments.Date as Date
	|	from (
	|		select top 1 Payments.Date as Date
	|		from Document.PayEmployees as Payments
	|		where Payments.Posted
	|		and Payments.Company = &Company
	|		order by Payments.Date desc
	|	) as Payments
	|	union all
	|	select Payments.Date
	|	from (
	|		select top 1 Payments.Date as Date
	|		from Document.PayAdvances as Payments
	|		where Payments.Posted
	|		and Payments.Company = &Company
	|		order by Payments.Date desc
	|	) as Payments
	|) as Payments
	|order by Payments.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Company", Object.Company );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Date );
	
EndFunction

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )

	if ( isNew () ) then
		if ( mailReady () ) then
			fillDocument ( true );
		else
			Output.SystemProfileEmpty ();
		endif;
	endif;

EndProcedure

&AtClient
Function isNew ()
	
	return Object.Ref.IsEmpty ()
		and Object.Employees.Count () = 0;
	
EndFunction

&AtServerNoContext
Function mailReady ()
	
	return Mailboxes.SystemMailReady ();
	
EndFunction

&AtClient
Procedure fillDocument ( Silently )
	
	if ( Forms.Check ( ThisObject, "Company", Silently ) ) then
		params = fillingParams ();
		if ( Silently ) then
			Filler.ProcessData ( params, ThisObject );
		else
			Filler.Open ( params, ThisObject );
		endif;
	endif; 
	
EndProcedure 

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "SendingPayslipsFilling";
	p.Filters = getFilters ();
	p.Background = true;
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	item = DC.CreateParameter ( "Date", Object.Month );
	filters.Add ( item );
	item = DC.CreateParameter ( "Company", Object.Company );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillTables ( Result ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure

&AtServer
Function fillTables ( val Result )
	
	table = Filler.Fetch ( Result );
	if ( table = undefined ) then
		return false;
	endif;
	employees = Object.Employees;
	if ( Result.ClearTable ) then
		employees.Clear ();
	endif; 
	employees.Load ( table );
	return true;
	
EndFunction

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
Procedure MonthOnChange ( Item )
	
	setMonth ( Object, Object.Month );
	
EndProcedure

&AtClient
Procedure Fill ( Command )
	
	fillDocument ( false );
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	applyCompany ();
	
EndProcedure

&AtServer
Procedure applyCompany ()
	
	Object.Employees.Clear ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure EmployeesEmployeeOnChange ( Item )
	
	setEmail ();
	
EndProcedure

&AtClient
Procedure setEmail ()
	
	row = Items.Employees.CurrentData;
	email = DF.Pick ( row.Employee, "Email", "" );
	if ( email <> "" ) then
		row.Email = email;
	endif;
	
EndProcedure
