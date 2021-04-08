#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params;
var StringConnectDB;
var FileMode;
var TextScript;
var PathScript;
var PathFileDataProcessor;

Procedure Update ( IDProcess ) export
	
	ID = IDProcess;	
	Output.StartUpdateScriptProcedure ();
	StringConnectDB = InfoBaseConnectionString (); 
	FileMode = checkMode ();
	fillParams ();
	saveProcessor ();
	getScript ();
	createFile ();
	Output.RunUpdateConfigurationScript ();
	RunApp ( PathScript );
		
EndProcedure

Function checkMode ()
	
	return ( Find ( StringConnectDB, "File=" ) = 1 );
		
EndFunction

Procedure fillParams ()
	
	s = "
	|select 
	|	Constants.CloudUser as CloudUser, Constants.CloudPassword as CloudPassword,
	|	Constants.ServerCode as ServerCode
	|from Constants as Constants
	|;
	|select Users.Password as Password 
	|from Catalog.UsersPasswords as Users
	|where Users.Description = &UserName
	|;
	|select Tenant.Code as DataSeparation
	|from Catalog.Tenants as Tenant
	|where Tenant.Ref = &Tenant 
	| ";
	q = new Query ( s );
	q.SetParameter ( "UserName", UserName () );
	q.SetParameter ( "Tenant", SessionParameters.Tenant );
	result = q.ExecuteBatch ();
	data0 = result [ 0 ].Select ();
	data0.Next ();
	Params = new Structure ();
	Params.Insert ( "CloudUser", data0.CloudUser );
	Params.Insert ( "CloudPassword", data0.CloudPassword );
	Params.Insert ( "PermissionCode", ? ( data0.ServerCode = "", "exchange", data0.ServerCode ) );
	data1 = result [ 1 ].Select ();
	data1.Next ();
	Params.Insert ( "User", UserName () );
	Params.Insert ( "Password", data1.Password );
	data2 = result [ 2 ].Select ();
	data2.Next ();	
	Params.Insert ( "DataSeparation", data2.DataSeparation );
	Params.Insert ( "Path", BinDir () );
	Params.Insert ( "StringDataBase", getStringDB () );
	Params.Insert ( "StringDataBaseRunEnterprise", getStringRunEnterprise () );
	Params.Insert ( "PathFileDataProcessor" );
	
EndProcedure

Function getStringDB ()
	
	if ( FileMode ) then
		s = " /F " + """""" + NStr ( StringConnectDB, "File" ) + """""";	
	else
		s = " /S " + """""" + NStr ( StringConnectDB, "Srvr" ) + "\" + NStr ( StringConnectDB, "Ref" ) + """""";
	endif;
	return s;	

EndFunction

Function getStringRunEnterprise ()
	
	if ( FileMode ) then
		s = " /F " + """""""""" + NStr ( StringConnectDB, "File" ) + """"""""""	
	else
		s = " /S " + """""""""" + NStr ( StringConnectDB, "Srvr" ) + "\" + NStr ( StringConnectDB, "Ref" ) + """"""""""
	endif;
	return s;	

EndFunction 

Procedure getScript ()	
	
	TextScript = GetTemplate ( "Script" ).GetText ();
	for each parameter in Params do
		TextScript = StrReplace ( TextScript, "%" + parameter.Key + "%", parameter.Value );
	enddo; 
	
EndProcedure

Procedure createFile ()
	
	pathScript = TempFilesDir () + "UpdateID_" + ID + ".vbs";
	script = new TextWriter ( pathScript, TextEncoding.ANSI );
	script.Write ( TextScript ); 
	script.Close ();
	Output.SaveUpdateConfigurationScript ( new Structure ( "File", pathScript ) );
	
EndProcedure

Procedure saveProcessor () export 
	
	Params.PathFileDataProcessor = TempFilesDir () + "RereadData_" + ID + ".epf";
	processor = GetTemplate ( "RereadData" );
	processor.Write ( Params.PathFileDataProcessor );
	Output.SaveRereadExchange ( new Structure ( "File", Params.PathFileDataProcessor ) );
	
EndProcedure

#endif