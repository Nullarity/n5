Function GetAccess ( val Ref, val Date ) export

	result = defineAccess ( Ref, Date );
	if ( result.Allowed
		and not Ref.IsEmpty () ) then
		oldDate = DF.Pick ( Ref, "Date" );
		if ( BegOfDay ( Date ) <> BegOfDay ( oldDate ) ) then
			result = defineAccess ( Ref, oldDate );
		endif;
	endif;
	return result;
	
EndFunction

Function defineAccess ( Ref, Date )
	
	rights = getRights ( Ref, Date );
	result = new Structure ( "Allowed, Action, Warning", false, undefined, false );
	if ( Ref.IsEmpty () ) then
		//@skip-warning
		stub = accessDenied ( Rights, Enums.AccessRights.Create, result )
		or accessDenied ( Rights, Enums.AccessRights.Any, result )
		or accessAllowed ( Rights, Enums.AccessRights.Create, result )
		or accessAllowed ( Rights, Enums.AccessRights.Any, result );
	else
		//@skip-warning
		stub = accessDenied ( Rights, Enums.AccessRights.Edit, result )
		or accessDenied ( Rights, Enums.AccessRights.UndoPosting, result )
		or accessDenied ( Rights, Enums.AccessRights.Any, result )
		or accessAllowed ( Rights, Enums.AccessRights.Edit, result )
		or accessAllowed ( Rights, Enums.AccessRights.UndoPosting, result )
		or accessAllowed ( Rights, Enums.AccessRights.Any, result );
	endif;
	return result;
	
EndFunction

Function accessDenied ( Rights, Action, Result )
	
	record = Rights [ Action ];
	if ( record <> undefined
		and record.Access = Enums.AllowDeny.Deny ) then
		Result.Allowed = false;
		Result.Action = Action;
		Result.Warning = record.Warning;
		return true;
	endif;
	return false;
	
EndFunction

Function accessAllowed ( Rights, Action, Result )
	
	record = Rights [ Action ];
	if ( record <> undefined
		and record.Access = Enums.AllowDeny.Allow ) then
		Result.Allowed = true;
		Result.Action = Action;
		return true;
	endif;
	return false;
	
EndFunction

Function getRights ( Ref, Date )
	
	rightsMap = new Map ();
	table = getRightsTable ( Ref, Date );
	for each row in table do
		if ( rightsMap [ row.Action ] = undefined ) then
			rightsMap [ row.Action ] = new Structure ( "Access, Warning", row.Access, row.Warning );
		endif; 
	enddo; 
	return rightsMap;
	
EndFunction 

Function getRightsTable ( Ref, Date )
	
	s = "
	|select undefined as User
	|into UserAndGroups
	|union
	|select &User
	|union
	|select Users.Membership
	|from InformationRegister.Membership as Users
	|where Users.User = &User
	|and not Users.Membership.DeletionMark
	|;
	|select Rights.Access as Access, Rights.Action as Action, Rights.Warning as Warning,
	|	case when Rights.Target = undefined then 0
	|			+ case when Rights.Document <> value ( Catalog.Metadata.EmptyRef ) then 5 else 0 end
	|			+ case when Rights.Access = value ( Enum.AllowDeny.Deny ) then 1000 else 0 end
	|		when Rights.Target refs Catalog.Membership then 10
	|			+ case when Rights.Document <> value ( Catalog.Metadata.EmptyRef ) then 5 else 0 end
	|			+ case when Rights.Access = value ( Enum.AllowDeny.Deny ) then 1000 else 0 end
	|		else 100
	|			+ case when Rights.Document <> value ( Catalog.Metadata.EmptyRef ) then 5 else 0 end
	|			+ case when Rights.Access = value ( Enum.AllowDeny.Deny ) then 1000 else 0 end
	|	end as Weight
	|from InformationRegister.Rights as Rights
	|where not Rights.Disabled
	|and Rights.Target in ( select User from UserAndGroups )
	|and Rights.Document in ( value ( Catalog.Metadata.EmptyRef ), Document = &Document )
	|and (
	|	( Rights.Method = value ( Enum.RestrictionMethods.Period )
	|		and &DocumentDate > Rights.DateStart
	|		and ( &DocumentDate < Rights.DateEnd or Rights.DateEnd = datetime ( 1, 1, 1 ) ) )
	|	or
	|	( Rights.Method = value ( Enum.RestrictionMethods.Span )
	|		and Rights.Access = value ( Enum.AllowDeny.Allow )
	|		and &DocumentDate between dateadd ( &OperationalTime, day, - Rights.Duration ) and dateadd ( &OperationalTime, day, Rights.Duration ) )
	|	or
	|	( Rights.Method = value ( Enum.RestrictionMethods.Span )
	|		and Rights.Access = value ( Enum.AllowDeny.Deny )
	|		and &DocumentDate not between dateadd ( &OperationalTime, day, - Rights.Duration ) and dateadd ( &OperationalTime, day, Rights.Duration ) )
	|	or
	|	( Rights.Method = value ( Enum.RestrictionMethods.Duration )
	|		and Rights.Access = value ( Enum.AllowDeny.Deny )
	|		and datediff ( &DocumentDate, &OperationalTime, day ) >= Rights.Duration )
	|	or
	|	( Rights.Method = value ( Enum.RestrictionMethods.Duration )
	|		and Rights.Access = value ( Enum.AllowDeny.Allow )
	|		and datediff ( &DocumentDate, &OperationalTime, day ) <= Rights.Duration )
	|	or
	|		Rights.Method = value ( Enum.RestrictionMethods.EmptyRef ) )
	|and ( &OperationalTime < Rights.Expiration or Rights.Expiration = datetime ( 1, 1, 1 ) )
	|order by Weight desc
	|";
	q = new Query ( s );
	q.TempTablesManager = new TempTablesManager ();
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Document", MetadataRef.Get ( Metadata.FindByType ( TypeOf ( Ref ) ).FullName () ) );
	q.SetParameter ( "DocumentDate", Date );
	q.SetParameter ( "OperationalTime",	CurrentDate () );
	return q.Execute ().Unload ();
	
EndFunction 
