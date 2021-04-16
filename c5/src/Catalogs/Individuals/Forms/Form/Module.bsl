&AtServer
var Base;
&AtClient
var ContinueSaving;
&AtClient
var IsNew;
&AtServer
var CopiedEmployee;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	initPhones ();
	Photos.Load ( ThisObject );
	loadSignature ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure initPhones ()
	
	PhoneTemplates.Set ( ThisObject, "MobilePhone, EmployeeBusinessPhone, EmployeeFax, HomePhone" );

EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	defineEmployee ();
	embedEmployee ();
	if ( Object.Ref.IsEmpty () ) then
		if ( EmployeeDefined ) then
			initEmployee ();
			CopiedEmployee = Parameters.Copy;
			if ( not CopiedEmployee.IsEmpty () ) then
				copyEmployee ();
			endif; 
		endif; 
		User = Parameters.User;
		if ( not User.IsEmpty () ) then
			fillByUser ();
		endif; 
		initPhones ();
	else
		if ( EmployeeDefined ) then
			setUser ( ThisObject );
		endif; 
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormSelectExisted show EmployeeDefined and empty ( Employee.Ref );
	|Write show empty ( Object.Ref );
	|Address Birthplace enable filled ( Object.Ref );
	|Photo show filled ( Photo );
	|Upload show empty ( Photo );
	|User show filled ( User );
	|CreateUser show empty ( User );
	|TimePage EmployeeCompany show EmployeeDefined;
	|Contractor enable Employee.EmployeeType = Enum.EmployeeTypes.Contractor;
	|Signature show filled ( Signature );
	|UploadSignature show empty ( Signature )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure defineEmployee ()

	if ( not AccessRight ( "View", Metadata.Catalogs.Employees ) ) then
		return;
	endif;
	if ( Parameters.Redirected ) then
		ref = Parameters.Employee;
	else
		ref = findEmployee ();
		if ( ref = undefined ) then
			return;
		endif; 
	endif; 
	if ( not ref.IsEmpty () ) then
		ValueToFormAttribute ( ref.GetObject (), "Employee" );
	endif;
	EmployeeDefined = true;
	
EndProcedure 

&AtServer
Procedure embedEmployee ()
	
	p = new Structure ( "Visibility", EmployeeDefined );
	SetFormFunctionalOptionParameters ( p );
	
EndProcedure 

&AtServer
Function findEmployee ()
	
	ref = Object.Ref;
	if ( ref.IsEmpty () ) then
		return undefined;
	endif; 
	s = "
	|select allowed top 1 Employees.Ref as Ref
	|from Catalog.Employees as Employees
	|where Employees.Individual = &Ref
	|and not Employees.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", ref );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

&AtServer
Procedure initEmployee ()
	
	Metafields.Constructor ( Employee );
	Employee.Currency = Application.Currency ();
	company = undefined;
	Parameters.FillingValues.Property ( "Company", company );
	if ( company = undefined ) then
		settings = Logins.Settings ( "Company" );
		company = settings.Company;
	endif; 
	Employee.Company = company;
	
EndProcedure 

&AtServer
Procedure copyEmployee ()
	
	FillPropertyValues ( Employee, CopiedEmployee, , "Ref, Code" );
	FillPropertyValues ( Object, CopiedEmployee, , "Ref, Code" );
	
EndProcedure 

&AtServer
Procedure fillByUser ()
	
	Object.FirstName = User.FirstName;
	Object.LastName = User.LastName;
	Object.Email = User.Email;
	setName ( Object );

EndProcedure 

&AtClientAtServerNoContext
Procedure setUser ( Form )
	
	Form.User = getUser ( Form.Employee.Ref );
	
EndProcedure 

&AtServerNoContext
Function getUser ( val Employee )
	
	s = "
	|select top 1 Users.Ref as User
	|from Catalog.Users as Users
	|where Users.Employee = &Employee
	|and not Users.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Employee", Employee );
	table = q.Execute ().Unload ();
	if ( table.Count () = 1 ) then
		return table [ 0 ].User;
	endif;
	return undefined;
	
EndFunction

&AtClient
Procedure OnOpen ( Cancel )
	
	IsNew = Object.Ref.IsEmpty ();
	if ( not IsNew
		and EmployeeDefined ) then
		if ( alreadyOpened () ) then
			Cancel = true;
			return;
		endif; 
	endif; 
	
