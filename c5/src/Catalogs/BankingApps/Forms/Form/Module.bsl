// *****************************************
// *********** Form events

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )

	CurrentObject.Description = Object.Application;

EndProcedure
 
// *****************************************
// *********** Group Form
 
&AtClient
Procedure UnloadingStartChoice ( Item, ChoiceData, StandardProcessing )

	StandardProcessing = false;
	BankingForm.ChooseFile ( Object.Application, Item );

EndProcedure

&AtClient
Procedure UnloadingSalaryStartChoice ( Item, ChoiceData, StandardProcessing )

	StandardProcessing = false;
	BankingForm.ChooseSalaryFile ( Object.Application, Item );

EndProcedure

&AtClient
Procedure LoadingStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	BankingForm.ChooseLoadingFile ( Object.Application, Item );
	
EndProcedure
