#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	if ( not checkScale () ) then
		Cancel = true;
	endif;

EndProcedure

Function checkScale ()

	p = new Structure ( "Scale", Scale.Unload () );
	CollectionsSrv.ForExtension ( p );
	wrongLine = CoreExtension.GetLibrary ( "Documents" ).Discounts_CheckScale ( Conversion.ToJSON ( p ) );
	if ( wrongLine = 0 ) then
		return true;
	endif;
	Output.WrongScaleLimit ( , Output.Row ( "Scale", wrongLine, "From" ), Ref );
	return false;

EndFunction

#endif
