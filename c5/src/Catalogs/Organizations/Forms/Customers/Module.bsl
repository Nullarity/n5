// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Forms.InsideMobileHomePage ( ThisObject ) ) then
		Cancel = true;
		return;
	endif;
	UserTasks.InitList ( List );
	filterByCustomer ();
	
EndProcedure

&AtServer
Procedure filterByCustomer ()
	
	DC.SetFilter ( List, "Customer", true );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CountryFilterOnChange ( Item )
	
	filterByCountry ();
	
EndProcedure

&AtServer
Procedure filterByCountry ()
	
	DC.ChangeFilter ( List, "PaymentAddress.Country", CountryFilter, not CountryFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure StateFilterOnChange ( Item )
	
	filterByState ();
	
EndProcedure

&AtServer
Procedure filterByState ()
	
	DC.ChangeFilter ( List, "PaymentAddress.State", StateFilter, not StateFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure CityFilterOnChange ( Item )
	
	filterByCity ();
	
EndProcedure

&AtServer
Procedure filterByCity ()
	
	DC.ChangeFilter ( List, "PaymentAddress.City", CityFilter, not CityFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
