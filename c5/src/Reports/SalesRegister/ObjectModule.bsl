#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export	
	
	defineMethods ();
	
EndProcedure

Procedure defineMethods ()
	
	settings = Params.Settings;
	DC.GetParameter ( settings, "MethodCash" ).Value = String ( Enums.PaymentMethods.Cash );
	DC.GetParameter ( settings, "MethodCard" ).Value = String ( Enums.PaymentMethods.Card );
	DC.GetParameter ( settings, "MethodOther" ).Value = String ( Enums.PaymentMethods.Other );
	
EndProcedure 

#endif