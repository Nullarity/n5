#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var IsNew;
var OldParent;

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	IsNew = IsNew ();
	setFolder ();
	inheritOffline ();
	OldParent = Ref.Parent;
	setOffline ();

EndProcedure

Procedure setFolder ()
	
	Folder = not IsNew and hasChild ( Ref );
	
EndProcedure 

Function hasChild ( Ancestor )
	
	s = "
	|select top 1 1, Accounts.Ref
	|from ChartOfAccounts.General as Accounts
	|where Accounts.Parent = &Ancestor
	|";
	q = new Query ( s );
	q.SetParameter ( "Ancestor", Ancestor );
	return not q.Execute ().IsEmpty ();
	
EndFunction 

Procedure inheritOffline ()
	
	if ( Offline
		or Parent.IsEmpty () ) then
		return;
	endif; 
	Offline = DF.Pick ( Parent, "Offline" );
	
EndProcedure

Procedure setOffline () 

	if ( DeletionMark ) then
		Offline = true;
	elsif ( Ref.DeletionMark ) then
		Offline = false;
	endif;

EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( OldParent <> Parent ) then
		changeParents ();
	endif;
	if ( Offline ) then
		disableChildren ();
	endif;
	
EndProcedure

Procedure changeParents ()
	
	if ( not OldParent.IsEmpty () ) then
		refreshFolder ( OldParent );
	endif; 
	if ( not Parent.IsEmpty () ) then
		refreshFolder ( Parent );
	endif; 
	
EndProcedure 

Procedure refreshFolder ( Reference )

	children = hasChild ( Reference );
	if ( children <> Reference.Folder ) then
		obj = Reference.GetObject ();
		obj.Folder = children;
		obj.Write ();
	endif; 
	
EndProcedure 

Procedure disableChildren ()
	
	if ( IsNew ) then
		return;
	endif; 
	children = onlineChildren ();
	for each child in children do
		obj = child.GetObject ();
		obj.Offline = true;
		obj.DataExchange.Load = true;
		obj.Write ();
	enddo; 
	
EndProcedure 

Function onlineChildren ()
	
	s = "
	|select Accounts.Ref as Ref
	|from ChartOfAccounts.General as Accounts
	|where Accounts.Parent in hierarchy ( &Ancestor )
	|and not Accounts.Offline
	|";
	q = new Query ( s );
	q.SetParameter ( "Ancestor", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 

#endif