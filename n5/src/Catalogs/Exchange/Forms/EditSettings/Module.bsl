
&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	getConstants ();	
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	ShowSymbols = false;
	showSymbols ();
	Modified = false;
	
EndProcedure

&AtServer 
Procedure getConstants ()
	
	s = "
	|select Constants.ClusterAdministrator as ClusterAdministrator, Constants.ClusterPassword as ClusterPassword,
	|	Constants.ServerAdministrator as ServerAdministrator, Constants.ServerPassword as ServerPassword,
	|	Constants.ServerCode as ServerCode  
	|from Constants as Constants
	|";
	q = new Query ( s );
	result = q.Execute ();
	select = result.Select ();
	select.Next ();
	ClusterAdministrator = select.ClusterAdministrator;
	ClusterPassword = select.ClusterPassword;
	ServerAdministrator = select.ServerAdministrator;
	ServerPassword = select.ServerPassword;
	ServerCode = select.ServerCode;
	
EndProcedure

&AtClient
Procedure ClusterAdministratorOnChange ( Item )
	
	Modified = true;
	
EndProcedure

&AtClient
Procedure ClusterPasswordOnChange ( Item )
	
	Modified = true;	
	
EndProcedure

&AtClient
Procedure ServerAdministratorOnChange ( Item )
	
	Modified = true;
	
EndProcedure

&AtClient
Procedure ServerPasswordOnChange ( Item )
	
	Modified = true;
	
EndProcedure

&AtClient
Procedure PermissionCodeOnChange ( Item )
	
	Modified = true;
	
EndProcedure

&AtClient
Procedure ShowSymbolsOnChange ( Item )
	
	showSymbols ();
	
EndProcedure

&AtClient
Procedure showSymbols ()
	
	Items.ClusterPassword.PasswordMode = not ShowSymbols;
	Items.ServerPassword.PasswordMode = not ShowSymbols;
	
EndProcedure 

&AtClient
Procedure WriteConstants ( Command )
	
	if ( Modified ) then
		setValues ();
	endif;
	Close ();	
	
EndProcedure

&AtServer
Procedure setValues ()
	
	Constants.ClusterAdministrator.Set ( ClusterAdministrator );
	Constants.ClusterPassword.Set ( ClusterPassword );
	Constants.ServerAdministrator.Set ( ServerAdministrator );
	Constants.ServerPassword.Set ( ServerPassword );
	Constants.ServerCode.Set ( ServerCode );
	
EndProcedure