// Open Balance Sheet and save/load settings/variant

Call ( "Common.Init" );
CloseAll ();
Connect ();
OpenMenu ( "Sections panel / Accounting" );
OpenMenu ( "Functions menu / Reports / Balance Sheet" );

#region savingSettings
With ();
settings = Get ( "#UserSettings" );
if ( not settings.CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;
Click ( "#UserSettingsContextMenuSaveSettings" );
With ();
Set ( "#RecordDescription", "" + CurrentDate () );
Click ( "#FormSave" );
#endregion

#region loadSettings
With ();
Click ( "#UserSettingsContextMenuLoadSettings" );
With ();
Click ( "#FormChoose" );
#endregion

#region loadVariant
With ();
Click ( "#UserSettingsContextMenuLoadVariant" );
With ();
Click ( "#FormChooseStandard" );
#endregion

#region saveVariant
With ();
Click ( "#UserSettingsContextMenuSaveVariant" );
With ();
Set ( "#RecordDescription", "" + CurrentDate () );
Click ( "#FormSave" );
#endregion

#region generateReport
With ();
Click("#GenerateReport");
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
