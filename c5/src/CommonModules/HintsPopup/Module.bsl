Procedure Open ( Hint, HintKey ) export
	
	if ( HintsPopupSrv.Show ( HintKey ) ) then
		p = new Structure ( "Text, HintKey", Hint, HintKey );
		OpenForm ( "CommonForm.Hint", p );
	endif;;
	
EndProcedure