EndProcedure

&AtClient
Function alreadyOpened ()
	
	windows = GetWindows ();
	for each wnd in windows do
		if ( not wnd.StartPage ) then
			if ( searchEmployee ( wnd.GetContent () ) ) then
				// Bug workaround: do not use Activate () method because it will not work since 8.3.10
				wnd.Content [ 0 ].Open ();
				return true;
			endif;
		endif; 
	enddo; 
	return false;
	
EndFunction 

&AtClient
Function searchEmployee ( Form )
	
	return TypeOf ( Form ) = Type ( Enum.FrameworkManagedForm () ) 
	and Form.FormName = "Catalog.Individuals.Form.Form"
	and Form.Employee.Ref = Employee.Ref;
	
EndFunction 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageUserIsSaved () ) then
		if ( EmployeeDefined ) then
			if ( Parameter = Employee.Ref ) then
				updateUser ();
			endif; 
		endif; 
	endif; 
	
EndProcedure

&AtClient
Procedure updateUser ()
	
	setUser ( ThisObject );
	Appearance.Apply ( ThisObject, "User" );
	
EndProcedure 

&AtClient
Procedure OnClose ( Exit )
	
	if ( picking () ) then
		NotifyChoice ( Employee.Ref );
	endif; 
	
EndProcedure

&AtClient
Function picking ()
	
	return ChoiceMode
	and CloseOnChoice
	and EmployeeDefined
	and not Employee.Ref.IsEmpty ();
	
