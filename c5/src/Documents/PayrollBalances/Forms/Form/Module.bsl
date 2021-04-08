&AtServer
var Copy;
&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		if ( Copy ) then
			BalancesForm.FixDate ( ThisObject );
		else
			BalancesForm.CheckParameters ( ThisObject );
		endif;
		DocumentForm.SetCreator ( Object );
	endif;
	initAccounts ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure initAccounts ()
	
	table = getAccounts ();
	for each row in table do
		method = row.Method;
		account = row.Account;
		if ( method = Enums.Calculations.IncomeTax
			or method = Enums.Calculations.FixedIncomeTax ) then
			IncomeTaxAccount = account;
		elsif ( method = Enums.Calculations.MedicalInsuranceEmployee ) then
			MedicalAccount = account;
		elsif ( method = Enums.Calculations.SocialInsuranceEmployee ) then
			EmployeesDebt = account;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function getAccounts ()
	
	s = "
	|select top 1 Taxes.Method as Method, Taxes.Account as Account
	|from ChartOfCalculationTypes.Taxes as Taxes
	|where not Taxes.DeletionMark
	|and Taxes.Account <> value ( ChartOfAccounts.General.EmptyRef )
	|and Taxes.Method in ( value ( Enum.Calculations.IncomeTax ), value ( Enum.Calculations.FixedIncomeTax ) )
	|union all
	|select top 1 Taxes.Method, Taxes.Account
	|from ChartOfCalculationTypes.Taxes as Taxes
	|where not Taxes.DeletionMark
	|and Taxes.Account <> value ( ChartOfAccounts.General.EmptyRef )
	|and Taxes.Method = value ( Enum.Calculations.MedicalInsuranceEmployee )
	|union all
	|select value ( Enum.Calculations.SocialInsuranceEmployee ), Settings.Value
	|from InformationRegister.Settings.SliceLast ( , Parameter = value ( ChartOfCharacteristicTypes.Settings.EmployeesOtherDebt ) ) as Settings
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Table Employees

&AtClient
Procedure EmployeesOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure EmployeesOnStartEdit ( Item, NewRow, Clone )
	
	if ( not NewRow
		or Clone ) then
		return;
	endif; 
	setTaxes ();
	
EndProcedure

&AtClient
Procedure setTaxes ()
	
	TableRow.IncomeTaxAccount = IncomeTaxAccount;
	TableRow.MedicalAccount = MedicalAccount;
	TableRow.EmployeesDebt = EmployeesDebt;

EndProcedure 

&AtClient
Procedure EmployeesEmployeeOnChange ( Item )
	
	HiringForm.SetIndividual ( TableRow );
	
EndProcedure

&AtClient
Procedure EmployeesCompensationOnChange ( Item )
	
	setAccount ();
	
EndProcedure

&AtClient
Procedure setAccount ()
	
	TableRow.Account = DF.Pick ( TableRow.Compensation, "Account" );
	
EndProcedure 
