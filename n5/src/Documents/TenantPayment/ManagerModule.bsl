#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makeTenants ( Env );
	makeAgents ( Env );
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
	|select Documents.Date as Date, Documents.Amount as Amount, Documents.Bonus as Bonus, Documents.TenantOrder as TenantOrder
	|from Document.TenantPayment as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure makeTenants ( Env )
	
	movement = Env.Registers.Tenants.AddExpense ();
	movement.Period = Env.Fields.Date;
	movement.TenantOrder = Env.Fields.TenantOrder;
	movement.Amount = Env.Fields.Amount;
	movement.Bonus = Env.Fields.Bonus;
	
EndProcedure 

Procedure makeAgents ( Env )
	
	if ( Env.Fields.Bonus = 0 ) then
		return;
	endif; 
	movement = Env.Registers.Agents.Add ();
	movement.Period = Env.Fields.Date;
	movement.TenantOrder = Env.Fields.TenantOrder;
	movement.Bonus = Env.Fields.Bonus;
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Tenants.Write = true;
	registers.Agents.Write = true;
	
EndProcedure

#endregion

#endif