EndFunction 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( EmployeeDefined ) then
		if ( FormAttributeToValue ( "Object" ).CheckFilling () ) then
			Catalogs.Employees.Update ( Employee, Object );
			if ( not FormAttributeToValue ( "Employee" ).Check  () ) then
				Cancel = true;
			endif; 
		endif; 
		CheckedAttributes.Clear ();
	endif;
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( not ContinueSaving
		and alreadyExists () ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

&AtClient
Function alreadyExists ()
	
	name = Object.Description;
	if ( nameFound ( Object.Ref, name ) ) then
		Output.ValueAlreadyExists ( ThisObject, , new Structure ( "Value", name ) );
		return true;
	endif; 
	return false;
	
EndFunction 

&AtServerNoContext
Function nameFound ( val Ref, val Description )
	
	SetPrivilegedMode ( true );
	return DF.GetOriginal ( Ref, "Description", Description ) <> undefined;
	
EndFunction 

&AtClient
Procedure ValueAlreadyExists ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	ContinueSaving = true;
	Write ();
	ContinueSaving = false;
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( EmployeeDefined ) then
		saveEmployee ( CurrentObject );
	endif; 
	Photos.Save ( ThisObject, CurrentObject );
	if ( NewSignature ) then
		saveSignature ( CurrentObject );
	endif;
	updateEmployees ();
	
EndProcedure

&AtServer
Procedure saveEmployee ( CurrentObject )
	
	obj = FormAttributeToValue ( "Employee" );
	obj.Individual = CurrentObject.Ref;
	if ( obj.IsNew () ) then
		DF.SetNewCode ( obj );
	endif;
	obj.Write ();
	ValueToFormAttribute ( obj, "Employee" );
	
EndProcedure

&AtServer
Procedure updateEmployees ()
	
	if ( Object.Ref.IsEmpty () ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	for each ref in getEmployees () do
		obj = ref.GetObject ();
		obj.DataExchange.Load = true;
		Catalogs.Employees.Update ( obj, Object );
		obj.Write ();
	enddo;
	
EndProcedure 

&AtServer
Function getEmployees ()
	
	s = "
	|select Employees.Ref as Ref
	|from Catalog.Employees as Employees
	|where Employees.Individual = &Ref
	|and Employees.Ref <> &Employee
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Employee", Employee.Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );

EndFunction 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	notifyRelatives ();
	IsNew = false;
	
EndProcedure

&AtClient
Procedure notifyRelatives ()
	
	if ( EmployeeDefined ) then
		ref = Employee.Ref;
		if ( IsNew ) then
			NotifyWritingNew ( ref );
		else
			NotifyChanged ( ref );
		endif; 
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure NameOnChange ( Item )
	
	setName ( Object );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setName ( Object )
	
	Object.Description = ContactsForm.FullName ( Object );
	
EndProcedure 

&AtClient
Procedure PhoneStartChoice ( Item, ChoiceData, StandardProcessing )
	
	PhoneTemplates.Choice ( ThisObject, Item );

EndProcedure

&AtClient
Procedure EmployeeTypeOnChange ( Item )
	
	applyEmployeeType ();
	
EndProcedure

&AtClient
Procedure applyEmployeeType ()
	
	Employee.Contractor = undefined;
	Appearance.Apply ( ThisObject, "Employee.EmployeeType" );
	
EndProcedure 

&AtClient
Procedure SelectExisted ( Command )
	
	OpenForm ( "Catalog.Individuals.ChoiceForm", , ThisObject, true, , , new NotifyDescription ( "AnotherIndividual", ThisObject ) );
	
	
EndProcedure

&AtClient
Procedure AnotherIndividual ( Individual, Params ) export
	
	if ( Individual = undefined ) then
		return;
	endif; 
	loadIndividual ( Individual );
	
EndProcedure 

&AtServer
Procedure loadIndividual ( val Ref )
	
	obj = Ref.GetObject ();
	ValueToFormAttribute ( obj, "Object" );
	Photos.Load ( ThisObject );
	loadSignature ();
	Modified = true;
	Appearance.Apply ( ThisObject );
	
EndProcedure 

// *****************************************
// *********** Photo

&AtClient
Procedure PhotoClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	Photos.Upload ( ThisObject );
	
EndProcedure

&AtClient
Procedure Upload ( Command )
	
	Photos.Upload ( ThisObject );
	
EndProcedure

&AtClient
Procedure ClearPhoto ( Command )
	
	Photos.Remove ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadSignature ()
	
	data = InformationRegisters.Signatures.Get ( new Structure ( "Individual", Object.Ref ) ).Signature.Get ();
	if ( data = undefined ) then
		Signature = undefined;
	else
		Signature = PutToTempStorage ( data );
	endif; 
	NewSignature = false;
	
EndProcedure 


&AtServer
Procedure saveSignature ( CurrentObject )
	
	r = InformationRegisters.Signatures.CreateRecordManager ();
	r.Individual = CurrentObject.Ref;
	if ( Signature = "" ) then
		r.Delete ();
	else
		r.Signature = new ValueStorage ( GetFromTempStorage ( Signature ) );
		r.Write ();
	endif; 
	NewSignature = false;
	
EndProcedure 

&AtClient
Procedure StartUploading ( Result, Params ) export
	
	BeginPutFile ( new NotifyDescription ( "CompleteUpload", ThisObject ), , , true, UUID );
	
EndProcedure 

&AtClient
Procedure CompleteUpload ( Result, Address, FileName, Params ) export
	
	if ( not Result ) then
		return;
	endif; 
	if ( not FileSystem.Picture ( FileName ) ) then
		return;
	endif; 
	Photo = Address;
	Modified = true;
	NewPhoto = true;
	Appearance.Apply ( ThisObject, "Photo" );

EndProcedure 

// *****************************************
// *********** Signature

&AtClient
Procedure SignatureClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	applyUploadSignature ();
	
EndProcedure

&AtClient
Procedure applyUploadSignature ()
	
	callback = new NotifyDescription ( "StartUploadingSignature", ThisObject );
	LocalFiles.Prepare ( callback );
	
EndProcedure 

&AtClient
Procedure StartUploadingSignature ( Result, Params ) export
	
	BeginPutFile ( new NotifyDescription ( "CompleteUploadSignature", ThisObject ), , , true, UUID );
	
EndProcedure 

&AtClient
Procedure CompleteUploadSignature ( Result, Address, FileName, Params ) export
	
	if ( not Result ) then
		return;
	endif; 
	if ( not FileSystem.Picture ( FileName ) ) then
		return;
	endif; 
	Signature = Address;
	Modified = true;
	NewSignature = true;
	Appearance.Apply ( ThisObject, "Signature" );

EndProcedure 

&AtClient
Procedure UploadSignature ( Command )
	
	applyUploadSignature ();
	
EndProcedure

&AtClient
Procedure ClearSignature ( Command )
	
	removeSignature ();
	Appearance.Apply ( ThisObject, "Signature" );
	
EndProcedure

&AtClient
Procedure removeSignature ()
	
	Signature = "";
	Modified = true;
	NewSignature = true;
	
EndProcedure 

// *****************************************
// *********** Variables Initialization

ContinueSaving = false;
