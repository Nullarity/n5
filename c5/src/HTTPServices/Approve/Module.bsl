
Function SalesGet ( Request )
	
	SetPrivilegedMode ( true );
	p = fetchParams ( "User, ID, Action", Request );
	record = applyRequest ( p );
	notifyUser ( record );
	return success ();
	
EndFunction

Function fetchParams ( Params, Request )
	
	p = new Structure ( Params );
	data = Conversion.MapToStruct ( Request.QueryOptions );
	FillPropertyValues ( p, data );
	return p;
	
EndFunction 

Function applyRequest ( Params )
	
	invoice = Documents.РеализацияТМЦ.GetRef ( new UUID ( Params.ID ) );
	r = InformationRegisters.Requests.CreateRecordManager ();
	r.Document = invoice;
	r.Read ();
	r.Date = CurrentSessionDate ();
	r.Resolution = Enums.Resolutions [ Params.Action ];
	r.Responsible = Catalogs.Пользователи.FindByCode ( Params.User );
	r.Write ();
	return r;
	
EndFunction

Procedure notifyUser ( Record )
	
	p = new Structure ( "Creator, Invoice, Resolution, Responsible" );
	FillPropertyValues ( p, Record );
	if ( Application.Testing () ) then
		PermissionsMailing.NotifyUser ( p );
	else
		params = new Array ();
		params.Add ( p );
		BackgroundJobs.Execute ( "PermissionsMailing.NotifyUser", params );
	endif;
	
EndProcedure

Function success ()
	
	html = "
	|<!DOCTYPE html>
	|<head><meta charset=""UTF-8""></head>
	|<html>
	|<body>
	|<p>" + Output.RemoteActionApplied () + "
	|</p>
	|<button onclick='window.close();'>Закрыть</button>
	|</body>
	|</html>
	|";
	response = new HTTPServiceResponse ( 200 );
	response.SetBodyFromString ( html );
	return response;

EndFunction
