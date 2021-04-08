&AtServer
var Env;
&AtServer
var Copy;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		DocumentForm.Init ( Object );
		fillNew ();
	endif;
	setLinks ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|Extended enable filled ( Object.Employee );
	|Compensation disable Object.Extension;
	|DateStart disable Object.Extension;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	company = settings.Company;
	Object.Company = company;
	Object.Compensation = ChartsOfCalculationTypes.Compensations.Default ( Enums.Calculations.SickDays );
	Object.SeniorityAmendment = InformationRegisters.Settings.GetLast ( , new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.SeniorityAmendment ) ).Value;
	individual = Object.Individual;
	if ( not individual.IsEmpty () ) then
		Object.Employee = InformationRegisters.Employees.GetByIndividual ( individual, company );
	endif;
	
EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", getBase ( Object.Ref ) );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	ViewPayrolls = AccessRight ( "View", Metadata.Documents.Payroll );
	if ( not ViewPayrolls 
		or isNew () ) then
		return;
	endif; 
	s = "
	|// #Payrolls
	|select Compensations.Ref as Document, Compensations.Ref.Date as Date, Compensations.Ref.Number as Number
	|from Document.Payroll.Compensations as Compensations
	|where Compensations.Reference = &Ref
	|and Compensations.Ref.Posted
	|and not Compensations.Ref.DeletionMark
	|group by Compensations.Ref
	|order by Date
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Function getBase ( Ref )
	
	if ( not Ref.Extension ) then
		return Ref;		
	endif;
	return getBase ( Ref.Base );
	
EndFunction

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	parts.Add ( URLPanel.DocumentsToURL ( Env.Payrolls, meta.Payroll ) );
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure EmployeeOnChange ( Item )
	
	applyEmployee ();
	
EndProcedure

&AtServer
Procedure applyEmployee ()
	
	Object.Extension = false;
	Object.Individual = DF.Pick ( Object.Employee, "Individual" );
	applyExtension ();
	Appearance.Apply ( ThisObject, "Object.Employee" );
	
EndProcedure

&AtServer
Procedure applyExtension ()
	
	if ( Object.Extension ) then
		setBase ();
		if ( ValueIsFilled ( Object.Base ) ) then
			Object.Compensation = Object.Base.Compensation;
			Object.DateStart = EndOfDay ( Object.Base.DateEnd ) + 1;	
		else
			Object.Extension = false;
		endif;
	endif;
	if ( not Object.Extension ) then
		Object.Base = undefined;
	endif;
	Appearance.Apply ( ThisObject, "Object.Extension" );	
	
EndProcedure

&AtServer
Procedure setBase ()
	
	q = new Query ();
	q.Text = "
	|select top 1 SickLeaves.Ref as Ref 
	|from Document.SickLeave as SickLeaves  
	|where SickLeaves.Employee = &Employee
	|and SickLeaves.DateEnd < &Date
	|and SickLeaves.Ref <> &Ref
	|order by SickLeaves.DateEnd desc
	|";
	q.SetParameter ( "Employee", Object.Employee );
	q.SetParameter ( "Date", Object.Date );
	q.SetParameter ( "Ref", Object.Ref );
	result = q.Execute ().Unload ();
	Object.Base = ? ( result.Count () = 0, undefined, result [ 0 ].Ref );
	
EndProcedure

&AtClient
Procedure ExtensionOnChange ( Item )
	
	applyExtension ();	
	
EndProcedure
