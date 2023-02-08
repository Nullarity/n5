#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makeTenants ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )
	
	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );

EndProcedure 

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Amount as Amount, Documents.Bonus as Bonus
	|from Document.TenantOrder as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure makeTenants ( Env )
	
	movement = Env.Registers.Tenants.Add ();
	movement.Period = Env.Fields.Date;
	movement.TenantOrder = Env.Ref;
	movement.Amount = Env.Fields.Amount;
	movement.Bonus = Env.Fields.Bonus;
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	Env.Registers.Tenants.Write = true;
	
EndProcedure

#endregion

Function Paid ( Ref, TenantPayment = undefined ) export
	
	s = "
	|select top 1 TenantPayments.Ref as TenantPayment
	|from Document.TenantPayment as TenantPayments
	|where TenantPayments.TenantOrder = &Ref
	|and TenantPayments.Posted
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	SetPrivilegedMode ( true );
	table = q.Execute ().Unload ();
	SetPrivilegedMode ( false );
	if ( table.Count () = 0 ) then
		return false;
	else
		TenantPayment = table [ 0 ].TenantPayment;
		return true;
	endif; 
	
EndFunction 

#endif