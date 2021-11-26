// Please do not use NStr () function in complex expressions!
//
// The following variant is incorrect:
//	text = "<" + NStr ( "en='test'" ) + ">";
//	return text;
//
// The following is incorrect:
//	text = NStr ( "en='test'" );
//	return "<" + text + ">";

Function FormatStr ( Str, Params ) export

	if ( Params = undefined ) then
		return Str;
	endif;
	result = Str;
	p = new Array ();
	for each parameter in Params do
		p.Add ( parameter.Key );
	enddo;
	indexOfMax = 0;
	while ( true ) do
		i = 0;
		max = 0;
		for each param in p do
			a = StrLen ( param );
			if ( a > max ) then
				max = a;
				indexOfMax = i;
			endif;
			i = i + 1;
		enddo;
		k = p [ indexOfMax ];
		p.Delete ( indexOfMax );
		result = StrReplace ( result, "%" + k, Params [ k ] );
		if ( p.UBound () = -1 ) then
			break;
		endif;
	enddo;
	return result;

EndFunction

Procedure PutMessage ( Text, Params, Field, DataKey, DataPath ) export

	msg = new UserMessage ();
	s = Output.FormatStr ( Text, Params );
	#if ( Server or ExternalConnection ) then
		property = Enum.AdditionalPropertiesInteractive ();
		interactive = ( Params = undefined  ) or not Params.Property ( property ) or Params [ property ];
	#else
		interactive = false;
	#endif
	if ( interactive ) then
		msg.DataPath = DataPath;
		msg.Field = Field;
		msg.DataKey = DataKey;
	else
		prefix = new Array ();
		if ( ValueIsFilled ( DataKey ) ) then
			prefix.Add ( String ( DataKey ) );
			table = getTable ( Field );
			if ( table <> undefined ) then
				name = DataKey.Metadata ().TabularSections [ table.Name ].Presentation ();
				prefix.Add ( Output.TableAndRow ( new Structure ( "Table, Row", name, table.Row ) ) );
			endif;
		endif;
		if ( prefix.Count () > 0 ) then
			s = StrConcat ( prefix, ", " ) + ": " + s;
		endif;
	endif;
	msg.Text = s;
	msg.Message ();

EndProcedure

&AtServer
Procedure putExchangeMessage ( Text, Params = Undefined, Status = undefined, Log = true, Protocol = false, EventName = "ScheduledJob.Exchange" )

	s = Output.FormatStr ( Text, Params );
	level = ? ( Status = undefined, EventLogLevel.Information, Status );
	#if ( Server ) then
		if ( Log ) then
			WriteLogEvent ( EventName, level, , , s );
		endif;
	#endif
	if ( Protocol ) then
		writeProtocol ( CurrentDate (), s );
	endif;
	message ( s );

EndProcedure

&AtServer
Procedure writeProtocol ( Date, Message ) export

	protocol = new TextWriter ();
	fileProtocol = getFileProtocol ( Date );
	protocol.Open ( fileProtocol, TextEncoding.ANSI, , true, );
	protocol.WriteLine ( " - " + Date + " - MSG: " + Message );
	protocol.Close ();

EndProcedure

Function getFileProtocol ( DateEvent )

	return TempFilesDir () + "ExchangeProtocol_" + Format ( DateEvent, "DF=dd.MM.yyyy" ) + ".txt";

EndFunction

&AtClient
Procedure putUserNotification ( Text, Params, NavigationLink, Explanation, Picture )

	#if ( MobileClient ) then
		PutMessage ( Text + Chars.LF + Explanation, Params, "", "", "" );
	#else
		ShowUserNotification ( Output.FormatStr ( Text, Params ), NavigationLink, Output.FormatStr ( Explanation, Params ), Picture );
	#endif

EndProcedure

&AtClient
Procedure OpenMessageBox ( Text, Params, ProcName, Module, CallbackParams, Timeout, Title ) export

	if ( Module = undefined ) then
		handler = undefined;
	else
		handler = new NotifyDescription ( ProcName, Module, CallbackParams );
	endif;
	if ( handler = undefined ) then // Bug workaround 8.3.3.658 for WebClient: it doesn't understand "Undefined" in first paramer
		ShowMessageBox ( , Output.FormatStr ( Text, Params ), Timeout, ? ( Title = "", MetadataPresentation (), Title ) );
	else
		ShowMessageBox ( handler, Output.FormatStr ( Text, Params ), Timeout, ? ( Title = "", MetadataPresentation (), Title ) );
	endif;

EndProcedure

&AtClient
Procedure OpenQueryBox ( Text, Params, ProcName, Module, CallbackParams, Buttons, Timeout, DefaultButton, Title ) export

	ShowQueryBox ( new NotifyDescription ( ProcName, Module, CallbackParams ), Output.FormatStr ( Text, Params ), Buttons, Timeout, DefaultButton, ? ( Title = "", MetadataPresentation (), Title ) );

EndProcedure

Function getTable ( Field )

	i = StrFind ( Field, "[" );
	j = StrFind ( Field, "]", , i );
	if ( i = 0 or j = 0 ) then
		return undefined;
	endif;
	name = TrimAll ( Left ( Field, i - 1 ) );
	row = 1 + Number ( Mid ( Field, i + 1, j - i - 1 ) );
	return new Structure ( "Name, Row", name, row );

EndFunction

Function Row ( Table, LineNumber, Field ) export

	return Table + "[" + Format ( LineNumber - 1, "NG=;NZ=" ) + "]." + Field;

EndFunction

Function TableAndRow ( Params ) export

	text = NStr ( "en='table %Table [%Row]'; ro='tabel %Table [%Row]'; ru='таблица %Table [%Row]'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Function MetadataPresentation () export

	text = NStr ( "en='Contabilizare'; ro='Contabilizare'; ru='Contabilizare'" );
	return text;

EndFunction

&AtClient
Procedure CommandForDeletionMarkNotSupported ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "CommandForDeletionMarkNotSupported" ) export

	text = NStr ( "en='Can''t apply action to the element marked for removal'; ro='Acțiunea nu poate fi aplicată la elementul marcat pentru ștergere'; ru='Действие нельзя применить к помеченному на удаление элементу'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure CommandForFolderNotSupported ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "CommandForFolderNotSupported" ) export

	text = NStr ( "en='Can''t apply action to the folder'; ro='Acțiunea nu poate fi aplicată unui dosar'; ru='Действие нельзя применить к папке'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure MetadataLoadSuccessfully ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "MetadataLoadSuccessfully" ) export

	text = NStr ( "en='Metadata was downloaded successfully'; ro='Metadatele au fost încărcate cu succes'; ru='Метаданные успешно загружены'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Procedure CommonReportOpenError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This report is an official report and it cannot be opened interactively '; ro='Acest raport este oficial și nu este destinat pentru descoperirea interactivă'; ru='Данный отчет является служебным и не предназначен для интерактивного открытия'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ClickGenerateReport () export

	text = NStr ( "en='Press the ""Generate"" button to create a report'; ro='Faceți clic pe Generare pentru a genera raportul'; ru='Нажмите кнопку Сформировать для формирования отчета'" );
	return text;

EndFunction

&AtServer
Function LoadReportSettings () export

	text = NStr ( "en='Report settings'; ro='Setări raport'; ru='Настройки отчета'" );
	return text;

EndFunction

&AtServer
Function LoadReportVariant () export

	text = NStr ( "en='Report variants'; ro='Opţiuni raport'; ru='Варианты отчета'" );
	return text;

EndFunction

&AtClient
Procedure LoadMetadata ( Module, CallbackParams = undefined, Params = undefined, ProcName = "LoadMetadata" ) export

	text = NStr ( "en='Would you like to load the metadata?
				|(this may take several minutes)'; ro='Doriți să descărcați metadatele?
				|(procesul poate dura câteva minute) '; ru='Выполнить загрузку метаданных?
				|(процесс может занять несколько минут)'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure ReplaceReportVariant ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReplaceReportVariant" ) export

	text = NStr ( "en='Are you sure that you want to overwrite the existing report settings?'; ro='Reinscrieți setările existente ale rapoartelor?'; ru='Перезаписать существующие настройки отчета?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure ReportVariantModified1 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportVariantModified1" ) export

	text = NStr ( "en='Current report version has been modified.
				|Would you like to save current changes before loading the new version?'; ro='Versiunea curentă a raportului a fost modificată.
				|Înainte de a încărca o nouă versiune a raportului, doriți să salvați modificările curente? '; ru='Текущий вариант отчета модифицирован.
				|Перед загрузкой нового варианта отчета, произвести сохранение текущих изменений?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure ReportVariantModified2 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportVariantModified2" ) export

	text = NStr ( "en='Current report version was modified.
				|Would you like to save the changes?'; ro='Versiunea curentă a raportului a fost modificată.
				|Doriți să salvați modificările? '; ru='Текущий вариант отчета модифицирован.
				|Сохранить изменения?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure DocumentIsRemoved ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This document was marked for deletion and can no longer be used'; ro='Acest document a fost marcat pentru ștergere și nu mai poate fi folosit în procese'; ru='Этот документ был помечен на удаление и уже не может быть использован в процессах'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure InvalidEmail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Incorrect e-mail address'; ro='Adresa poștală este incorectă'; ru='Почтовый адрес указан неверно'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function AgainApprovalBody ( Params ) export

	text = NStr ( "en='Hello!
				|
				|%Creator has sent back an order for additional work and approval. 
				|Memo: %Memo
				|
				|You can open the Sales Order here: %SalesOrderURL
				|
				|Total: %Amount
				|%Items
				|%Services
				|
				|This is an automatically generated email, please do not reply.
				|Route point: %RoutePoint.
				|Responsible person: %Responsible.'; ro='Bună ziua!
				|Utilizator %Creator din nou, v-a trimis un ordin de aprobare (după prelucrare).
				|Comentariu: %Memo.
				|
				|Puteți aproba comanda la: %SalesOrderURL.
				|
				|Suma totală a comenzii: %Amount.
				|%Items
				|%Services
				|
				|Acest mesaj a fost generat automat.
				|Punct de ruta: %RoutePoint.
				|Responsabil pentru comandă: %Responsible.'; ru='День добрый!
				|Пользователь %Creator снова отправил вам заказ на утверждение (после доработки).
				|Комментарий: %Memo.
				|
				|Заказ можно утвердить по адресу: %SalesOrderURL.
				|
				|Общая сумма заказа: %Amount.
				|%Items
				|%Services
				|
				|Это сообщение было сформировано автоматически.
				|Точка маршрута: %RoutePoint.
				|Ответственный за заказ: %Responsible.'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function AgainApprovalSubject ( Params ) export

	text = NStr ( "en='Approve the order #%Number again please, Department: %Department, Responsible: %Responsible'; ro='Trebuie să re-aprobați comanda #%Number, pentru %Department, %Responsible'; ru='Нужно снова утвердить заказ #%Number, для %Department, %Responsible'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ApprovalBody ( Params ) export

	text = NStr ( "en='Hello!
				|
				|%Creator sent you an order for approval.
				|%Performer
				|You can approve this order here: %SalesOrderURL.
				|
				|Total: %Amount.
				|%Items
				|%Services
				|
				|This is an automatically generated email, please do not reply.
				|Route point: %RoutePoint.
				|Responsible person: %Responsible.'; ro='Bună ziua!
				|Utilizator %Creator v-a trimis un ordin de aprobare.
				|%Performer
				|Puteți aproba comanda la: %SalesOrderURL.
				|
				|Suma totală a comenzii: %Amount.
				|%Items
				|%Services
				|
				|Acest mesaj a fost generat automat.
				|Punct de ruta: %RoutePoint.
				|Responsabil pentru comandă: %Responsible.'; ru='День добрый!
				|Пользователь %Creator отправил вам заказ на утверждение.
				|%Performer
				|Заказ можно утвердить по адресу: %SalesOrderURL.
				|
				|Общая сумма заказа: %Amount.
				|%Items
				|%Services
				|
				|Это сообщение было сформировано автоматически.
				|Точка маршрута: %RoutePoint.|
				|Ответственный за заказ: %Responsible.'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ApprovalSubject ( Params ) export

	text = NStr ( "en='Approve the order #%Number please, Department: %Department, Responsible: %Responsible'; ro='Trebuie să aprobați comanda #%Number, pentru %Department, %Responsible'; ru='Нужно утвердить заказ #%Number, для %Department, %Responsible'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function EmptyMemo () export

	text = NStr ( "en='empty'; ro='absent'; ru='отсутствует'" );
	return text;

EndFunction

&AtServer
Function ItemsRow ( Params ) export

	text = NStr ( "en='%LineNumber) %Item, qty: %Quantity, price: %Price%Discount, amount: %Amount'; ro='%LineNumber) %Item, Cantitate: %Quantity, Pret: %Price, Reducere: %Discount, Suma: %Amount'; ru='%LineNumber) %Item, кол-во: %Quantity, цена: %Price, скидка: %Discount, сумма: %Amount'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function PreviousPerformer ( Params ) export

	text = NStr ( "en='The previous step in the approval process was performed by %Performer'; ro='Înainte de dv, rezoluția a dat: %Performer'; ru='До вас, резолюцию дал: %Performer'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function RejectBody ( Params ) export

	text = NStr ( "en='Hello!
				|%Sender rejected your order.
				|Memo: %Memo.
				|You can open the order here: %SalesOrderURL.
				|
				|Total: %Amount.
				|%Items
				|%Services
				|
				|This is an automatically generated email, please do not reply.
				|Route point: %RoutePoint.'; ro='Bună ziua!
				|Utilizatorul %Sender a respins comanda dv.
				|Comentariu: %Memo.
				|Puteți deschide comanda la %SalesOrderURL.
				|
				|Suma totală a comenzii: %Amount.
				|%Items
				|%Services
				|
				|Acest mesaj a fost generat automat.
				|Punct ruta: %RoutePoint. '; ru='День добрый!
				|Пользователь %Sender отклонил ваш заказ.
				|Комментарий: %Memo.
				|Заказ можно открыть по адресу: %SalesOrderURL.
				|
				|Общая сумма заказа: %Amount.
				|%Items
				|%Services
				|
				|Это сообщение было сформировано автоматически.
				|Точка маршрута: %RoutePoint.'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function RejectSubject ( Params ) export

	text = NStr ( "en='Your order #%Number was rejected'; ro='Comanda #%Number a fost refuzată'; ru='Ваш заказ #%Number был отклонен'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ReworkBody ( Params ) export

	text = NStr ( "en='Hello!
				|%Sender submitted your order for additional work.
				|Memo: %Memo.
				|
				|You can open the order here: %SalesOrderURL.
				|
				|Total: %Amount.
				|%Items
				|%Services
				|
				|This is an automatically generated email, please do not reply.
				|Route point: %RoutePoint.'; ro='Bună ziua!
				|%Sender v-a trimis o comandă pentru revizuire.
				|Comentariu: %Memo.
				|
				|Puteți modifica comanda la adresa %SalesOrderURL.
				|
				|Suma totală a comenzii: %Amount.
				|%Items
				|%Services
				|
				|Acest mesaj a fost generat automat.
				|Punct ruta: %RoutePoint.'; ru='День добрый!
				|%Sender отправил вам заказ на доработку.
				|Комментарий: %Memo.
				|
				|Заказ можно доработать по адресу: %SalesOrderURL.
				|
				|Общая сумма заказа: %Amount.
				|%Items
				|%Services
				|
				|Это сообщение было сформировано автоматически.
				|Точка маршрута: %RoutePoint.'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ReworkSubject ( Params ) export

	text = NStr ( "en='Additional work is required for the order #%Number '; ro='Necesitatea modificării comenzii #%Number'; ru='Нужно доработать заказ #%Number'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure ApproveConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ApproveConfirmation" ) export

	text = NStr ( "en='Would you like to approve this order and send the process further?'; ro='Aprobați comanda si transmiteți?'; ru='Одобрить заказ и передать дальше?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

Function AddPictureLink ( Params ) export

	text = NStr ( "en='<span id=""%Command#%ID"" name=""%Command#%ID"" style=""color: blue;text-decoration: underline;cursor: pointer"">Add picture</span>'; ro='<span id=""%Command#%ID"" name=""%Command#%ID"" style=""color: blue;text-decoration: underline;cursor: pointer""> Adăugați o fotografie </span>'; ru='<span id=""%Command#%ID"" name=""%Command#%ID"" style=""color: blue;text-decoration: underline;cursor: pointer"">Добавить фотографию</span>'" );
	return Output.FormatStr ( text, Params );

EndFunction

Function DeletePictureLink ( Params ) export

	text = NStr ( "en='<span id=""%Command#%ID"" name=""%Command#%ID"" style=""color: red;text-decoration: underline;cursor: pointer"">Remove picture</span>'; ro='<span id=""%Command#%ID"" name=""%Command#%ID"" style=""color: red;text-decoration: underline;cursor: pointer""> Sterge fotografia </span>'; ru='<span id=""%Command#%ID"" name=""%Command#%ID"" style=""color: red;text-decoration: underline;cursor: pointer"">Удалить фотографию</span>'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Function PictureDescription () export

	text = NStr ( "en='Picture description'; ro='Descrierea fotografiei'; ru='Описание фотографии'" );
	return text;

EndFunction

&AtClient
Procedure ClearTablesYesNo ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ClearTablesYesNo" ) export

	text = NStr ( "en='Clear table parts?
				|%Tables'; ro='Sterge tabelele?
				|%Tables'; ru='Очистить табличные части?
				|%Tables'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure ClearTablesYesNoCancel ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ClearTablesYesNoCancel" ) export

	text = NStr ( "en='Clear table parts?
				|%Tables
				|
				|- Press ""Yes"" and table parts will be cleared
				|- Press ""No"" and new lines will be added to the table   
				|- Press ""Cancel"" and operation will be canceled    '; ro='Sterge tabelele?                       
				|%Tables
				|
				|- Apăsând pe ""Da"", tabelul va fi șters
				|- Apăsând pe ""Nu"", vor fi adăugate noi rânduri în tabele
				|- Apăsând pe ""Anulare"", operația va fi anulată'; ru='Очистить табличные части?
				|%Tables
				|
				|- Нажав ""Да"", таблицы будут очищены
				|- Нажав ""Нет"", в таблицы будут добавлены новые строки
				|- Нажав ""Отмена"", операция будет отменена'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure ClearTableYesNo ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ClearTableYesNo" ) export

	text = NStr ( "en='All rows will be deleted. Would you like to clear the tables?'; ro='Toate rândurile vor fi șterse. Șterge din tabel?'; ru='Все строки будут удалены. Очистить таблицу?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure ClearTableYesNoCancel ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ClearTableYesNoCancel" ) export

	text = NStr ( "en='All rows will be deleted. Would you like to clear the table?
				|
				|- Press ""Yes"" and the table will be cleared
				|- Press ""No"" and new rows will be added
				|- Press ""Cancel"" and the operation will be canceled'; ro='Toate rândurile vor fi șterse. Ștergeți tabelul?
				|
				|- făcând clic pe ""Da"", tabelul va fi șters
				|- făcând clic pe ""Nu"" "", vor fi adăugate noi rânduri în tabel
				|- făcând clic pe ""Anulare"", operația va fi anulată ""'; ru='Все строки будут удалены. Очистить таблицу?
				|
				|- Нажав ""Да"", таблица будет очищена
				|- Нажав ""Нет"", в таблицу будут добавлены новые строки
				|- Нажав ""Отмена"", операция будет отменена'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );

EndProcedure

Procedure FieldIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	if ( Params = undefined ) then
		text = NStr ( "en='Field is empty'; ro='Câmpul nu este completat'; ru='Поле не заполнено'" );
	else
		text = NStr ( "en='Field ""%Field"" is empty'; ro='Câmpul ""%Field"" nu este completat'; ru='Поле ""%Field"" не заполнено'" );
	endif;
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ColumnIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Row ""%Column"" in line %LineNumber of list ""%Table"" is empty'; ro='Nu este completată coloana ""%Column"" pe linia %LineNumber lista ""%Table""'; ru='Не заполнена колонка ""%Column"" в строке %LineNumber списка ""%Table""'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function AccountingRegisterTypeAndPresentation ( Params ) export

	text = NStr ( "en='Accounting register %RegisterPresentation'; ro='Registrul de conturi %RegisterPresentation'; ru='Регистр бухгалтерии %RegisterPresentation'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function BegOfActionPeriod () export

	text = NStr ( "en='Beginning of action period'; ro='Începutul perioadei de valabilitate'; ru='Начало периода действия'" );
	return text;

EndFunction

&AtServer
Function BegOfBasePeriod () export

	text = NStr ( "en='Beginning of base period'; ro='Începutul perioadei de bază'; ru='Начало базового периода'" );
	return text;

EndFunction

&AtServer
Function CalculationType () export

	text = NStr ( "en='Calculation type'; ro='Tipul de calcul'; ru='Вид расчета'" );
	return text;

EndFunction

&AtServer
Function CutAccumulationRegister () export

	text = NStr ( "en='Accumulation'; ro='Acumulare'; ru='Накопления'" );
	return text;

EndFunction

&AtServer
Function CutBalancesAndTurnovers () export

	text = NStr ( "en='(balances and turnovers)'; ro='(solduri și rulaje)'; ru='(остатки и обороты)'" );
	return text;

EndFunction

&AtServer
Function CutCalculationRegister () export

	text = NStr ( "en='Calculation'; ro='Calculele'; ru='Расчетов'" );
	return text;

EndFunction

&AtServer
Function CutInformationRegister () export

	text = NStr ( "en='Information'; ro='Informații'; ru='Сведений'" );
	return text;

EndFunction

&AtServer
Function CutTurnovers () export

	text = NStr ( "en='(turnovers only)'; ro='(numai rulaje)'; ru='(только обороты)'" );
	return text;

EndFunction

Function DocumentMovementsPresentation ( Params ) export

	text = NStr ( "en='Records: %Document'; ro='Mișcare: %Document'; ru='Движения: %Document'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function EndOfActionPeriod () export

	text = NStr ( "en='End of action period'; ro='Sfârșitul perioadei de valabilitate'; ru='Конец периода действия'" );
	return text;

EndFunction

&AtServer
Function EndOfBasePeriod () export

	text = NStr ( "en='End of base period'; ro='Sfârșitul perioadei de bază'; ru='Конец базового периода'" );
	return text;

EndFunction

&AtServer
Function Period () export

	text = NStr ( "en='Period'; ro='perioadă'; ru='Период'" );
	return text;

EndFunction

&AtServer
Function RecordActive () export

	text = NStr ( "en='Activity'; ro='Activitate'; ru='Активность'" );
	return text;

EndFunction

&AtServer
Function RegisterTypeAndPresentation ( Params ) export

	text = NStr ( "en='%RegisterPresentation %RegisterType Register'; ro='Registru %RegisterType %RegisterPresentation'; ru='Регистр %RegisterType %RegisterPresentation'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function RegistrationPeriod () export

	text = NStr ( "en='Registration period'; ro='Perioada de înregistrare'; ru='Период регистрации'" );
	return text;

EndFunction

&AtServer
Function ShortQuantity () export

	text = NStr ( "en='Q'; ro='C'; ru='К'" );
	return text;

EndFunction

&AtServer
Procedure WarehouseBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en = 'The quantity %Quantity of item %Item is insufficient. The amount of stock listed for warehouse %Warehouse is %QuantityBalance'; ro = 'Nu este suficient %Quantity de marfă %Item. În balanța pentru depozitul %Warehouse este %QuantityBalance'; ru = 'Не хватает %Quantity товара %Item. В остатках на складе %Warehouse числится %QuantityBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

Function Processing () export

	text = NStr ( "en='Processing...'; ro='Prelucrarea ...'; ru='Обработка...'" );
	return text;

EndFunction

&AtClient
Function ErrorTitle () export

	text = NStr ( "en='Error'; ro='Eroare'; ru='Ошибка'" );
	return text;

EndFunction

&AtClient
Procedure ShowWeekendTip ( Params = undefined, NavigationLink = undefined ) export

	text = NStr ( "en='Tip'; ro='Sfat'; ru='Совет'" );
	explanation = NStr ( "en='Use calendar settings to show weekends'; ro='Pentru a afișa zilele libere, utilizați setarea pentru calendar'; ru='Для отображения выходных дней воспользуйтесь настройкой календаря'" );
	putUserNotification ( text, Params, NavigationLink, explanation, PictureLib.Info32 );

EndProcedure

&AtClient
Procedure InvalidPasswordAndConfirmation ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Password and password confirmation are not identical'; ro='Parola și confirmarea ei trebuie să fie identică'; ru='Пароль и подтверждение пароля должны быть одинаковыми'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReportSchedulingIncorrectPeriod ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Selection by period is set to a specific date. You cannot use the schedule because you enabled ""strict selection"" mode. As a result, the report will always be delivered with the same data. Try to set a predefined value as a selection, not a specific date.'; ro='Selectarea după perioadă este stabilită la o anumită dată. Nu puteți utiliza orarul, deoarece ați stabilit un filtru strict și veți primi de fiecare dată acest raport cu aceleași date. Încercați să specificați în filtru, nu o anumită dată, ci o valoare predefinită'; ru='Отбор по периоду установлен на конкретную дату. Использовать расписание нельзя, так как вы установили строгий отбор и будете каждый раз получать этот отчет с одними и теме же данными. Попробуйте указать в качестве отбора, не конкретную дату(ы), а предопределенное значение'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ScheduleDateError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Please set the start date to after thecurrent date'; ro='Începeți orarul de la o dată mai mare decât data curentă'; ru='Начните расписание с даты большей, чем текущая дата'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure SelectAccessRights ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Check the boxes to set access rights'; ro='Selectați drepturile de acces necesare'; ru='Отметьте флажками необходимые права доступа'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ConfirmAccessRights ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Confirm or revert changes to access rights'; ro='Confirmați sau respinge modificările aduse drepturilor de acces'; ru='Подтвердите или отмените изменения в правах доступа'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure SendingReportsByScheduleAddingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Scheduled reports must be created and sent from a specific form. Interactive access is denied'; ro='Crearea orarului de expediere se realizează din forme de rapoarte concrete. Adăugarea interactivă nu este disponibilă'; ru='Создание графиков отправки осуществляется из форм конкретных отчетов. Интерактивное добавление недоступно'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure WeekDaySelectionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Please select at least one week day'; ro='Selectați cel puțin o zi a săptămânii'; ru='Выберите хотя бы один день недели'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Function FitCalendar () export

	text = NStr ( "en='Change calendar height and width to match the current window size'; ro='Reglați înălțimea și lățimea calendarului la dimensiunea curentă a ferestrei'; ru='Подогнать высоту и ширину календаря под текущие размеры окна'" );
	return text;

EndFunction

Function Kilobyte () export

	text = NStr ( "en='Kb'; ro='KB'; ru='Кб'" );
	return text;

EndFunction

Function Megabyte () export

	text = NStr ( "en='Mb'; ro='MB'; ru='Мб'" );
	return text;

EndFunction

&AtServer
Function PageFooter () export

	text = NStr ( "en='[&PageNumber] from [&PagesTotal]'; ro='[&PageNumber] din [& PagesTotal]'; ru='[&PageNumber] из [&PagesTotal]'" );
	return text;

EndFunction

&AtServer
Function ReportByEmailBody ( Params ) export

	text = NStr ( "en='Hello,
				|
				|You have received %ReportPresentation , a scheduled report. It is attached to this e-mail.
				|
				|To change the schedule you can go to:
				|%ScheduleSettingsURL
				|
				|Sincerely,
				|%Website'; ro='Bună ziua!
				|Ați primit un raport %ReportPresentation conform programului. Raportul este atașat la scrisoare.
				|
				|Pentru a modifica programul, puteți da clic pe link:
				|% ScheduleSettingsURL
				|
				|Cu stimă, echipa de specialiști %Website'; ru='Доброго времени суток!
				|Вы получили по расписанию отчет %ReportPresentation. Отчет во вложении к письму.
				|
				|Для изменения расписания, вы можете перейти по ссылке:
				|%ScheduleSettingsURL
				|
				|С уважением, команда специалистов %Website'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ShortDay () export

	text = NStr ( "en='d'; ro='z'; ru='д'" );
	return text;

EndFunction

&AtServer
Function ShortHour () export

	text = NStr ( "en='h'; ro='o'; ru='ч'" );
	return text;

EndFunction

&AtServer
Function TaskBody ( Params ) export

	text = NStr ( "en='%Task
				|
				|1) %Start %StartTime - %Finish = %Duration
				|%Memo
				|
				|Task can be opened here:
				|%URL'; ro='%Task
				|
				|1) %Start %StartTime - %Finish = %Duration
				|%Memo
				|
				|Sarcina poate fi deschisă prin linkul:
				|%URL'; ru='%Task
				|
				|1) %Start %StartTime - %Finish = %Duration
				|%Memo
				|
				|Задачу можно открыть по ссылке:
				|%URL'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function TaskSubject ( Params ) export

	text = NStr ( "en='Reminder: %Description, start: %Start %StartTime - %Finish, duration: %Duration'; ro='Memento: %Description, start: %Start %StartTime - %Finish, durată: %Duration'; ru='Напоминание: %Description, start: %Start %StartTime - %Finish, продолжительность: %Duration'" );
	return Output.FormatStr ( text, Params );

EndFunction

Function TimeDay () export

	text = NStr ( "en='d.'; ro='z.'; ru='д.'" );
	return text;

EndFunction

Function TimeHour () export

	text = NStr ( "en='h.'; ro='o.'; ru='ч.'" );
	return text;

EndFunction

Function TimeMinute () export

	text = NStr ( "en='m.'; ro='m.'; ru='м.'" );
	return text;

EndFunction

&AtServer
Function UserTask () export

	text = NStr ( "en='User Task'; ro='Sarcina utilizatorului'; ru='Задача пользователя'" );
	return text;

EndFunction

&AtClient
Function Week ( Params ) export

	text = NStr ( "en='Week %Week'; ro='Saptamana %Week'; ru='Неделя %Week'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure CompleteTask ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CompleteTask" ) export

	text = NStr ( "en='Would you like to complete this task?'; ro='Finalizați sarcina?'; ru='Завершить задачу?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure TerminateProcess ( Module, CallbackParams = undefined, Params = undefined, ProcName = "TerminateProcess" ) export

	text = NStr ( "en='Are you sure you want to terminate the entire process?'; ro='Anulați procesul?'; ru='Отменить процесс?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure RemoveAttachmentConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RemoveAttachmentConfirmation" ) export

	text = NStr ( "en='Are you sure you want to delete the selected attachments?'; ro='Ștergeți atașamentele selectate?'; ru='Удалить выделенные вложения?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure RemoveTaskConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RemoveTaskConfirmation" ) export

	text = NStr ( "en='Are you sure you want to remove this task (note)?'; ro='Ștergeți sarcina (notă)?'; ru='Удалить задачу (заметку)?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure ReportScheduleRemovingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportScheduleRemovingConfirmation" ) export

	text = NStr ( "en='Are you sure you want to delete the schedule?'; ro='Ștergeți orarul?'; ru='Удалить расписание?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure AccessRemovingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "AccessRemovingConfirmation" ) export

	text = NStr ( "en='Are you sure you want to remove this permission (or selected range of records)?'; ro='Ștergeți dreptul de acces?
				|(sau o gamă de înregistrări selectate) '; ru='Удалить право доступа?
				|(или выделенный диапазон записей)'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

Function PreviewNotSupported () export

	text = NStr ( "en='Preview mode is not supported for this file'; ro='Pentru acest fișier, modul de previzualizare nu se susține'; ru='Для данного файла режим предпросмотра не поддерживается'" );
	return text;

EndFunction

&AtClient
Procedure PublicationAccessSetup ( Module, CallbackParams = undefined, Params = undefined, ProcName = "PublicationAccessSetup" ) export

	text = NStr ( "en='You have not designated access rights to this document. 
				|After publication, no users will be able to view it.
				|Do you still want to proceed with the publication?'; ro='Nu ați configurat accesul la acest document.
				|După publicare, acesta va fi disponibil numai pentru dvs.
				|Continuați să postați? '; ru='Вы не настроили доступ к данному документу.
				|После публикации он будет доступен только вам.
				|Продолжить публикацию?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtServer
Function SubscriptionNotificationBody ( Params ) export

	text = NStr ( "en='Hello!
				|User %User has sent a notification about ""%Subject"".
				|%Comment
				|Direct link to the document: %URL
				|
				|This email was created automatically. Do not reply to this email.'; ro='Bună ziua!
				|Utilizatorul %User v-a trimis o notificare despre documentul ""%Subject"" "".
				|%Comment
				|Link direct la document: %URL
				|
				|Scrisoarea s-a format automat. Nu răspundeți la acest e-mail. ""'; ru='Доброго времени суток!
				|Пользователь %User отправил Вам уведомление о документе ""%Subject"".
				|%Comment
				|Прямая ссылка на документ: %URL
				|
				|Письмо было сформировано автоматически. Не отвечайте на это письмо.'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function CreatorComment ( Params ) export

	text = NStr ( "en='Creator’s note: %Comment'; ro='Nota autorului: %Comment'; ru='Примечание автора: %Comment'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure PublishDocument ( Module, CallbackParams = undefined, Params = undefined, ProcName = "PublishDocument" ) export

	text = NStr ( "en='Would you like to publish this document?'; ro='Publicați documentul?'; ru='Опубликовать документ?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure ChangeDocument ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ChangeDocument" ) export

	text = NStr ( "en='Would you like to change this document?
				|Warning: during the editing process, the document will be unpublished'; ro='Modificați documentul?
				|Atenție: pentru perioada de editare, bifa de publicare va fi eliminată '; ru='Вы хотите изменить документ?
				|Внимание: на период редактирования, флаг публикации будет снят'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure BooksAccessError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='You do not have appropriate rights to change the book'; ro='Permisiuni insuficiente pentru editarea cărții'; ru='Недостаточно прав для изменения книги'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure BookAccessNotDefined ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='You have to set up parent group or define special access rights for this book'; ro='Se specifică partiția elementului părinte sau cere un element drepturi specifice'; ru='Укажите для элемента родительский раздел или задайте для элемента специальные права'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure BookAccessNotSelected ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The access rights to this Book should be defined'; ro='Accesul la carte nu a fost setat'; ru='Доступ к книге не задан'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure BookIsNotDefined ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "BookIsNotDefined" ) export

	text = NStr ( "en='A book is not defined for this document'; ro='Pentru acest document, cartea nu este specificată'; ru='Для этого документа книга не задана'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure SelectBookFirst ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ChangeDocumentPosition" ) export

	text = NStr ( "en='In order to change the document''s position, you must first select a book'; ro='Alegeți o carte în care doriți să schimbați ordinea documentelor'; ru='Выберите книгу в пределах которой вы хотите менять порядок следования документов'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure DocumentsLoadingCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DocumentsLoadingCompleted" ) export

	text = NStr ( "en='Upload is complete!
				|%Count files were loaded'; ro='Încărcare completa! Încărcat %Count fișiere'; ru='Загрузка завершена!
				|Загружено %Count файлов'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure BookDownloaded ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export

	text = NStr ( "en='Downloading...'; ro='Descărcarea ...'; ru='Скачивание...'" );
	explanation = NStr ( "en='%Name'; ro='%Name'; ru='%Name'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );

EndProcedure

&AtClient
Procedure DocumentsDownloadingCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DocumentsDownloadingCompleted" ) export

	text = NStr ( "en='Download is completed!
				|%Count files were downloaded'; ro='Descărcarea este completă!
				|Fisierele descarcate: %Count '; ru='Выгрузка завершена!
				|Выгружено файлов: %Count'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Procedure DocumentAlreadyAttached ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The %File already exists in the list, and has therefore been skipped'; ro='%File există deja în listă, descărcarea este omisă'; ru='%File уже существует в списке, загрузка пропущена'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure DocumentFilesDuplicate ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DocumentFilesDuplicate" ) export

	text = NStr ( "en='The selected documents contain duplicate file names!
				|Please select documents with unique file names'; ro='Documentele selectate conțin denumiri identice de fișiere!
				|Selectați documente cu denumiri de fișiere care nu sunt identice
				|și repetați operația '; ru='Выбранные документы содержат одинаковые названия файлов!
				|Выберите документы с неповторяющимися названиями файлов
				|и повторите операцию'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

Procedure DocumentIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The document does not have attachments'; ro='Documentul nu conține fișiere atașate'; ru='Документ не содержит вложенных файлов'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ManualSortingOff ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The Manual sorting flag is not enabled for the %Book. 
				|This option can be enabled in the book dialog form, please see the ""More"" tab'; ro='Pentru carte %Book nu este inclusă abilitatea de sortare manuală. Posibilitatea de sortare manuală este setată pe fila Altele sub forma editării unei cărți'; ru='Для книги %Book не включена возможность ручной сортировки. Возможность ручной сортировки задается на вкладке Дополнительно в форме редактирования книги'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure PrintedFilesNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "PrintedFilesNotFound" ) export

	text = NStr ( "en='Printed files were not found!'; ro='Nu au fost găsite fișiere de imprimat'; ru='Не обнаружено файлов для печати'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure WebclientIsNotSupported ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "WebclientIsNotSupported" ) export

	text = NStr ( "en='Web-client does not support this operation'; ro='Într-un client Web, această operație nu este acceptată'; ru='В веб-клиенте данная операция не поддерживается'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure DocumentsCreatorChanged ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DocumentsCreatorChanged" ) export

	text = NStr ( "en='Creator replacement is completed!'; ro='Înlocuirea autorului este finalizată!'; ru='Замена автора завершена!'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure AccessDenied ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "AccessDenied" ) export

	text = NStr ( "en='Access denied'; ro='Accesul la sistem este interzis'; ru='Доступ в систему запрещен'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure RegistrationDataSendedSuccessfully ( Params = undefined, NavigationLink = undefined ) export

	text = NStr ( "en='Send notification'; ro='Trimiterea mesajului'; ru='Сообщение об отправке'" );
	explanation = NStr ( "en='The registration data was successfully sent'; ro='Datele de înregistrare au fost trimise cu succes'; ru='Регистрационные данные были успешно отправлены'" );
	putUserNotification ( text, Params, NavigationLink, explanation, PictureLib.Info32 );

EndProcedure

&AtServer
Procedure AdministratorNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='No users with administrative rights remain in the system. One database user must have administrative rights'; ro='Nu au existat utilizatori cu drepturi administrative. Pentru funcționalitatea serviciului, în baza dvs. de informații trebuie să existe cel puțin un utilizator cu drepturi administrative'; ru='Не осталось пользователей с административными правами. Для работоспособности сервиса, в вашей информационной базе должен быть как минимум один пользователь с административными правами'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure SelectUsersGroup ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Assign user to the group or assign individual rights'; ro='Selectați dacă utilizatorul aparține unui grup sau setați drepturi individuale'; ru='Выберите принадлежность пользователя к группе или задайте индивидуальные права'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function Resolution () export

	text = NStr ( "en='Resolution'; ro='Rezoluție'; ru='Резолюция'" );
	return text;

EndFunction

&AtClient
Procedure SendRegistrationDataInformation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SendRegistrationDataInformation" ) export

	text = NStr ( "en='Attention! Due to security reasons, this e-mail won''t contain a password.
				|If you have already assigned a password to this user, please ensure that the user is aware of it. 
				|In addition, you can enable the flag “User must change the password on next logon”'; ro='Avertisment: Din motive de securitate, e-mailul trimis nu va conține o parolă.
				|Dacă ați stabilit deja o parolă pentru acest utilizator, asigurați-vă că utilizatorul știe sau va ști parola.
				|Dacă nu ați setat încă parola, vă recomandăm să activați steagul
				|""Utilizatorul trebuie să schimbe parola la următoarea conectare"".      
				|În acest caz, utilizatorul va putea să-și stabilească o parolă pentru prima dată când se conectează.
				|
				|Continuați?'; ru='Внимание! В целях безопасности, высылаемое письмо не будет содержать пароль.
				|Если вы уже установили для этого пользователя пароль, убедитесь, что он его знает или будет знать.
				|Если вы пароль еще не устанавливали, рекомендуем вам включить флаг
				|«Пользователь должен сменить пароль при следующем входе в систему».
				|В этом случае, пользователь самостоятельно сможет установить себе пароль при первом входе в систему.
				|
				|Продолжить?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.OKCancel, 0, DialogReturnCode.OK, title );

EndProcedure

&AtServer
Procedure DocumentCannotBeChanged ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This document cannot be modified because the approval process has begun '; ro='Documentul nu poate fi modificat, pentru ca a fost lansat procesul de aprobare'; ru='Документ нельзя изменить, по нему был запущен процесс одобрения'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function DateNumber ( Params ) export

	text = NStr ( "en='#%Number %Date'; ro='№%Number din %Date'; ru='№%Number от %Date'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure RightsConfirmation ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "RightsConfirmation" ) export

	text = NStr ( "en='The selected permission has dependencies on other system permissions.
				|They should be added or removed as well.
				|Please review changes, then Accept or Cancel them'; ro='Există dependențe între privilegiul și alte privilegii ale sistemului.
				|Acestea trebuie șterse sau adăugate împreună.
				|Revizuiți modificările, apoi confirmă sau le anulați '; ru='Существуют зависимости между выделенной привилегией и другими привилегиями системы.
				|Они должны быть удалены либо добавлены вместе.
				|Пересмотрите изменения, затем либо подтвердите, либо отмените их'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function General ( Params = undefined ) export

	text = NStr ( "en='General'; ro='De bază'; ru='Основной'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function InvoicingBody ( Params ) export

	text = NStr ( "en='Hello!
				|%Sender sent your order for invoicing.
				|Memo: %Memo.
				|
				|You can open the order here: %SalesOrderURL.
				|
				|Total: %Amount.
				|%Items
				|%Services
				|
				|This is an automatically generated email, please do not reply.
				|Route point: %RoutePoint.'; ro='Bună ziua!
				|%Sender v-a trimis o comanda de a finaliza punerea în aplicare.
				|Comentariu: %Memo.
				|
				|Puteți deschide comanda la %SalesOrderURL.
				|
				|Suma totală a comenzii: %Amount.
				|%Items
				|%Services
				|
				|Acest mesaj a fost generat automat.
				|Punct ruta: %RoutePoint. '; ru='День добрый!
				|%Sender отправил вам заказ для завершения реализации.
				|Комментарий: %Memo.
				|
				|Заказ можно открыть по адресу: %SalesOrderURL.
				|
				|Общая сумма заказа: %Amount.
				|%Items
				|%Services
				|
				|Это сообщение было сформировано автоматически.
				|Точка маршрута: %RoutePoint.
				|'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function InvoicingSubject ( Params ) export

	text = NStr ( "en='Please invoice the order #%Number'; ro='Necesitatea de a pune în aplicare comanda #%Number'; ru='Нужно реализовать заказ #%Number'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure SelectPicture ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "SelectPicture" ) export

	text = NStr ( "en='Please select a picture '; ro='Alegeți o fotografie, vă rog'; ru='Выберите картинку пожалуйста'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

Function PictureNotFound () export

	text = NStr ( "en='Picture not found.'; ro='Fotografia nu este specificată.'; ru='Фотография не задана.'" );
	return text;

EndFunction

Function PicturesCount ( Params ) export

	text = NStr ( "en='Pictures count: %Count'; ro='Imagini totale: %Count'; ru='Всего картинок: %Count'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure DeletePictureConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DeletePictureConfirmation" ) export

	text = NStr ( "en='Would you like to delete this picture?'; ro='Ștergeți fotografia?'; ru='Удалить фотографию?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure OpenDownloadsFolder ( Module, CallbackParams = undefined, Params = undefined, ProcName = "OpenDownloadsFolder" ) export

	text = NStr ( "en='Would you like to open the downloads folder?'; ro='Deschideți folderul cu fișierul descărcat?'; ru='Открыть папку с загруженными файлами?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function Download () export

	text = NStr ( "en='Download'; ro='Descarcă'; ru='Скачать'" );
	return text;

EndFunction

&AtClient
Procedure RollbackChanges ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RollbackChanges" ) export

	text = NStr ( "en='Would you like to cancel all changes and restore the previous version of the Document?'; ro='Anulați toate modificările și reveniți la versiunea anterioară a documentului?'; ru='Отменить все изменения и вернуться к предыдущей версии документа?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function VersionCreated () export

	text = NStr ( "en='Document version was created'; ro='Versiunea creată a documentului'; ru='Создана версия документа'" );
	return text;

EndFunction

&AtServer
Function DocumentPublished () export

	text = NStr ( "en='Document was published'; ro='Document publicat'; ru='Документ опубликован'" );
	return text;

EndFunction

&AtClient
Procedure CannotUpdateDocument ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "CannotInjectFile" ) export

	text = NStr ( "en='You do not have sufficient permissions to change this document'; ro='Nu aveți drepturi suficiente pentru a modifica documentul'; ru='У вас недостаточно прав для изменения документа'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure FileNotSelected ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "FileNotSelected" ) export

	text = NStr ( "en='File not selected'; ro='Nu a fost selectat niciun fișier'; ru='Не выбран файл'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function SelectFiles () export

	text = NStr ( "en='Select files'; ro='Selectați fișierele'; ru='Выберите файлы'" );
	return text;

EndFunction

&AtServer
Function UploadFiles () export

	text = NStr ( "en='Would you like to upload changed files?'; ro='Încarcă fișierele modificate?'; ru='Загрузить измененные файлы?'" );
	return text;

EndFunction

&AtClient
Procedure DocumentLocked ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DocumentLocked" ) export

	text = NStr ( "en='Document is locked by user %User'; ro='Document blocat de utilizator %User'; ru='Документ заблокирован пользователем %User'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure ChangedFilesNotFound ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ChangedFilesNotFound" ) export

	text = NStr ( "en='Changed files are not found.
				|Would you like to continue publishing?'; ro='Nu au fost găsite fișiere modificate.
				|Continuați să postați? '; ru='Измененных файлов не обнаружено.
				|Продолжить публикацию?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure LocalFileUsed ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export

	text = NStr ( "en='Downloading'; ro='Încarcare'; ru='Закачка'" );
	explanation = NStr ( "en='%File has been found on your local computer and was not downloaded from the database again '; ro='%File a fost găsit pe discul local și nu a fost re-descărcat din baza de date'; ru='%File был найдет на локальном диске и не был заново скачен из базы данных'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );

EndProcedure

&AtClient
Procedure ReplaceFile ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReplaceFile" ) export

	text = NStr ( "en='%File already exists in your local computer.
				|Would you like to replace it?'; ro='%File există deja pe computerul local.
				|Vreți să-l înlocuiți?'; ru='%File уже существует на вашем локальном компьюторе.
				|Вы хотите заменить его?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Function RenameFile () export

	text = NStr ( "en='Please enter a new file name'; ro='Introduceți un nou nume de fișier'; ru='Пожалуйста введите новое имя файла'" );
	return text;

EndFunction

&AtClient
Procedure FileNameExists ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "FileNameExists" ) export

	text = NStr ( "en='The file already exists'; ro='Un fișier cu acest nume există deja'; ru='Файл с таким именем уже существует'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

Function TableCaption () export

	text = NStr ( "en='Table'; ro='Tabel'; ru='Таблица'" );
	return text;

EndFunction

&AtServer
Procedure LinkAccessError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='%Object cannot be modified – you do not have sufficient access'; ro='Drepturi de acces insuficiente pentru a modifica %Object'; ru='Недостаточно прав доступа для изменения %Object'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DictionaryTemplateNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Template %Template was not found. Please check your dictionary'; ro='Modelul %Template nu a fost găsit. Verificați dicționarul'; ru='Шаблон %Template не найден. Проверьте словарь'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure NodesRecoursion ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "NodesRecoursion" ) export

	text = NStr ( "en='Node cannot be placed inside itself'; ro='Un nod nu poate fi plasat în interiorul său'; ru='Узел не может быть помещен внутрь себя самого'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure ConfirmExit ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ConfirmExit" ) export

	text = NStr ( "en='Data has been changed. Do you want to save the changes?'; ro='Datele au fost modificate, salvați modificările?'; ru='Данные были изменены, сохранить изменения?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function PropertiesRoot () export

	text = NStr ( "en='Items'; ro='Elemente'; ru='Элементы'" );
	return text;

EndFunction

&AtServer
Function WorkingDescription () export

	text = NStr ( "en='<Under Construction>'; ro='<În construcție>'; ru='<В разработке>'" );
	return text;

EndFunction

&AtClient
Procedure SaveNewObject ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SaveNewObject" ) export

	text = NStr ( "en='Save this object before continuing.
				|Would you like to save changes?'; ro='Pentru a continua, obiectul trebuie scris.
				|Doriți să înregistrați obiect? '; ru='Для продолжения, объект необходимо записать.
				|Записать объект?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure ParentPropertiesNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ParentPropertiesNotFound" ) export

	text = NStr ( "en='Parent object for properties inheritance is not found'; ro='Obiectul părinte nu a fost găsit pentru moștenire de proprietate'; ru='Родительский объект для наследования свойств не найден'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function PropertiesDefaultName () export

	text = NStr ( "en='Property'; ro='Proprietate'; ru='Свойство'" );
	return text;

EndFunction

&AtClient
Function HostAlreadyUsed () export

	text = NStr ( "en='(owner is already defined)'; ro='(proprietarul deja setat)'; ru='(владелец уже задан)'" );
	return text;

EndFunction

&AtClient
Procedure SaveNewProperties ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SaveNewProperties" ) export

	text = NStr ( "en='Properties must be saved before owner selection.
				|Would you like to save properties?'; ro='Proprietățile trebuie salvate înainte de selectarea proprietarului.
				|Doriți să salvați proprietățile?'; ru='Перед выбором владельца, свойства должны быть записаны.
				|Записать свойства?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Function OpenGoogleMaps () export

	text = NStr ( "en='Open in Google Maps'; ro='Deschideți în Hărți Google'; ru='Открыть карты Google'" );
	return text;

EndFunction

&AtServer
Function AndClause () export

	text = NStr ( "en='and'; ro='și'; ru='и'" );
	return text;

EndFunction

&AtServer
Function OrClause () export

	text = NStr ( "en='or'; ro='sau'; ru='или'" );
	return text;

EndFunction

&AtServer
Function NotClause () export

	text = NStr ( "en='not'; ro='nu'; ru='не'" );
	return text;

EndFunction

&AtServer
Function IfClause () export

	text = NStr ( "en='if'; ro='dacă'; ru='если'" );
	return text;

EndFunction

&AtClient
Procedure PropertyDeletionError ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "PropertyDeletionError" ) export

	text = NStr ( "en='Field cannot be removed because it is used in Conditions Table'; ro='Câmpul este utilizat în tabelul Condiții. Câmpul nu poate fi șters'; ru='Поле используется в таблице Условия. Поле не может быть удалено'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Function Building () export

	text = NStr ( "en='cl.'; ro='cl.'; ru='cl.'" );
	return text;

EndFunction

&AtClient
Function Entrance () export

	text = NStr ( "en='sc.'; ro='sc.'; ru='sc.'" );
	return text;

EndFunction

&AtClient
Function Floor () export

	text = NStr ( "en='et.'; ro='et.'; ru='et.'" );
	return text;

EndFunction

&AtClient
Function Apartment () export

	text = NStr ( "en='ap.'; ro='ap.'; ru='ap.'" );
	return text;

EndFunction

&AtClient
Function Municipality () export

	text = NStr ( "en='mun.'; ro='mun.'; ru='mun.'" );
	return text;

EndFunction

&AtClient
Procedure ValueAlreadyExists ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ValueAlreadyExists" ) export

	text = NStr ( "en='%Value already exists!
				|Would you like to continue?'; ro='%Value există deja.
				|Doriți să continuați operația?'; ru='%Value уже существует.
				|Продолжить операцию?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure UserAlreadyExists ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UserAlreadyExists" ) export

	text = NStr ( "en='User name already exists for the specified employee.
				|Would you like to create another user?'; ro='Utilizatorul pentru angajatul specificat a fost deja creat.
				|Creați un alt utilizator?'; ru='Пользователь для указанного сотрудника уже был создан.
				|Создать еще одного пользователя?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure FillingDataNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "FillingDataNotFound" ) export

	text = NStr ( "en='Filling data was not found'; ro='Nu au fost găsite date pentru completare'; ru='Данные для заполнения не найдены'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function FillingDataNotFoundError () export

	text = NStr ( "en='Filling data was not found'; ro='Nu au fost găsite date pentru completare'; ru='Данные для заполнения не найдены'" );
	return text;

EndFunction

&AtClient
Procedure DocumentLoaded ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export

	text = NStr ( "en='Loading...'; ro='Se încărca ...'; ru='Загрузка...'" );
	explanation = NStr ( "en='%Name'; ro='%Name'; ru='%Name'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );

EndProcedure

&AtClient
Procedure AnotherSessionDetected ( Module, CallbackParams = undefined, Params = undefined, ProcName = "AnotherSessionDetected" ) export

	text = NStr ( "en='You are already connected to the system:
				|%Sessions
				|
				|One user cannot log into multiple simultaneous sessions.
				|Would you like to terminate the existing connections and start a new session?'; ro='Sunteți deja conectat la sistem:
				|%Sessions
				|
				|Nu puteți lucra sub același utilizator în diferite sesiuni.
				|Doriți să terminați conexiunile specificate și să începeți o nouă sesiune?'; ru='Вы уже подключены к системе:
				|%Sessions
				|
				|Нельзя работать под одним пользователем в разных сессиях.
				|Завершить работу указанных соединений и начать новую сессию?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtServer
Function SessionPresentation ( Params ) export

	text = NStr ( "en='Computer: %ComputerName, session started: %SessionStarted'; ro='Computer: %ComputerName, începutul sesiunii: %SessionStarted'; ru='Компьютер: %ComputerName, начало сессии: %SessionStarted'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure RemoveObjectsConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RemoveObjectsConfirmation" ) export

	text = NStr ( "en='Are you sure you want to delete the selected objects?
				|Warning! This operation cannot be undone'; ro='Sigur doriți să ștergeți obiectele selectate?
				|Atenție: operația de ștergere este ireversibilă'; ru='Удалить отмеченные объекты?
				|Внимание: операция удаления необратима'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure RemovingObjectsCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "RemovingObjectsCompleted" ) export

	text = NStr ( "en='Objects removed successfully'; ro='Obiectele șterse cu succes!'; ru='Объекты успешно удалены!'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure RemovingObjectsNotCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "RemovingObjectsNotCompleted" ) export

	text = NStr ( "en='The object has dependencies and therefore cannot be removed.
				|To analyze the dependencies, use the ""Dependencies"" table.
				|Dependencies lists are available for every object in the system.
				|For more information regarding the removal of objects with dependencies, please consult the Help page. '; ro='Nu s-au șters unele obiecte, deoarece au legături către alte obiecte.
				|Pentru a analiza aceste linkuri, utilizați tabelul Dependențe.
				|Pentru fiecare obiect, puteți obține o listă de dependențe.
				|Pentru informații detaliate despre ștergerea obiectelor pentru care sunt disponibile referințe, consultați secțiunea'; ru='Не удалось удалить некоторые объекты, так как на них имеются ссылки других объектов.
				|Чтобы проанализировать эти ссылки, воспользуйтесь таблицей Зависимости.
				|Для каждого объекта, можно получить список зависимостей.
				|Подробную информацию о удалении объектов на которые имеются ссылки, читайте в справке'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Procedure RemovingObjectsNotSelected ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='No objects selected for removal'; ro='Nu s-au selectat elemente pentru ștergere'; ru='Не выбрано ни одного объекта для удаления'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure DeletionMarkConfirmation1 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DeletionMarkConfirmation1" ) export

	text = NStr ( "en='Would you like to mark the linked objects for removal?'; ro='Marcați pentru a șterge obiecte legate?'; ru='Пометить на удаление связанные объекты?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure DeletionMarkConfirmation2 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DeletionMarkConfirmation2" ) export

	text = NStr ( "en='Are you sure you want to mark the linked objects for removal?
				|Warning: This process is irreversible!
				|All linked records will be marked, not just the %Count visible elements'; ro='Marcați pentru eliminarea obiectelor asociate?
				|Atenție!  Acest proces este ireversibil!
				|Toate obiectele asociate vor fi marcate, nu numai cele care se văd %Count elemente'; ru='Пометить на удаление связанные объекты?
				|Внимание! Этот процесс необратим!
				|Помечены будут все связанные объекты, а не только видимые %Count элементов'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure CompleteRoutePoint ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CompleteRoutePoint" ) export

	text = NStr ( "en='Would you like to complete this task?'; ro='Finalizați sarcina?'; ru='Завершить задачу?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure TasksNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='No tasks for the employee in this project'; ro='Nu există sarcini pentru acest angajat în proiect'; ru='В проекте нет задач для этого сотрудника'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ProcessPerformers ( Params ) export

	text = NStr ( "en='Current process performers:
				|%Performers'; ro='Executorii procesului curent:
				|%Performers'; ru='Текущие исполнители процесса:
				|%Performers'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure PerformersNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "PerformersNotFound" ) export

	text = NStr ( "en='Performers are not found.
				|Check the Roles document and define process performers.'; ro='Implementatorii nu au fost găsiți.
				|Verificați setările registrului de adrese al procesului de afaceri.'; ru='Исполнители не найдены.
				|Проверьте настройки регистра адресации бизнес-процессов.'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure RejectConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RejectConfirmation" ) export

	text = NStr ( "en='Would you like to reject this order?
				|
				|In contrast to the Rework action, the Rejection is an irreversible operation.
				|Rejection will cancel the process completely.'; ro='Respingeți comanda?
				|
				|Spre deosebire de acțiunea Reface, respingerea este o operație ireversibilă.
				|După respingere, procesul de afaceri se va încheia și comanda va fi închisă.'; ru='Отклонить заказ?
				|
				|В отличие от действия Доработать, отклонение заказа безвозвратная операция.
				|После отклонения, бизнес-процесс завершится, и заказ будет закрыт.'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtServer
Procedure Error ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Error: %Error'; ro='Eroare: %Error'; ru='Ошибка: %Error'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

Function SpreadsheedTotalCount ( Params ) export

	text = NStr ( "en='Count: %Count'; ro='Cantitate: %Count'; ru='Кол-во: %Count'" );
	return FormatStr ( text, Params );

EndFunction

Function SpreadsheedTotal ( Params ) export

	text = NStr ( "en='Avg: %Average   Count: %Count   Sum: %Sum'; ro='Media: %Average   Cantitate: %Count   Suma: %Sum'; ru='Среднее: %Average   Кол-во: %Count   Сумма: %Sum'" );
	return FormatStr ( text, Params );

EndFunction

&AtClient
Function CalculationAreaTooBig () export

	text = NStr ( "en='The selected area is too large. Click on the button on the right for manual calculation'; ro='Este alocată o suprafață mare. Faceți clic pe butonul din dreapta pentru a calcula'; ru='Выделена большая область. Нажмите кнопку справа для расчета'" );
	return text;

EndFunction

Function SpreadsheedAreaNotSelected () export

	text = NStr ( "en='Area not defined'; ro='Domeniul nu este specificat '; ru='Область не задана'" );
	return text;

EndFunction

&AtServer
Function NewPhoneTemplate () export

	text = NStr ( "en='New Template'; ro='Creați șablon'; ru='Создать шаблон'" );
	return text;

EndFunction

&AtServer
Function ListPhoneTemplates () export

	text = NStr ( "en='Open List'; ro='Deschideți lista'; ru='Открыть список'" );
	return text;

EndFunction

&AtServer
Procedure WrongPhone ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The phone number is incorrect'; ro='Numărul de telefon greșit'; ru='Неверный номер телефона'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function MinumumPropertyValue ( Params = undefined ) export

	text = NStr ( "en='Min value: %Value'; ro='Valoare minimă: %Value'; ru='Мин.значение: %Value'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function MaximumPropertyValue ( Params = undefined ) export

	text = NStr ( "en='Max value: %Value'; ro='Valoare maximă: %Value'; ru='Макс.значение: %Value'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function PerformerUndefined ( Params = undefined ) export

	text = NStr ( "en='%Role does not have assigned performers. To assign performers, use Menu / Settings / Users / Roles'; ro='Nu este specificat niciun executant pentru rolul%. Pentru a seta executanți, consultați Meniu / Setări / Utilizatori / Roluri'; ru='Для роли %Role не задан ни один исполнитель. Для задания исполнителей см. Меню / Настройки / Пользователи / Роли'" );
	return Output.FormatStr ( text, Params );

EndFunction

Function TimeFormat () export

	text = NStr ( "en='hh:mm t'; ro='HH:mm'; ru='HH:mm'" );
	return "DF='" + text + "'";;

EndFunction

&AtClient
Function HourFormat () export

	text = NStr ( "en='hh t'; ro='HH'; ru='HH'" );
	return "DF='" + text + "'";

EndFunction

&AtClient
Function DatetimeFormat () export

	text = NStr ( "en='MMM dd/yyyy hh:mm t'; ro='MMM dd/yyyy HH:mm'; ru='MMM dd/yyyy HH:mm'" );
	return "DF='" + text + "'";

EndFunction

&AtServer
Function DatetimeTitle () export

	text = NStr ( "en='Please select a date & time'; ro='Selectați data și ora'; ru='Выберите дату и время'" );
	return text;

EndFunction

&AtServer
Function DatetimePeriodTitle () export

	text = NStr ( "en='Please select a period & time'; ro='Selectați o perioadă și o oră'; ru='Выберите период и время'" );
	return text;

EndFunction

&AtClient
Function TaskNotes ( Params ) export

	text = NStr ( "en='%Date.%User.
				|Notes: %Notes'; ro='%Date.%User.
				|Comentariu: %Notes'; ru='%Date.%User.
				|Комментарий: %Notes'" );
	return FormatStr ( text, Params );

EndFunction

&AtClient
Function TaskDuration ( Params ) export

	text = NStr ( "en='%Start - %Finish, duration: %Duration'; ro='%Start - %Finish, durată: %Duration'; ru='%Start - %Finish, продолжительность: %Duration'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Procedure DocumentDateError1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Document date cannot be set to before the year 2000'; ro='Data documentului nu poate fi stabilită mai puțin de anul 2000'; ru='Дата документа не должна быть меньше 2000 года'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DocumentDateError2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Document date cannot exceed the year 2100'; ro='Data documentului nu poate depăși anul 2100'; ru='Дата документа не должна быть больше 2100 года'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure RecordRemovingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RecordRemovingConfirmation" ) export

	text = NStr ( "en='Are you sure you want to remove this record (or selected range of records)?'; ro='Ștergeți inregistrarea? (sau intervalul de înregistrări selectat) '; ru='Удалить запись?
				|(или выделенный диапазон записей)'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure SendToReworkConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SendToReworkConfirmation" ) export

	text = NStr ( "en='Would you like to return the order to rework?
				|
				|Note: if you want to inform the responsible person about any issues, you can add a note.
				|Simply close this message and press the ""Comments"" button.'; ro='Returnați comanda autorului pentru revizuire?
				|
				|Notă: înainte de aceasta, este de dorit să introduceți un comentariu explicativ.
				|Pentru a adăuga un comentariu, închideți această fereastră și faceți clic pe butonul Comentarii.'; ru='Вернуть заказ его автору на доработку?
				|
				|Примечание: перед этим, желательно ввести поясняющий комментарий.
				|Для добавления комментария, закройте это окно и нажмите кнопку Комментарий.'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure StoreDataErrorTryAgain ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Error occurred while saving data! 
				|Retry the operation'; ro='A apărut o eroare la salvarea datelor dvs.!
				|Repetați operația'; ru='Возникла ошибка сохранения данных!
				|Повторите операцию'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure ModificationTooltip ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ModificationTooltip" ) export

	text = NStr ( "en='Edits to the order will be permitted after closing this window.
				|Press the ""Complete Editing"" button to finalize your changes.'; ro='După închiderea acestei ferestre, comanda poate fi editată.
				|După editare, pentru a salva modificările, faceți clic pe butonul Finalizați modificările.'; ru='После закрытия этого окна, заказ можно будет отредактировать.
				|После редактирования, для сохранения изменений, нажмите кнопку  Завершить редактирование.'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Procedure DocumentOrderItemsNotValid ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The row cannot be reconciled with the document %DocumentOrder'; ro='Linia nu este în concordanță cu documentul %DocumentOrder'; ru='Строка не согласована с документом %DocumentOrder'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure OrdersBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Not enough %Resource item %Item  in order balance. The balance of %DocumentOrder is %ResourceBalance '; ro='Nu este suficientă %Resource a elementului %Item în restul comenzii. In soldul %DocumentOrder este %ResourceBalance'; ru='Не хватает %Resource товара %Item  в остатке заказа. В остатке %DocumentOrder числится %ResourceBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DeliveryDateError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Delivery date cannot be earlier  than document date'; ro='Data livrării nu poate fi mai devreme de data documentului'; ru='Дата доставки не может быть раньше даты документа'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure IncorrectDeliveryDate ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Delivery date is exceeding delivery date %DeliveryDate of linked order'; ro='Data livrării depășește data livrarii %DeliveryDate pentru comanda asociată'; ru='Дата доставки превышает дату доставки %DeliveryDate связанного заказа'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure InternalOrderClosingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Some items have not been delivered. This order cannot be completed'; ro='Nu toate bunurile sunt primite prin comanda dată. Comanda nu poate fi închisă'; ru='Еще не все товары получены по данной заявке. Заказ закрыть нельзя'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReservationBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The quantity  (%Quantity ) of item %Item  is insufficient. In warehouse %Warehouse, the quantity in store is  %QuantityBalance'; ro='Nu este suficient %Quantity de marfă %Item. În rezerva din depozitul %Warehouse este %QuantityBalance'; ru='Не хватает %Quantity товара %Item. В резерве на складе %Warehouse числится %QuantityBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ItemNotFilled ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='There are empty values in column %Column of table %Table. Please fill all values and attempt the operation again. '; ro='În tabelul %Table in coloana %Column există valori ne completate. Completați toate valorile și încercați din nou operația'; ru='В табличной части %Table в колонке %Column существуют незаполненные значения. Заполните все значения и повторите операцию'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure TableDoubleRows ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='In the %Table table, duplicate lines were detected for the following value(s); %Values.
				|Duplicate key values are not permitted. Please remove the duplicate lines or change their values'; ro='În tabelul %Table, există linii duble de valori pentru %Values.
				|Nu este permis duplicarea valorilor cheie. Ștergeți rândurile duplicate sau modificați valorile acestora'; ru='В табличной части %Table обнаружены дубли строк значений %Values.
				|Не допускается дублирование ключевых значений. Удалите повторяющиеся строки или измените их значения'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure TableIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Table part ""%Table"" is empty'; ro='Tabelul ""%Table"" nu este completat'; ru='Табличная часть ""%Table"" не заполнена'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function TotalLabel () export

	text = NStr ( "en='Total'; ro='Total'; ru='Итого'" );
	return text;

EndFunction

&AtClient
Procedure SaveNewObjectBeforeChoice ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SaveNewObjectBeforeChoice" ) export

	text = NStr ( "en='Before object selection, this object must be saved.
				|Save the object?'; ro='Înainte de a selecta elementul, acest obiect urmează să fie salvat.
				|Salvați obiectul?'; ru='Перед выбором элемента, этот объект необходимо записать.
				|Записать объект?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure LoadComplete ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "LoadComplete" ) export

	text = NStr ( "en='Upload is complete!'; ro='Încărcarea a fost finalizată!'; ru='Загрузка завершена!'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function Connecting () export

	text = NStr ( "en='Connecting...'; ro='Conectarea...'; ru='Соединение...'" );
	return text;

EndFunction

&AtClient
Procedure SaveModifiedTemplate ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SaveModifiedTemplate" ) export

	text = NStr ( "en='The template has been altered. 
				|Would you like to save your changes? '; ro='Modelul a fost schimbat.
				|Doriți să salvați modificările?'; ru='Шаблон был изменен.
				|Сохранить изменения?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure UserDataWillBeCleared ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UserDataWillBeCleared" ) export

	text = NStr ( "en='User''s data will be cleared.
				|Would you like to continue?'; ro='Datele introduse de utilizator vor fi șterse. 
				|Continuați?'; ru='Введенные пользователем данные будут очищены. 
				|Продолжить?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure ReportIsNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Report %Report was not found. The dependency was not created'; ro='Nu s-a găsit raportul %Report, dependența nu a fost generată'; ru='Не удалось найти отчет %Report, зависимость не сформирована'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure ReloadTemplateConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReloadTemplateConfirmation" ) export

	text = NStr ( "en='Entered changes will be lost. Would you like to continue loading?'; ro='Modificările efectuate vor fi pierdute. Continuați descărcarea?'; ru='Сделанные изменения будут утеряны. Продолжить загрузку?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtServer
Function MapFieldError () export

	text = NStr ( "en='mapField () calling error: ParamsList should be defined in order to pass list of codes'; ro='mapField () eroare de apelare: ParamsList ar trebui să fie definite pentru a trece lista de coduri'; ru='Ошибка вызова mapField (): при передаче списка кодов, параметр ParamsList должен быть задан'" );
	return text;

EndFunction

&AtServer
Function ReportNotCalculated ( Params ) export

	text = NStr ( "en='Report %Report is not yet calculated. The report should be opened a minimum of one time '; ro='Raportul %Report nu este încă calculat. Ar trebui să deschideți raportul cel puțin o dată'; ru='Отчет %Report еще не рассчитан. Для расчета отчета, требуется его открыть на экране хотя бы один раз'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Procedure ReportAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Report ID = %Name already exists'; ro='Raportul cu identificatorul %Name există deja'; ru='Отчет с идентификатором %Name уже существует'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure CancelDesignConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CancelDesignConfirmation" ) export

	text = NStr ( "en='The template has been altered. 
				|Are you sure you want to cancel editing without saving?'; ro='Modelul a fost modificat.
				|Doriți să anulați editarea fără salvare?'; ru='Шаблон был изменен.
				|Отменить редактирование без сохранения?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure BPNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "BPNotFound" ) export

	text = NStr ( "en='Business process not found'; ro='Procesul de afaceri nu a fost găsit'; ru='Бизнес-процесс не найден'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure ScheduleDayNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ScheduleDayNotFound" ) export

	text = NStr ( "en='No record found in schedule on the date selected.
				|The schedule was probably not recorded yet.
				|If you filled our schedule in but want to make changes, please use the ""Manual changes"" button'; ro='Nu sa găsit nicio înregistrare în orar la data selectată.
				|Cel mai probabil orarul nu a fost înregistrat încă.
				|Dacă ați completat orarul, dar doriți să faceți modificări, utilizați butonul ""Modificări manuale""'; ru='На указанную дату в графике записи нет.
				|Возможно, график еще не был записан.
				|Если график заполнен, и вы хотите внести некоторые изменения,
				|воспользуйтесь кнопкой Ручные изменения'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure SelectWebColor ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "SelectWebColor" ) export

	text = NStr ( "en='Please select a color from the Web-colors set.
				|The use of stylized or absolute colors is not permitted'; ro='Selectați o culoare din setul de culori Web.
				|Utilizarea culorilor stilizate sau absolute nu este permisă'; ru='Выберите пожалуйста цвет из набора Web-цветов.
				|Использование стилизованных или абсолютных цветов недопустимо'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure NewEmails ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export

	text = NStr ( "en='Checking email'; ro='Verificarea e-mailului'; ru='Проверка почты'" );
	explanation = NStr ( "en='%Message'; ro='%Message'; ru='%Message'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );

EndProcedure

&AtServer
Procedure EmailAlreadyPosted ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='E-mail was already sent'; ro='Scrisoarea a fost deja trimisă'; ru='Письмо уже было отослано'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure InvalidHolidayDay ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The date of the Holiday must fall within the calendar year for which a record was created'; ro='Data de sarbatoare selectată trebuie să se încadreze în același an calendaristic'; ru='Выбранная дата праздника должна быть в том году, в котором вводится календарь'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure InvalidScheduleDay ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The selected date must be within the same calendar year as the schedule '; ro='Data selectată trebuie să se afle în același an calendaristic în care creați orarul'; ru='Выбранная дата должна быть в том году, в котором вводится график'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LabelIsIncorrect ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The Folder type must correspond to the Label type. Error: Folder type: %ParentType, Label type: %LabelType'; ro='Tipul de grup trebuie să se potrivească cu tipul etichetei. Eroare: Tip grup: %ParentType, tip etichetă: %LabelType'; ru='Тип группы должен соответствовать типу метки. Ошибка: Тип группы: %ParentType, тип метки: %LabelType'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure MailLabelDeletionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='System labels cannot be removed '; ro='Nu puteți șterge eticheta de sistem'; ru='Нельзя удалить системную метку'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure TimeEntryAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='A Time Entry has already been created for the %Customer on %Date'; ro='Pentru %Customer la %Date a fost deja introdusă Foaia de pontaj'; ru='Для %Customer на %Date уже была введена запись времени'" );
	putMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure TrashFolderError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Adding labels to the Trash folder is not allowed'; ro='Nu puteți adăuga etichete în coș.'; ru='Нельзя добавлять метки в корзину'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure YearAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This year''s schedule already exists in the list.
				|Please select another year'; ro='Programul de lucru există deja pentru acest an.
				|Introduceți un alt an'; ru='В списке уже существует график для этого года.
				|Укажите другой год'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ApplyingChanges () export

	text = NStr ( "en='Applying changes...'; ro='Aplicarea modificărilor ...'; ru='Применяются изменения...'" );
	return text;

EndFunction

&AtServer
Function CheckingMailbox ( Params ) export

	text = NStr ( "en='Checking: %Mailbox'; ro='Verificarea: %Mailbox'; ru='Проверка: %Mailbox'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function Forward ( Params ) export

	text = NStr ( "en='Forwarded by %Email<br>
				|----------------------- Original Message -----------------------<br>
				|From: %From<br>
				|To: %To<br>
				|Cc: %Cc<br>
				|Date: %Date<br>
				|Subject: %Subject<br>'; ro='Trimis %Email<br>
				|----------------------- Mesaj original -----------------------<br>
				|De la: %From<br>
				|Pentru: %To<br>
				|Cc: %Cc<br>
				|Data: %Date<br>
				|Subiect: %Subject<br>'; ru='Переслал %Email<br>
				|----------------------- Исходное сообщение -----------------------<br>
				|От: %From<br>
				|К: %To<br>
				|Копии: %Cc<br>
				|Дата: %Date<br>
				|Тема: %Subject<br>'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ForwardEnd () export

	text = NStr ( "en='--------------------- Original Message Ends --------------------'; ro='--------------------- Sfârșitul mesajului original ---------------------'; ru='--------------------- Конец исходного сообщения --------------------'" );
	return text;

EndFunction

&AtServer
Function LastMessageUIDError () export

	text = NStr ( "en='System cannot define last message number'; ro='Sistemul nu poate defini ultimul număr al mesajului'; ru='Не удается получить последний номер сообщения'" );
	return text;

EndFunction

&AtServer
Function LeftLabel () export

	text = NStr ( "en='Left:'; ro='Rămas:'; ru='Осталось:'" );
	return text;

EndFunction

&AtServer
Function Loaded ( Params ) export

	text = NStr ( "en='Loaded: %Count emails'; ro='Încărcat: %Count de e-mailuri'; ru='Загружено: %Count писем'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function LoadingMessages ( Params ) export

	text = NStr ( "en='Loading: %Count/%Total messages…'; ro='Descărcare: %Count/%Total mesaje ...'; ru='Загрузка: %Count/%Total сообщений…'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ManyNewMessages ( Params ) export

	text = NStr ( "en='The mailbox contains too many (more than %Count) new messages'; ro='În cutia poștală prea mult (mai mult %Count) de mesaje necitite'; ru='В почтовом ящике слишком много (более %Count) непрочитанных сообщений'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function MyMail () export

	text = NStr ( "en='My mail'; ro='E-mailurile mele'; ru='Моя почта'" );
	return text;

EndFunction

Function NewTimeEntry () export

	text = NStr ( "en='Time record (create)'; ro='Înregistrarea de timp (crează)'; ru='Запись времени (создать)'" );
	return text;

EndFunction

&AtServer
Function NotificationEmailFooter ( Params ) export

	text = NStr ( "en='
				|
				|If you use the system but want to stop getting notifications, please click the link below and configure notifications settings:
				|%UserSettingsURL
				|
				|If you received this message by mistake or you have additional questions, please send e-mail to:
				|%Support
				|
				|Please do not reply on this notification e-mail.
				|
				|Best regards,
				|Support team
				|%Website'; ro='
				|
				|Dacă sunteți utilizator al sistemului, dar nu mai doriți să primiți notificări, accesați link-ul de mai jos, unde puteți configura notificările:
				|%UserSettingsURL
				|
				|Dacă ați primit această scrisoare din greșeală sau dacă aveți întrebări suplimentare, vă rugăm să ne scrieți la:
				|%Support
				|
				|Aceasta a fost o scrisoare de notificare, nu trebuie să i se răspundă.
				|Cu stimă, echipa de specialiști %Website'; ru='
				|
				|Если вы являетесь пользователем системы, но больше не хотите получать уведомления, перейдите по указанной ниже ссылке, там вы сможете произвести настройку уведомлений:
				|%UserSettingsURL
				|
				|Если вы получили это письмо по ошибке, или у вас есть дополнительные вопросы, пожалуйста, пишите нам по адресу:
				|%Support
				|
				|Это было уведомительное письмо, на него не нужно отвечать.
				|С уважением, команда специалистов %Website'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function Outbox () export

	text = NStr ( "en='Outbox'; ro='Mesaje de trimis'; ru='Исходящие'" );
	return text;

EndFunction

&AtServer
Function Over () export

	text = NStr ( "en='Over:'; ro='Surplus:'; ru='Сверх:'" );
	return text;

EndFunction

&AtServer
Function Performed () export

	text = NStr ( "en='Done:'; ro='Realizat de:'; ru='Сделано:'" );
	return text;

EndFunction

&AtServer
Function ReceivingProfiles () export

	text = NStr ( "en='Receiving profiles'; ro='Obținerea de profiluri'; ru='Получение профайлов'" );
	return text;

EndFunction

&AtServer
Function ReminderBody ( Params ) export

	text = NStr ( "en='%TimeEntry
				|Employee: %Employee
				|Customer: %Customer
				|Project: %Project
				|Tasks:
				|%Tasks
				|Time record can be opened here:
				|%URL'; ro='%TimeEntry
				|Angajat: %Employee
				|Client: %Customer
				|Proiect: %Project
				|obiective:
				|%Tasks
				|Inregistrarea timpului poate fi deschisa de link-ul:
				|%URL'; ru='%TimeEntry
				|Сотрудник: %Employee
				|Клиент: %Customer
				|Проект: %Project
				|Задачи:
				|%Tasks
				|Запись времени можно открыть по ссылке:
				|%URL'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ReminderSubject ( Params ) export

	text = NStr ( "en='Reminder: %ReminderDescription'; ro='Memento: %ReminderDescription'; ru='Напоминание: %ReminderDescription'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function Reply ( Params ) export

	text = NStr ( "en='%Address, %Date, wrote:'; ro='%Address, %Date, a scris:'; ru='%Address, %Date, писал:'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function SearchResultIsTooBig () export

	text = NStr ( "en='Too many search results'; ro='Prea multe rezultate de căutare'; ru='Слишком много результатов поиска'" );
	return text;

EndFunction

&AtServer
Function Size () export

	text = NStr ( "en='Size'; ro='Dimensiune'; ru='Размер'" );
	return text;

EndFunction

&AtClient
Function StrDate () export

	text = NStr ( "en='Date'; ro='Data'; ru='Дата'" );
	return text;

EndFunction

&AtServer
Function StringNotFound () export

	text = NStr ( "en='Search string was not found'; ro='Șirul nu a fost găsit'; ru='Строка не найдена'" );
	return text;

EndFunction

&AtServer
Function TimeEntry () export

	text = NStr ( "en='Time Record'; ro='Înregistrarea de timp'; ru='Запись времени'" );
	return text;

EndFunction

&AtServer
Function Command () export

	text = NStr ( "en='Command'; ro='Dispoziție'; ru='Распоряжение'" );
	return text;

EndFunction

&AtServer
Function Project () export

	text = NStr ( "en='Project'; ro='Proiect'; ru='Проект'" );
	return text;

EndFunction

&AtServer
Function Meeting () export

	text = NStr ("en = 'Meeting'; ro = 'Întâlnire'; ru = 'Встреча'" );
	return text;

EndFunction

&AtServer
Function TimeEntryRow ( Params ) export

	text = NStr ( "en='%LineNumber) %TimeStart - %TimeEnd = %Duration, %Description, task: %TaskDescription'; ro='%LineNumber) %TimeStart - %TimeEnd = %Duration, %Description, sarcina: %TaskDescription'; ru='%LineNumber) %TimeStart - %TimeEnd = %Duration, %Description, задача: %TaskDescription'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure MailboxIsNotConfigured ( Module, CallbackParams = undefined, Params = undefined, ProcName = "MailboxIsNotConfigured" ) export

	text = NStr ( "en='Mailbox is not configured.
				|Would you like to configure it now?'; ro='Profilul e-mail nu este configurat.
				|Doriți să o configurați chiar acum?'; ru='Почтовый профайл не настроен.
				|Настроить его прямо сейчас?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure RemoveFilesConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RemoveFilesConfirmation" ) export

	text = NStr ( "en='Are you sure you want to delete the selected files?'; ro='Ștergeți fișierele selectate?'; ru='Удалить выделенные файлы?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure RemoveLabelConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RemoveLabelConfirmation" ) export

	text = NStr ( "en='Are you sure you want to remove the label?'; ro='Ștergeți eticheta?'; ru='Удалить метку?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure RemoveMailboxConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RemoveMailboxConfirmation" ) export

	text = NStr ( "en='Are you sure you want to remove Mailbox?'; ro='Sigur doriți să ștergeți Cutia poștală?'; ru='Удалить почтовый ящик?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure RemoveScheduleYear ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RemoveScheduleYear" ) export

	text = NStr ( "en='Are you sure you want to remove the timesheet for the selected year?'; ro='Sigur doriți să ștergeți foaia de pontaj pentru anul selectat?'; ru='Удалить график за выбранный год?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure RemoveTimeEntryConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RemoveTimeEntryConfirmation" ) export

	text = NStr ( "en='Are you sure you want to remove time record?
				|(The record will be permanently removed)'; ro='Sigur doriți să eliminați înregistrarea de timp?
				|(înregistrarea va fi ștearsă definitiv)'; ru='Удалить запись времени?
				|(запись будет удалена навсегда)'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure TaskToTimeEntry ( Module, CallbackParams = undefined, Params = undefined, ProcName = "TaskToTimeEntry" ) export

	text = NStr ( "en='Would you like to move the data to the Time record document?'; ro='Transferați datele în documentul Foaie de pontaj?'; ru='Перенести данные в документ Запись времени?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure UncheckManualChanges ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UncheckManualChanges" ) export

	text = NStr ( "en='Are you sure you want to disable manual correction mode?
				|All manual changes that have been made to the schedule will be lost '; ro='Opriți posibilitatea rectificarilor manuale?
				|Dacă ați efectuat modificări manuale ale programului,
				|aceste schimbări vor fi pierdute '; ru='Выключить возможность ручных корректировок?
				|Если вы вносили какие-то ручные изменения в график,
				|эти изменения будут утеряны'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function Deleted () export

	text = NStr ( "en='Deleted'; ro='Șterse'; ru='Удаленные'" );
	return text;

EndFunction

&AtServer
Function ToClause () export

	text = NStr ( "en='To:'; ro='Către:'; ru='К:'" );
	return text;

EndFunction

&AtServer
Function OutClause () export

	text = NStr ( "en='Out:'; ro='De ieșire:'; ru='Исх:'" );
	return text;

EndFunction

&AtClient
Function MailInbox () export

	text = NStr ( "en='Inbox'; ro='Mesaje primite'; ru='Входящие'" );
	return text;

EndFunction

&AtClient
Function Mailbox () export

	text = NStr ( "en='Mail'; ro='Poștă'; ru='Почта'" );
	return text;

EndFunction

&AtClient
Function MailTrash () export

	text = NStr ( "en='Trash'; ro='Gunoi'; ru='Корзина'" );
	return text;

EndFunction

&AtClient
Function MailOutbox () export

	text = NStr ( "en='Outbox'; ro='Mesaje de trimis'; ru='Исходящие'" );
	return text;

EndFunction

&AtServer
Procedure CannotRemoveMailbox ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The Mail account cannot be removed at this time because an email is currently being received.
				|Please try again later'; ro='Nu puteți șterge contul de poștă electronică în acest moment, deoarece primirea e-mailului este în proces. Încercați mai târziu'; ru='Сейчас нельзя удалить почтовый ящик, почта в процессе получения, повторите попытку позже'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function OutgoingError ( Params ) export

	text = NStr ( "en='%Outgoing sending error'; ro='Nu s-a reușit să se trimită e-mailul %Outgoing'; ru='Не удалось отправить письмо %Outgoing'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Procedure PaymentDateError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Payment date cannot be earlier than the date of the document'; ro='Data plății nu poate fi mai devreme de data documentului'; ru='Дата оплаты не может быть раньше даты документа'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure BillAmountGreatPaymentsByBase ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Amount of payment must be equal to total amount of payment stages'; ro='Suma plății trebuie să fie egală cu suma etapelor de plată'; ru='Сумма оплаты должна равняться сумме этапов оплат'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PaymentsBillBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Payment of a bill on document %Document was exceeded by %Amount. The balance is %AmountBalance'; ro='Depășită cu %Amount pentru contul documentului %Document. Soldul este %AmountBalance'; ru='Превышена на %Amount оплата счету для документа %Document. В остатке  числится %AmountBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

Function CantCreateTenantCode () export

	text = NStr ( "en='Unique client code creation failed'; ro='Crearea unui cod client unic a eșuat'; ru='Не удалось создать уникальный код для клиента'" );
	return text;

EndFunction

Function GeneralLoginNotFound ( Params ) export

	text = NStr ( "en='Can''t find account with the following parameters: Tenant=%TenantCode, User=%User'; ro='Nu a putut fi găsit un cont cu următorii parametri: Tenant=%TenantCode, User=%User'; ru='Не удалось найти учетную запись с параметрами: Tenant=%TenantCode, User=%User'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function TenantOrderNotFound ( Params ) export

	text = NStr ( "en='Can''t find the order #%OrderNumber'; ro='Nu se poate găsi comanda #%OrderNumber'; ru='Заказ по номеру #%OrderNumber не найден'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure Debt ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "Debt" ) export

	text = NStr ( "en='Access denied.
				|Reason: Service fees overdue.
				|Solution: Please call the administrator responsible for financial activities.'; ro='Din păcate, accesul la sistem este interzis.
				|Motivul: termenul de plată pentru serviciu a expirat.
				|Soluție: Vă rugăm să sunați administratorul responsabil pentru activitatea financiară'; ru='К сожалению, доступ в систему запрещен.
				|Причина: просрочена оплата за сервис.
				|Решение: обратитесь пожалуйста к ответственному за взаиморасчеты сотруднику вашей компании.'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure InvoiceWrongBase ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "InvoiceWrongBase" ) export

	text = NStr ( "en='Customer and currency fields must match '; ro='Câmpurile clientului și valutei trebuie să se potrivească cu obiectele selectate'; ru='У выбранных объектов поля Клиент и Валюта должны совпадать'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure ProfileDeactivated ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ProfileDeactivated" ) export

	text = NStr ( "en='This tenant profile has been deactivated.
				|Please send an e-mail regarding the status of the profile to %Info '; ro='Profilul chiriașului este dezactivat.
				|Pentru activare, vă rugăm să contactați:
				|%Info'; ru='Профиль арендатора деактивирован.
				|По вопросам активации обращайтесь по адресу:
				|%Info'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure RowContainsTimeEntries ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "RowContainsTimeEntries" ) export

	text = NStr ( "en='Cannot remove the row because it contains time records.
				|To remove the row please remove all related time records '; ro='Nu se poate șterge rândul deoarece conține înregistrări de timp.
				|Pentru a șterge rândul vă rugăm să ștergeți toate înregistrările de timp asociate'; ru='Строку удалить нельзя, в ней содержатся связанные записи времени.
				|Для возможности удалить строку, необходимо удалить все связанные с ней записи времени'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure TenantOrderAccessError ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "TenantOrderAccessError" ) export

	text = NStr ( "en='You do not have sufficient permissions to pay.
				|Please contact the administrator responsible for financial operations'; ro='Nu aveți permisiunea de a plăti.
				|Vă rugăm să sunați administratorul responsabil pentru operațiunile financiare'; ru='У вас нет прав на осуществление оплаты.
				|Обратитесь пожалуйста к ответственному за взаиморасчеты сотруднику вашей компании'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Procedure CannotCopyTimesheet ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Duplication of a Timesheet is not permitted '; ro='Copierea foilor de pontaj  nu este permisă'; ru='Копирование табелей не допускается'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DemoMode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This operation is not permitted in demo-mode'; ro='Operația nu este disponibilă în regimul-demo'; ru='Операция недоступна в демо-режиме'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DoublesApprovalList ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Users cannot be duplicated in the list of claims administrators'; ro='Utilizatorii nu se pot repeta în lista de aprobatori'; ru='Пользователи не могут повторяться в списке утверждающих лиц'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DoublesEmployeesAndTasks ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='You have assigned more than one hourly rate for this task. 
				|The same task cannot be assigned multiple rates. 
				|Please create another task, or assign the same rate (including costs) to all instances of this task'; ro='Angajatului i se atribuie o sarcină pentru diferite tarife pe ore. Nu puteți aloca aceeași sarcină la tarife diferite. Vă rugăm să atribuiți o altă sarcină sau să efectuați aceeași rată orară (inclusiv costurile)'; ru='Сотруднику определена задача по разным часовыми тарифам. Нельзя назначать одну и туже задачу по разным тарифам. Назначьте другую задачу или сделайте одинаковым часовой тариф (включая себестоимость)'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DoubleTimesheetRow ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Duplicate data detected. Please use only one line for data entry'; ro='O înregistrare cu astfel de date există deja. Utilizați o singură linie pentru introducerea datelor'; ru='Запись с такими данными уже существует. Используйте пожалуйста только одну строку для ввода данных'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure IllegalFolderCurrency ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The currency cannot be changed. This group already contains projects'; ro='Nu puteți modifica valuta, acest grup conține deja proiecte'; ru='Валюту изменить нельзя, эта группа уже содержит проекты'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LicenseDateStartError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The start date of the license cannot be set to before the current date'; ro='Licența nu poate începe înainte de data curentă'; ru='Дата начала действия лицензии не может быть раньше текущей даты'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure OrganizationAccessMustBeInstalled ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Restricted access to organizations must be set for client''s employees'; ro='Pentru utilizatorii clientului, restricționarea accesului la terț trebuie să fie stabilită în mod obligatoriu'; ru='Для пользователей клиента, ограничение доступа к контрагент необходимо установить в обязательном порядке'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ProjectCurrencyMismatch ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The currency used for this project must match the project group''s currency '; ro='Valuta proiectului trebuie să fie aceeași cu valuta grupului de proiect'; ru='Валюта проекта должна совпадать с валютой группы проектов'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ProjectPeriodError1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The project end date cannot be earlier than the start date'; ro='Data finalizării proiectului nu poate fi mai devreme decât data de începere'; ru='Дата окончания проекта раньше даты его начала'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ProjectPeriodError2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Project completion date is earlier than the start date'; ro='Data finalizării proiectului este mai devreme decât data de începere'; ru='Дата завершения проекта раньше даты его начала'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure TenantOrderCannotBeChanged ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Tenant order cannot be changed'; ro='Comanda chiriasului nu poate fi schimbată'; ru='Заказ арендатора не может быть изменен'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure TenantOrderDeletionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Removal of paid orders was denied '; ro='Nu puteți șterge comenzi plătite'; ru='Нельзя удалять оплаченные заказы'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure TimesheetCannotBeChanged ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The timesheet cannot be removed because the approval process is in progress'; ro='Nu puteți elimina foaia de pontaj. Procesul de aprobare este în desfășurare'; ru='Табель нельзя удалить или снять с проведения, по нему был запущен процесс одобрения'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure TimesheetComprisesTimeEntry ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Time record for %Employee can only be changed or removed from %Timesheet'; ro='Înregistrarea timpului pentru %Employee poate fi modificată sau ștearsă numai din documentul %Timesheet'; ru='Запись времени для %Employee может быть изменена или удалена только из документа %Timesheet'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UserCannotApprove ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Timesheet approval was denied for %Customer because they do not have access permissions for this organization. Access can be set in ""Users"" directory'; ro='Utilizatorul nu poate aproba foaia de pontaj %Customer, deoarece nu are acces la acest terț. Accesul este specificat în catalogul Utilizatori'; ru='Пользователь не может утверждать табеля %Customer, потому что у него нет доступа к этому контрагенту. Доступ задается в справочнике Пользователи'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ApplicationShortcut ( Params ) export

	text = NStr ( "en='[Contabilizare]
				|Connect=ws=""%ApplicationURL/%TenantCode"";
				|External=0
				|UseProxy=0
				|App=Auto
				|WA=1
				|Version=8.3
				|WSA=1'; ro='[Contabilizare]
				|Connect=ws=""%ApplicationURL/%TenantCode"";
				|External=0
				|UseProxy=0
				|App=Auto
				|WA=1
				|Version=8.3
				|WSA=1'; ru='[Contabilizare]
				|Connect=ws=""%ApplicationURL/%TenantCode"";
				|External=0
				|UseProxy=0
				|App=Auto
				|WA=1
				|Version=8.3
				|WSA=1'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ApprovalEmailBody ( Params ) export

	text = NStr ( "en='Hello,
				|
				|You have received this notification because a timesheet for employee %Employee requires your approval.
				|
				|Direct link to the timesheet:
				|%TimesheetURL'; ro='Salut!
				|Ați primit această notificare pentru că trebuie să aprobați o foaie de pontaj pentru angajatul %Employee.
				|
				|Link direct la foaia de pontaj:
				|%TimesheetURL'; ru='Доброго времени суток!
				|Вы получили уведомление о необходимости утвердить табель сотрудника %Employee.
				|
				|Прямая ссылка на табель:
				|%TimesheetURL'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ApprovalEmailSubject ( Params ) export

	text = NStr ( "en='Timesheet approval #%TimesheetNumber: %Employee'; ro='Validarea foii de pontaj #%TimesheetNumber: %Employee'; ru='Утверждение табеля #%TimesheetNumber: %Employee'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function EndOfLicensePeriodBody ( Params ) export

	text = NStr ( "en='Hello,
				|
				|You have received this e-mail because you are a Contabilizare service user.
				|Your order #%OrderNumber expire in %CountDays. There are %UsersCount users.
				|
				|To pay for the service, please go to:
				|%TenantOrder
				|
				|To review current order information, please go to:
				|%TenantOrderList
				|
				|Thank you for your cooperation!
				|If you have additional questions or suggestions, please send us e-mail at %Info
				|
				|Best regards,
				|Development team
				|%Website'; ro='Bună ziua!
				|Ați primit acest e-mail deoarece utilizați serviciul Contabilizare.
				|După %CountOfDays, perioada de acțiune a comenzii se termină #%OrderNumber, numărul de utilizatori: %UsersCount.
				|
				|Pentru a plăti serviciul, utilizați linkul:
				|%TenantOrder
				|
				|Pentru a vizualiza datele pentru comenzile curente, folosiți linkul:
				|%TenantOrderList
				|
				|Vă mulțumim pentru cooperarea dvs.!
				|Dacă aveți întrebări sau sugestii, scrieți-ne la %Info.
				|Cu stimă, echipa de specialiști %Website'; ru='Доброго времени суток!
				|Вы получили это письмо, потому что используете сервис Contabilizare.
				|Через %CountOfDays дней заканчивается период действия заказа #%OrderNumber, количество пользователей: %UsersCount.
				|
				|Для оплаты сервиса, воспользуйтесь ссылкой:
				|%TenantOrder
				|
				|Для просмотра данных по текущим заказам, воспользуйтесь ссылкой:
				|%TenantOrderList
				|
				|Спасибо за сотрудничество!
				|Если у Вас есть какие-либо вопросы или предложения, пишите нам по адресу %Info.
				|С уважением, команда специалистов %Website'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function EndOfLicensePeriodSubject ( Params ) export

	text = NStr ( "en='Access to Contabilizare system will expire in %CountOfDays days'; ro='Până la sfârșitul perioadei de acces la Contabilizare, rămân %CountOfDays zile'; ru='До окончания периода доступа к Contabilizare осталось %CountOfDays дней'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function EndOfTrialPeriodBody ( Params ) export

	text = NStr ( "en='Hello,
				|
				|You have received this e-mail because you are now a registered Contabilizare service user.
				|Your trial period will expire in %CountOfDays days.
				|You can order the full version of our software by following this link:
				|%TenantOrder
				|
				|If you want to stop using the Contabilizare service, you can remove your profile.
				|In order to do this please follow the link:
				|%DeactivateProfile
				|
				|Thank you for your interest in our service.
				|If you have any questions, please send us an e-mail at %Info.
				|
				|Sincerely,
				|%Website'; ro='Bună ziua!
				|Ați primit acest e-mail deoarece ați fost înregistrat la serviciul Contabilizare.
				|Perioada de familiarizare cu programul se termină în %CountOfDays.
				|Dacă v-a plăcut serviciul nostru, puteți face o comandă și puteți plăti prin linkul:
				|%TenantOrder
				|
				|Dacă nu mai plănuiți să lucrați în Contabilizare, puteți șterge profilul.
				|Pentru aceasta, faceți clic pe link-ul:
				|%DeactivateProfile
				|
				|Vă mulțumim pentru interesul față de resursele noastre.
				|Dacă aveți întrebări, scrieți-ne la %Info.
				|Cu stimă, echipa de specialiști %Website'; ru='Доброго времени суток!
				|Вы получили это письмо, потому что были зарегистрированы в сервисе Contabilizare.
				|Период ознакомления с программой заканчивается через %CountOfDays дней.
				|Если вам понравился наш сервис, Вы можете произвести заказ и оплату по ссылке:
				|%TenantOrder
				|
				|Если вы больше не планируете работать в Contabilizare, Вы можете удалить свой профайл.
				|Для этого нужно перейти по ссылке:
				|%DeactivateProfile
				|
				|Спасибо за проявленный интерес к нашему ресурсу.
				|Если у Вас остались какие-либо вопросы, пишите нам по адресу %Info.
				|С уважением, команда специалистов %Website'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function EndOfTrialPeriodSubject ( Params ) export

	text = NStr ( "en='The trial period will expire in %CountOfDays days'; ro='Până la sfârșitul perioadei de familiarizare cu Contabilizare, au mai rămas %CountOfDays zile'; ru='До окончания периода ознакомления с Contabilizare осталось %CountOfDays дней'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function InvoiceInformation ( Params ) export

	text = NStr ( "en='The order has been made and sent to %Email!
				|
				|For uninterrupted access to the system, the invoice must be paid within 5 working days or before the license expiry date.
				|
				|You can close this form and continue working.
				|
				|Thank you!
				|'; ro='Comanda este emisă și trimisă la adresa poștală %Email!
				|Pentru accesul neîntrerupt la serviciu, vă rugăm să efectuați plata înainte de expirarea perioadei de licență sau a perioadei de probă.
				|
				|Vă mulțumim pentru cooperarea dvs.!
				|
				|Puteți închide acest formular și puteți continua să lucrați cu programul.'; ru='Заказ оформлен и выслан на почтовый адрес %Email!
				|Для бесперебойного доступа к сервису, произведите пожалуйста оплату до окончания срока действия текущей лицензии или пробного периода.
				|
				|Спасибо за сотрудничество!
				|
				|Вы можете закрыть эту форму и продолжить работу с программой.'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function LicensePeriodInformation ( Params ) export

	text = NStr ( "en='License will be expire in %DaysRemain days'; ro='Licența va expira în %DaysRemain zile'; ru='До окончания лицензии осталось %DaysRemain дн.'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function Password1 () export

	text = NStr ( "en='Password: you must set a password on the first attempt to log in to the system'; ro='Parola: trebuie să setați parola la prima încercare de conectare la sistem'; ru='Пароль: вам потребуется установить его при первом входе в систему.'" );
	return text;

EndFunction

&AtServer
Function Password2 ( Params ) export

	text = NStr ( "en='Password: Your system administrator has already set up your password.
				|We do not store your passwords or send them to any third party.
				|To reset your password, please contact your system administrator at %AdminEmail or any other preferred method'; ro='Password: Administratorul de sistem v-a stabilit deja o parolă.
				|Nu trimitem și nu stocăm parole de utilizatori.
				|Pentru a vă clarifica parola, contactați administratorul de sistem la %AdminEmail sau altfel.'; ru='Пароль: Администратор системы уже установил вам пароль.
				|Мы не высылаем и не храним пароли пользователей.
				|Для уточнения вашего пароля, свяжитесь с системным администратором по адресу %AdminEmail или другим способом.'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function Password3 () export

	text = NStr ( "en='Password: You have not set a password.
				|We strongly recommend setting it as soon as possible by using the application''s administrative interface.'; ro='Parola: nu aveți parola setată.
				|Vă recomandăm insistent să o setați cât mai curând posibil.'; ru='Пароль: вам не был установлен пароль.
				|Мы рекомендуем вам установить его при первой возможности, используя административный раздел приложения.'" );
	return text;

EndFunction

Function PaymentStep1 () export

	text = NStr ( "en='Step 1. Create order'; ro='Pasul 1: Creați o comandă'; ru='Шаг 1. Создание заказа'" );
	return text;

EndFunction

&AtClient
Function PaymentStep2 () export

	text = NStr ( "en='Step 2. Choose payment method'; ro='Pasul 2. Alegeți o metodă de plată'; ru='Шаг 2. Выбор способа оплаты'" );
	return text;

EndFunction

&AtClient
Function PaymentStep3 () export

	text = NStr ( "en='Step 3. Order payment'; ro='Pasul 3. Plata pentru comanda'; ru='Шаг 3. Оплата заказа'" );
	return text;

EndFunction

&AtServer
Function PaymentStep4Bank () export

	text = NStr ( "en='Step 4. Invoice has been sent by email'; ro='Pasul 4. Factura a fost trimisă prin e-mail'; ru='Шаг 4. Счет на оплату был выслан на почту'" );
	return text;

EndFunction

&AtClient
Function PaymentStep4PayPal () export

	text = NStr ( "en='Step 4. Payment process completed successfully'; ro='Pasul 4: Plata a fost efectuată cu succes'; ru='Шаг 4. Оплата успешно завершена'" );
	return text;

EndFunction

&AtServer
Function Plan () export

	text = NStr ( "en='Plan:'; ro='Plan:'; ru='План:'" );
	return text;

EndFunction

&AtServer
Function RegistrationDataEmailBody ( Params ) export

	text = NStr ( "en='Hello,
				|
				|
				|You received registration data from %AdminEmail to access Contabilizare System %Website:
				|
				|Tenant code: %TenantCode
				|User name: %User
				|%Password
				|
				|Direct URL to access the application:
				|%TenantURL
				|
				|If you experience any difficulties while using the system, or if you have any questions or suggestions:
				|- please e-mail us at %Support
				|- please leave a message on our forum at %Forum
				|
				|We also offer additional services:
				|- developing cloud solutions for the specific needs of your organization
				|- transferring data and applications from the cloud to your on-premise environment
				|
				|If you are interested please send us an e-mail at %Info
				|
				|This e-mail has attachment. The attachment is a configuration file which will allow you to run our special ""thin"" client.
				|Although you can work with the system from virtually any Internet browser, the thin client offers the richest experience.
				|You can download and install this software from:
				|%ThinClientURL
				|
				|(System requirements are: Windows 7 / 8.*, Windows Server 2000 / 2003 / 2008 / 2008 / 2012 / R2, Windows XP/Vista)
				|
				|Thank you for your interest in our resource.
				|We hope to be helpful to you and your organization! 
				|
				|Best regards,
				|Development team
				|%Website'; ro='Salut!
				|Ați primit date de înregistrare de la %AdminEmail pentru a accesa Sistemul Contabilizare %Website:
				|
				|Codul chiriașului: %TenantCode
				|Nume utilizator: %User
				|%Password
				|
				|Adresa URL directă pentru a accesa aplicația:
				|%TenantURL
				|
				|Dacă aveți dificultăți în utilizarea sistemului sau aveți întrebări și sugestii atunci:
				|- vă rugăm să ne trimiteți un e-mail către %Support
				|- vă rugăm să lăsați mesaj pe forumul nostru la %Forum
				|
				|De asemenea, oferim servicii suplimentare:
				|- dezvoltarea de soluții cloud în funcție de organizația dvs.
				|- transferul de date și aplicații din mediul cloud către mediul înconjurător
				|
				|Dacă sunteți interesat, vă rugăm să ne trimiteți e-mail la %Info  
				|
				|Acest e-mail are atașament. Atașamentul este un fișier de configurare pentru a rula un client ""subțire"" special.
				|Deși puteți lucra cu sistemul din orice browser de internet, puteți obține cea mai bogată experiență prin colaborarea cu un client ""subțire"".
				|Puteți descărca și instala acest software de la:
				|%ThinClientUR
				|L
				|(Cerințele de sistem sunt: Windows 7 / 8. *, Windows Server 2000/2003/2008/2008/2012 / R2, Windows XP / Vista)
				|
				|Vă mulțumim pentru interesul acordat resurselor noastre.
				|Vom fi bucuroși dacă serviciul nostru vă va fi de ajutor!
				|Cu stimă, echipa de specialiști %Website'; ru='Доброго времени суток!
				|Вы получили от пользователя %AdminEmail регистрационные данные для доступа в систему Contabilizare на сайте %Website:
				|
				|Код арендатора:  %TenantCode
				|Пользователь: %User
				|%Password
				|
				|Прямая ссылка на доступ к приложению:
				|%TenantURL
				|
				|Если у вас возникают трудности в освоении системы, вопросы, предложения, тогда:
				| - пишите нам на адрес %Support
				| - или общайтесь на форуме %Forum
				|
				|Дополнительно, мы предлагаем такие услуги:
				|- доработка предложенных в облаке решений под вашу специфику
				|- перенос программы и данных из облака в инфраструктуру вашего предприятия
				|Если вам это интересно, напишите нам по адресу %Info
				|
				|К этому письму есть вложение. Это конфигурационный файл для запуска специального «тонкого» клиента.
				|Несмотря на то, что работа с системой возможна практически из любого обозревателя, «тонкий клиент» более эффективно взаимодействует с нашим сервисом.
				|Эту программу вы можете скачать и установить в любое время по этой ссылке:
				|%ThinClientURL
				|(Системные требования: Windows 7 / 8.*, Windows Server 2000 / 2003 / 2008 / 2012 / R2, Windows XP / Vista, Windows 2000)
				|
				|Спасибо за проявленный интерес к нашему ресурсу.
				|Будем рады, если наш сервис окажется вам полезен!
				|С уважением, команда специалистов %Website'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function RegistrationDataEmailSubject ( Params ) export

	text = NStr ( "en='""%Company"" e-mailed you registration data to access Contabilizare'; ro='""%Company"" v-a trimis prin e-mail datele de înregistrare pentru a accesa Contabilizare'; ru='""%Company"" выслал вам регистрационные данные для доступа в Contabilizare'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function RejectTimesheetEmailBody ( Params ) export

	text = NStr ( "en='Hello,
				|
				|You have received this notification because part of your timesheet (or the whole timesheet) was rejected.
				|User %User rejected your timesheet.
				| 
				|Direct link to the timesheet:
				|%TimesheetURL'; ro='Salut!
				|Ați primit această notificare deoarece o parte din foaia dvs. de pontaj (sau întreaga foaie) a fost respinsă.
				|Utilizatorul care a respins foaia dvs. de pontaj: %User
				|
				|Link direct la foaia de pontaj:
				|%TimesheetURL'; ru='Доброго времени суток!
				|Вы получили уведомление о том, что часть вашего табеля (или весь табель) была отклонена.
				|Пользователь, отклонивший время: %User
				|
				|Прямая ссылка на табель:
				|%TimesheetURL'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function RejectTimesheetEmailSubject ( Params ) export

	text = NStr ( "en='Timesheet rejected: #%TimesheetNumber'; ro='Tabel respins: #%TimesheetNumber'; ru='Табель отклонен: #%TimesheetNumber'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ReworkTimesheetEmailBody ( Params ) export

	text = NStr ( "en='Hello,
				|
				|You have received this notification because timesheet #%TimesheetNumber requires additional work.
				|
				|Direct link to the timesheet:
				|%TimesheetURL'; ro='Salut,
				|Ați primit această notificare pentru că trebuie să vă refaceți foaia de pontaj #%TimesheetNumber.
				|
				|Link direct la foaia de pontaj:
				|%TimesheetURL'; ru='Доброго времени суток!
				|Вы получили уведомление о необходимости доработать свой табель #%TimesheetNumber.
				|
				|Прямая ссылка на табель:
				|%TimesheetURL'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ReworkTimesheetEmailSubject ( Params ) export

	text = NStr ( "en='Timesheet revision #%TimesheetNumber'; ro='Revizuirea foii de pontaj #%TimesheetNumber'; ru='Доработка табеля #%TimesheetNumber'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function TimeAccountingItemName ( Params ) export

	text = NStr ( "en='Access to application, Users: %UsersCount, Months: %MonthsCount'; ro='Acces la aplicație, Utilizatori: %UsersCount, Luni: %MonthsCount'; ru='Доступ к приложению, Пользователи: %UsersCount, месяцы: %MonthsCount'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function TimesheetApprovalCompleteEmailBody ( Params ) export

	text = NStr ( "en='Hello,
				|You received this notification because your timesheet was approved: #%TimesheetNumber.
				|
				|Direct link to the timesheet:
				|%TimesheetURL'; ro='Bună ziua!
				|Ați fost notificat (ă) că procesul de aprobare pentru tabelul dvs. de pontaj a fost finalizat: #%TimesheetNumber.
				|
				|Link direct la tabelul de pontaj:
				|%TimesheetURL'; ru='Доброго времени суток!
				|Вы получили уведомление о том, что процесс одобрения вашего табеля был завершен: #%TimesheetNumber.
				|
				|Прямая ссылка на табель:
				|%TimesheetURL'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function TimesheetApprovalCompleteEmailSubject ( Params ) export

	text = NStr ( "en='Your timesheet was approved: %TimesheetNumber'; ro='Tabelul dvs. de pontaj a fost aprobat: #%TimesheetNumber'; ru='Одобрение вашего табеля завершено: #%TimesheetNumber'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function TrialPeriodInformation ( Params ) export

	text = NStr ( "en='Trial period will expire in %DaysRemain days'; ro='Perioada de probă va expira în %DaysRemain zile'; ru='До окончания периода ознакомления осталось %DaysRemain дн.'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure ApplyResolutionsConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ApplyResolutionsConfirmation" ) export

	text = NStr ( "en='Would you like to apply the resolutions specified?'; ro='Doriți să aplicați rezoluțiile specificate?'; ru='Применить указанные резолюции?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure ApproveTimesheetConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ApproveTimesheetConfirmation" ) export

	text = NStr ( "en='Would you like to set positive resolutions and approve the entire timesheet?'; ro='Doriți să stabiliți rezoluții pozitive și să aprobați întreaga foaie de pontaj?'; ru='Установить положительные резолюции и одобрить табель целиком?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure BreakPaymentChecking ( Module, CallbackParams = undefined, Params = undefined, ProcName = "BreakPaymentChecking" ) export

	text = NStr ( "en='Are you sure you want to cancel payment verification?
				|(if you are not sure please press ""No"" and then press F1 to see help)'; ro='Anulați procesul de verificare a plății? 
				|(dacă nu sunteți sigur, răspundeți Nu și apăsați F1 pentru a apela ajutorul)'; ru='Прервать процесс проверки платежа?
				|(если вы не уверены, ответьте Нет и нажмите F1 для вызова справки)'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure BuyNowConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "BuyNowConfirmation" ) export

	text = NStr ( "en='Would you like to pay for this order?'; ro='Doriți să plătiți această comandă?'; ru='Произвести оплату заказа?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure CancelTenantOrder ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CancelTenantOrder" ) export

	text = NStr ( "en='Would you like to cancel tenant''s order?'; ro='Doriți să anulați comanda chiriașului?'; ru='Отменить заказ арендатора?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure DeactivateConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DeactivateConfirmation" ) export

	text = NStr ( "en='Access will be locked after deactivation.
				|All work within the application will be completed.
				|Please confirm that the action has been performed'; ro='După dezactivare, accesul la sistem va fi închis.
				|Lucrul cu programul va fi finalizat.
				|Confirmați acțiunea care trebuie efectuată.'; ru='После деактивации, доступ в систему будет закрыт.
				|Работа с программой будет завершена.
				|Подтвердите пожалуйста выполняемое действие.'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.OKCancel, 0, DialogReturnCode.Cancel, title );

EndProcedure

&AtClient
Procedure GeneratePromoCodesConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "GeneratePromoCodesConfirmation" ) export

	text = NStr ( "en='Would you like to generate promo codes?'; ro='Doriți să generați coduri promoționale?'; ru='Сгенерировать промо-коды?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure GoToNextPeriodConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "GoToNextPeriodConfirmation" ) export

	text = NStr ( "en='The information has been changed.
				|Would you like to save the document and switch to another time period?'; ro='Datele au fost modificate.
				|Salvați documentul și treceți la o altă perioadă?'; ru='Данные были изменены.
				|Сохранить документ и перейти в другой период?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Cancel, title );

EndProcedure

&AtClient
Procedure SendForApprovalAgainConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SendForApprovalAgainConfirmation" ) export

	text = NStr ( "en='Would you like to save changes and send the document for approval again?'; ro='Doriți să salvați modificările și să trimiteți documentul spre aprobare din nou?'; ru='Сохранить изменения и отправить документ повторно на одобрение?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure SendForApprovalConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SendForApprovalConfirmation" ) export

	text = NStr ( "en='Would you like to save the data and send the document for approval?
				|This will render any further modifications to the document impossible '; ro='Doriți să salvați datele și să trimiteți documentul spre aprobare?
				|(Ulterior, nu se va permite modificarea acestui document)'; ru='Сохранить данные и отправить документ на одобрение?
				|(после этого, изменение документа будет недоступно)'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure StartPaymentProcessConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "StartPaymentProcessConfirmation" ) export

	text = NStr ( "en='Unfortunately, access to the system was denied because your payment is overdue.
				|Number of registered users: %UsersCount
				|Number of paid users: %PaidUsersCount
				|
				|We ask that you please pay the amount owed for our services.
				|If you choose not to pay immediately, access to the system will be denied.
				|
				|If you have any questions, please feel free to contact us at %Info
				|
				|Would you like to submit payment for the service at this time? '; ro='Din păcate, accesul la sistem a fost respins deoarece plata este întârziată.
				|Număr de utilizatori înregistrați: %UsersCount
				|Număr de utilizatori ce au plătit: %PaidUsersCount
				|
				|Soluție: puteți plăti pentru serviciul acum.
				|În caz de anulare, accesul la sistem nu va fi disponibil.
				|
				|Dacă aveți întrebări, contactați-ne la: %Info
				|
				|Doriți să plătiți serviciul acum?'; ru='К сожалению, доступ в систему запрещен.
				|Причина: просрочена оплата за сервис.
				|Зарегистрированное количество пользователей: %UsersCount
				|Оплаченное количество пользователей: %PaidUsersCount
				|
				|Решение: вы можете прямо сейчас оплатить услуги за сервис.
				|В случае отказа, доступ в систему будет недоступен.
				|
				|Если у вас есть вопросы, обращайтесь по адресу: %Info
				|
				|Оплатить услуги прямо сейчас?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function ApplicationItemName ( Params ) export

	text = NStr ( "en='Access to Contabilizare, Users: %UsersCount, Months: %MonthsCount'; ro='Acces la Contabilizare, Utilizatori: %UsersCount, Luni: %MonthsCount'; ru='Доступ к Contabilizare, пользователи: %UsersCount, месяцы: %MonthsCount'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function InvoiceShortName () export

	text = NStr ( "en='Invoice'; ro='Factură'; ru='Инвойс'" );
	return text;

EndFunction

&AtClient
Function ItemsTable () export

	text = NStr ( "en='Items'; ro='Marfă'; ru='Товары'" );
	return text;

EndFunction

&AtServer
Function PaymentDateUndefined () export

	text = NStr ( "en='undefined'; ro='nu este definit'; ru='не определена'" );
	return text;

EndFunction

&AtClient
Function QuantityAllocationInformation ( Params ) export

	text = NStr ( "en='Selected: %QuantitySelected, allocated: %QuantityAllocated'; ro='Selectat: %QuantitySelected, plasat: %QuantityAllocated'; ru='Выбрано: %QuantitySelected, размещено: %QuantityAllocated'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Function QuantityReserveAllocationInformation ( Params ) export

	text = NStr ( "en='Selected: %Selected, Reserved: %Reserved, Allocated: %Allocated'; ro='Selectat: %Selected, rezervat: %Reserved, plasat: %Allocated'; ru='Выбрано: %Selected, зарезервировано: %Reserved, размещено: %Allocated'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function QuoteDueDateLessCurrentDate ( Params ) export

	text = NStr ( "en='The period of validity of the commercial offer has passed as of %DueDate.
				|You cannot enter orders based on outstanding commercial offers'; ro='Perioada de valabilitate a ofertei a fost (data de încheiere: %DueDate).
				|Este imposibil de a introduce comenzi pe baza propunerilor comerciale expirate'; ru='Период действия коммерческого предложения вышел (дата конца действия: %DueDate).
				|Нельзя вводить заказы на основании просроченных коммерческих предложений'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function QuoteRejected ( Params ) export

	text = NStr ( "en='Commercial offer was already rejected for the reason: %Cause
				|It is impossible to enter an order based on a rejected commercial offer'; ro='Oferta comerciala a fost deja refuzată din cauza: %Cause
				|Intrarea ordinului pe baza ofertei comerciale respinse este imposibilă '; ru='Коммерческое предложение уже было отклонено по причине: %Cause
				|Ввод заказа на основании отклоненного коммерческого предложения невозможен'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function SalesOrderShortInfo ( Params ) export

	text = NStr ( "en='SO #%Number from %Date'; ro='СС №%Number din %Date'; ru='ЗП №%Number от %Date'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function SalesOrderShortName () export

	text = NStr ( "en='SO'; ro='СС'; ru='ЗП'" );
	return text;

EndFunction

&AtClient
Function ServicesTable () export

	text = NStr ( "en='Services'; ro='Servicii'; ru='Услуги'" );
	return text;

EndFunction

Function TotalWithoutVATString ( Params ) export

	text = NStr ( "en='Total: %Amount'; ro='Total: %Amount'; ru='Всего: %Amount'" );
	return Output.FormatStr ( text, Params );

EndFunction

Function TotalWithVATString1 ( Params ) export

	text = NStr ( "en='Total: %Amount, plus VAT: %AmountVAT'; ro='Total: %Amount, inclusiv TVA: %AmountVAT'; ru='Всего: %Amount, включая НДС: %AmountVAT'" );
	return Output.FormatStr ( text, Params );

EndFunction

Function TotalWithVATString2 ( Params ) export

	text = NStr ( "en='Total: %Amount, including VAT: %AmountVAT'; ro='Total: %Amount, inclusiv. TVA: %AmountVAT'; ru='Всего: %Amount, в т.ч. НДС: %AmountVAT'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure DeleteMessagesConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DeleteMessagesConfirmation" ) export

	text = NStr ( "en='Would you like to remove the selected messages?'; ro='Doriți să ștergeți mesajele selectate?'; ru='Удалить выбранные сообщения?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure MoveToDocumentConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "MoveToDocumentConfirmation" ) export

	text = NStr ( "en='Move selected items in the document?'; ro='Transferați elementele selectate într-un document?'; ru='Перенести выбранные товары в документ?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure AmountDiscountGreatAmount ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "AmountDiscountGreatAmount" ) export

	text = NStr ( "en='Discount amount (%Discount)  cannot exceed total payment amount (%AmountPayment)'; ro='Suma de reducere (%Discount) nu poate depăși suma totală de plată (%AmountPayment)'; ru='Сумма скидки (%Discount) не может превышать общую сумму платежа (%AmountPayment)'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure QuantityAllocatedGreatOrderQuantity ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "QuantityAllocatedGreatOrderQuantity" ) export

	text = NStr ( "en='Allocated quantity cannot exceed available stock'; ro='Cantitatea care trebuie plasată nu poate depăși restul disponibil al comenzii'; ru='Размещаемое количество не может превышать доступный остаток заказа'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure QuantityLessReservation ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "QuantityLessReservation" ) export

	text = NStr ( "en='Allocated quantity cannot exceed ordered quantity!
				|Increase ordered quantity or decrease allocated quantity'; ro='Cantitatea alocată nu poate depăși cantitatea comandată!
				|Măriți cantitatea comandată sau reduceți cantitatea alocată'; ru='Размещенное количество не должно превышать заказываемое количество!
				|Увеличьте количество заказа или уменьшите размещение'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure QuantityLessReservationAndAllocation ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "QuantityLessReservationAndAllocation" ) export

	text = NStr ( "en='Reserved and/or allocated quantity cannot exceed the ordered quantity!
				|Please increase the order quantity or decrease the reserved and/or allocated quantities '; ro='Cantitatea rezervată și alocată nu poate depăși cantitatea comandată!
				|Măriți cantitatea comandată sau micșorați cantitatea rezervată / alocată'; ru='Зарезервированное и размещенное количество не должно превышать заказываемое количество!
				|Увеличьте количество заказа или уменьшите резерв/размещение'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure QuantityReservedGreatWarehouseQuantity ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "QuantityReservedGreatWarehouseQuantity" ) export

	text = NStr ( "en='The reserved quantity cannot exceed available warehouse stock '; ro='Cantitatea rezervată nu poate depăși soldul disponibil în depozit'; ru='Резервируемое количество не может превышать доступный остаток на складе'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure QuantitySelectedGreatWarehouseQuantity ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "QuantitySelectedGreatWarehouseQuantity" ) export

	text = NStr ( "en='Selected quantity cannot exceed available stock in warehouse'; ro='Cantitatea selectată nu poate depăși soldul stocului disponibil'; ru='Выбранное количество не может превышать доступный остаток на складе'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure QuantitySelectedGreatReservedQuantity ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "QuantitySelectedGreatWarehouseQuantity" ) export

	text = NStr ( "en='Selected quantity cannot exceed reserved quantity'; ro='Cantitatea selectată nu poate depăși cantitatea rezervată'; ru='Выбранное количество не может превышать зарезервированное количество'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure ItemWasAddedToSelectedItems ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export

	text = NStr ( "en='%Item added to the basket'; ro='%Item este adăugat în coș'; ru='%Item добавлен в корзину'" );
	explanation = NStr ( "en=''; ro=''; ru=''" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );

EndProcedure

&AtServer
Procedure CannotDistributeAdditionalExpenses ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Unable to determine the items'' composition from the document % Document. 
				|It is possible that the document was not recorded or contains no items.
				| It may also be the case that the type of contract or transaction does not provide for the inclusion of additional costs'; ro='Nu este posibilă determinarea compoziției de mărfuri în document %Document pentru distribuția serviciilor. Probabil, documentul specificat nu este valid sau nu conține mărfurile sau tipul contractului sau operațiunea nu prevede includerea cheltuielilor suplimentare în prețul de cost'; ru='Не удалось определить товарный состав документа %Document для распределения услуг. Возможно, указанный документ не проведен, или не содержит товаров, или вид договора или операции не предусматривает включение дополнительных затрат в себестоимость'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ExistPriceRecursion ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The specified type of price leads to looped pricing '; ro='Aceste prețuri de bază conduc la un calcul infinit'; ru='Указанные базовые цены приводят к зацикливанию расчета'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure InventoryNoAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This inventory number is already in use by the fixed asset with code %Code'; ro='Un astfel de număr de inventar este deja utilizat de mijlocul fix existent sub codul %Code'; ru='Такой инвентарный номер уже используется существующим основным средством под кодом %Code'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure AllocationBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The quantity  (%Quantity ) of item %Item in the order placement balance is insufficient. The balance of %DocumentOrder is  %QuantityBalance'; ro='Nu este suficient %Quantity de marfă %Item în balanța plasării comenzii. Soldul %DocumentOrder este %QuantityBalance'; ru='Не хватает %Quantity товара %Item  в остатке размещения заказа. В остатке %DocumentOrder числится %QuantityBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ItemsCostBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The quantity (%Quantity) of item %Item is insufficient. The amount of stock listed for warehouse %Warehouse is %QuantityBalance'; ro='Nu este suficient %Quantity de marfă %Item. În balanța lotului contabil pentru depozitul %Warehouse este %QuantityBalance'; ru='Не хватает %Quantity товара %Item. В остатках партионного учета по складу %Warehouse числится %QuantityBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PriceCalculationMethodChangeError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The calculation method cannot be changed.
				|This type of price already exists in recorded documents'; ro='Metoda de calcul nu poate fi modificată, în funcție de acest tip de preț există deja documente valide de stabilire a prețurilor'; ru='Метод расчета нельзя изменить, по данному типу цены уже существуют проведенные документы установки цен'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PriceDetailChangeError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Details of price formation cannot be changed, the price for this type already exists in documents'; ro='Detaliile de formare a prețurilor nu pot fi modificate, deoarece acest tip de preț deja este folosit în documente care stabilesc prețurile'; ru='Детализацию образования цены нельзя изменить, по данному типу цены уже существуют проведенные документы установки цен'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PriceListWarehouseError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='To obtain data regarding stock, you must select a warehouse'; ro='Pentru a obține date despre solduri, selectați depozitul'; ru='Для получения данных по остаткам необходимо выбрать Cклад'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PricesPeriodError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The price cannot expire before it becomes valid '; ro='Data expirării prețurilor nu poate fi mai devreme de data începerii acțiunii'; ru='Дата окончания срока действия цен не может быть раньше даты начала их действия'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PricesNotRecognized ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='One or more of the prices in table %Table are not marked for use in the price tables. Please bookmark the prices in use, or delete the unused prices from this document'; ro='În tabelul %Table există prețuri care nu sunt marcate pentru a fi utilizate în tabelele cu prețuri. Bifați prețurile utilizate (fila Prețuri) sau ștergeți din acest table prețurile neutilizate din acest document'; ru='В табличной части %Table существуют цены, не отмеченные для использования в таблицах цен. Установите флажки используемых типов цен (закладка Цены), или удалите из данной табличной части цены, не задействованные в документе'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure QuoteDateError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The expiration date of the quota cannot be set to before the date of the document'; ro='Data de expirare a acțiunii cotei nu poate fi mai devreme de data documentului'; ru='Дата окончания срока действия квоты не может быть раньше даты документа'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RejectionCauseAlreadyExist ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Refusal of the commercial offer has already been recorded'; ro='Refuzul la această ofertă comercială a fost deja stabilit'; ru='Отказ по данному коммерческому предложению уже был установлен'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UndefinedAccountPolicy ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The accounting policy parameter ""%Parameter"" has not been specified for the company  ""%Company"" on  %Date. The parameters of the accounting policy are set in the catalog ""Companies."" '; ro='Pentru întreprinderea ""%Company"" la data %Date nu este specificat parametrul politicii contabile ""%Parameter"". Parametrii politicii contabile sunt stabiliți în catalogul ""Întreprinderi""'; ru='Для компании ""%Company"" на дату %Date не указаны параметры учетной политики. Параметры учетной политики устанавливаются в справочнике ""Компании""'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UndefinedAccountPolicyParameter ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The accounting policy parameter ""%Parameter"" has not been specified for the company  ""%Company"" on  %Date. The parameters of the accounting policy are set in the catalog ""Companies."" '; ro='Pentru întreprinderea ""%Company"" la data %Date nu este specificat parametrul politicii contabile ""%Parameter"". Parametrii politicii contabile sunt stabiliți în catalogul ""Întreprinderi""'; ru='Для компании ""%Company"" на дату %Date не указаны параметры учетной политики. Параметры учетной политики устанавливаются в справочнике ""Компании""'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnpostLinkedDocuments ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Distributed costs have been recorded in the document. In order to change this document, you must cancel the linked document: %Dependency'; ro='Registrele acestui document conțin costuri distribuite. Pentru a modifica acest document, trebuie mai întâi să anulați documentul asociat: %Dependency'; ru='Записи регистров данного документа содержат распределенные затраты. Для изменения данного документа, необходимо предварительно отменить проведение связанного с ним документа: %Dependency'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure VendorServicesBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The quantity  (%Quantity ) of service %Item  is insufficient. %QuantityBalance are listed for issue. '; ro='Nu este suficient %Quantity serviciu %Item. Pentru eliberare este afișat %QuantityBalance'; ru='Не хватает %Quantity услуг %Item. К оформлению числится %QuantityBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure RestartInterface ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "RestartInterface" ) export

	text = NStr ( "en='Some System Features which influence the User Interface have been changed.
				|After closing this window, the System will refresh User Interface'; ro='Ați schimbat caracteristicile sistemului care influențează interfața utilizatorilor.
				|După închiderea acestei ferestre, sistemul va actualiza interfața utilizatorului'; ru='Вы изменили настройки, влияющие на построение интерфейса системы.
				|После закрытия этого окна, интерфейс будет обновлен'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function Discount ( Params ) export

	text = NStr ( "en='discount: %Discount'; ro='reducere: %Discount'; ru='скидка: %Discount'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Procedure OrderCannotBeChanged ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This order cannot be changed. The approval process has already begun'; ro='Această comandă nu poate fi modificată. Procesul de aprobare a început deja'; ru='Заказ нельзя изменить, по нему был запущен процесс одобрения'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure SalesOrderClosingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Some items have not been shipped. This order cannot be completed'; ro='Nu toate bunurile sunt primite prin comanda dată. Comanda nu poate fi închisă'; ru='Еще не все товары получены по данному заказу. Заказ закрыть нельзя'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure SelectCustomer ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "SelectCustomer" ) export

	text = NStr ( "en='Please select a customer'; ro='Selectați un cumpărător'; ru='Выберите покупателя'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure SelectVendor ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "SelectVendor" ) export

	text = NStr ( "en='Please select a vendor '; ro='Selectați furnizorul'; ru='Выберите поставщика'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure StartShippingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SendForApprovalConfirmation" ) export

	text = NStr ( "en='Would you like to start the picking process?'; ro='Doriți să începeți procesul de complectare?'; ru='Начать процесс комплектации?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure CompleteShipmentConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SendForApprovalConfirmation" ) export

	text = NStr ( "en='Would you like to complete the picking process?'; ro='Doriți să finalizați procesul de completare?'; ru='Завершить процесс комплектации?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure ShipmentCannotBeChanged ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The document cannot be changed because the shipment process has been completed'; ro='Documentul nu poate fi schimbat deoarece procesul de expediere a fost terminat'; ru='Документ нельзя изменить, процесс отгрузки был завершен'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure QuantityBackIncorrect ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The entered quantity exceeds the ordered quantity'; ro='Cantitatea este mai mare decât cantitatea comandată'; ru='Количество больше количества в заказе'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PeriodicityError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='To generate the report, you must select the desired frequency'; ro='Pentru a genera un raport, trebuie să selectați un interval.'; ru='Для формирования отчета Вам необходимо выбрать периодичность.'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure EnrollMobile ( Module, CallbackParams = undefined, Params = undefined, ProcName = "EnrollMobile" ) export

	text = NStr ( "en='All data will be marked for migration to the mobile application server!
				|Are you sure you want to continue?'; ro='Toate datele vor fi marcate pentru migrare
				|la serverul de aplicații mobile!
				|Doriți să continuați?'; ru='Все данные базы данных будут помечены
				|для миграции на сервер мобильных приложений!
				|Продолжить?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure EnrollmentCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "EnrollmentCompleted" ) export

	text = NStr ( "en='Enrollment is completed!'; ro='Înregistrarea este finalizată!'; ru='Регистрация завершена!'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure EnrollmentError ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "EnrollmentError" ) export

	text = NStr ( "en='The main node cannot be used'; ro='Nodul central nu poate fi utilizat'; ru='Центральный узел не может быть использован'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Procedure DefaultCompanyError1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The company is not defined in the list of allowed companies'; ro='Întreprinderea nu este specificată în lista întreprinderilor disponibile pentru acest utilizator'; ru='Компания не задана в списке доступных этому пользователю компаний'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DefaultCompanyError2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The company is defined in the list of restricted companies'; ro='Întreprinderea este definită în lista întreprinderilor restricționate'; ru='Компания задана в списке недоступных этому пользователю компаний'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DefaultWarehouseError1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The warehouse is not defined in the list of allowed warehouses'; ro='Depozitul nu este specificat în lista depozitelor disponibile pentru acest utilizator'; ru='Склад не задан в списке доступных этому пользователю складов'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DefaultWarehouseError2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The warehouse is defined in the list of restricted warehouses'; ro='Acest depozit este specificat în lista depozitelor care nu sunt disponibile pentru acest utilizator'; ru='Этот склад задан в списке недоступных этому пользователю складов'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure OperationNotPerformed ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "OperationNotPerformed" ) export

	title = NStr ( "en=''; ro=''; ru=''" );
	text = Output.OperationError ();
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

Function OperationError () export

	text = NStr ( "en='The operation was not successfully performed'; ro='Operația nu a fost efectuată'; ru='Операция не выполнена'" );
	return text;

EndFunction

&AtClient
Procedure UserIsUndefined ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UserIsUndefined" ) export

	text = NStr ( "en='The current user is not defined.
				|Please complete the setup of the mobile application. 
				|Otherwise, the application will be closed'; ro='Utilizatorul curent nu este definit.
				|Vă rugăm să configurați aplicația mobilă în mod corespunzător.
				|În caz contrar, aplicația va fi închisă'; ru='Не удалось определить текущего пользователя.
				|Для продолжения работы необходимо повторно
				|произвести настройку подключения мобильного приложения
				|к центральной базе данных.
				|В случае отмены, работа приложения будет завершена'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.OKCancel, 0, DialogReturnCode.OK, title );

EndProcedure

&AtServer
Procedure ExchangeReceivedFromNode ( Params ) export

	s = NStr ( "en='Data exchange from node ""%Node"" accepted'; ro='Schimbul de date de la nodul ""%Node"" este acceptat'; ru='Данные обмена от узла ""%Node"" приняты!'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure ErrorReceivingData ( Params ) export

	s = NStr ( "en='Error retrieving data exchange! %Error. Exchange file %FileXml.'; ro='A apărut o eroare în timpul preluării datelor de schimb! %Error. Fisierul de schimb %FileXml.'; ru='Ошибка при получении данных обмена! %Error. Файл обмена %FileXml.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure ExchangeWithNode ( Params ) export

	s = NStr ( "en='Retrieving data from the node ""%Node"" ...'; ro='Obținerea datelor din nodul ""%Node"" ...'; ru='Получение данных от узла ""%Node"" ...'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure ExchangeWithNodeOver ( Params ) export

	s = NStr ( "en='... receiving data from node ""%Node"" completed.'; ro='... primirea datelor din nodul ""%Node"" este finalizată.'; ru='... получение данных от узла ""%Node"" завершено.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure LogonToServerMail () export

	s = NStr ( "en='Connection to mail server ...'; ro='Conectarea la serverul de e-mail ...'; ru='Соединение с почтовым сервером ...'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure LogonSuccess () export

	s = NStr ( "en='... connected to the server.'; ro='... conexiunea la server este stabilită.'; ru='... соединение с сервером установлено.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure ErrorConnectEmailProfile ( Params ) export

	s = NStr ( "en='Error connecting to mail profile! The exchange was not carried out! Error description: %Error'; ro='A apărut o eroare la conectarea la profilul de poștă electronică! Schimbul nu este finalizat! Descrierea erorii: %Error'; ru='Ошибка при подключении к почтовому профилю! Обмен не выполнен! Описание ошибки: %Error'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure MailReceived () export

	s = NStr ( "en='Message received ...'; ro='Mesajul primit ...'; ru='Сообщение получено ...'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure NoNewExchangeFiles () export

	s = NStr ( "en='There are no new messages!'; ro='Nu există mesaje noi!'; ru='Отсутствуют новые сообщения !'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure FTPConnectionError () export

	s = NStr ( "en='An error occurred while connecting to the FTP server!'; ro='Au existat erori în timpul conectării la serverul FTP!'; ru='Возникли ошибки при соединении с FTP сервером!'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure SendingMail () export

	s = NStr ( "en='Sending message ...'; ro='Trimiterea mesajului ...'; ru='Отправка сообщения ...'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure MessageSent ( Params ) export

	s = NStr ( "en='Message exchange for the unit ""%Node"" has been sent successfully.'; ro='Mesajul de schimb pentru nodul ""%Node"" a fost trimis cu succes.'; ru='Сообщение обмена для узла ""%Node"" успешно отправлено.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure ReadingChanges () export

	s = NStr ( "en='... read the data from the file.'; ro='... citirea datele din fișier.'; ru='... чтение данных из файла.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure ReadingChangesComplete ( Params ) export

	s = NStr ( "en='... the data from the node ""%Node"" successfully read from a file.'; ro='... datele din nodul ""%Node"" au fost citite cu succes din fișier.'; ru='... данные от узла ""%Node"" успешно прочитаны из файла.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure WritingChanges () export

	s = NStr ( "en='... write data to a file.'; ro='... înregistrarea datelor în fișier.'; ru='... запись данных в файл.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure WritingChangesComplete () export

	s = NStr ( "en='... the data was successfully written to the file.'; ro='... datele au fost înregistrate cu succes în fișier.'; ru='... данные успешно записаны в файл.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure FileDeletionError ( Params ) export

	s = NStr ( "en='Error deleting the file (%File)! %Error'; ro='Eroare la ștergerea fișierului (%File)! %Error'; ru='Ошибка при удалении файла (%File)! %Error'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure JobStarted ( Params ) export

	s = NStr ( "en='Background job starts in %DateTime.'; ro='Lucrarea de fundal începe în %DateTime.'; ru='Фоновое задание стартовало в %DateTime.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure JobEnded ( Params ) export

	s = NStr ( "en='Background job was completed in %DateTime.'; ro='Lucrarea de fundal a fost finalizată în %DateTime.'; ru='Фоновое задание завершилось в %DateTime.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtClient
Function ExchangeNode ( Params ) export

	s = NStr ( "en='Node %OperationType.'; ro='Nodul de schimb %OperationType.'; ru='Узел обмена %OperationType.'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtClient
Procedure ThisNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The selected node data exchange corresponds to this knowledge base. 
				|You must select a node for data exchange.'; ro='A fost selectat un nod de schimb de date corespunzător acestei baze de date de informații. Trebuie să selectați un nod pentru schimbul de date.'; ru='Выбран узел обмена данными, соответствующей данной информационной базе. Необходимо выбрать узел для обмена данными.'" );
	Output.PutMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure ChangePrefixFileName ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The file name associated with the data exchange prefix was changed! This operation must be performed with caution! For correct operation of the data exchange, such changes must be made within the appropriate nodes for a distributed information database.'; ro='Prefixul numelui fișierului a fost modificat! Această operațiune trebuie efectuată cu atenție! Pentru funcționarea corectă a schimbului de date, este necesar să se efectueze modificări similare în nodurile corespunzătoare ale bazei de date de informații distribuite.'; ru='Был изменён префикс имени файла обмена данными! Данную операцию необходимо выполнять осмотрительно! Для дальнейшей корректной работы обмена данными, необходимо произвести подобные изменения в соответствующих узлах распределённой информационной базы.'" );
	Output.PutMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReadChangesConfiguration () export

	s = NStr ( "en='Changes -including modifications to the configuration- were read. The configuration will now be updated.'; ro='Modificările care conțin modificări de configurare au fost citite. Configurația va fi actualizată.'; ru='Были прочитаны изменения, которые содержат изменения в конфигурации. Конфигурация будет обновлена.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure ExchangeLoadingAgain ( Params ) export

	s = NStr ( "en='This will be produced by re-reading the data exchange from node %Node (ID = %ID).'; ro='Datele de schimb vor fi citite din nou de la nodul %Node (ID = %ID).'; ru='Будет произведено повторное чтение данных обмена из узла %Node (ID = %ID).'" );
	putExchangeMessage ( s, Params, , false, false );

EndProcedure

&AtServer
Function InformationAboutFileRules ( Params ) export

	s = NStr ( "en='File = %File, size - %Size bytes, loaded - %SaveTime.'; ro='Fișier - %File, dimensiune - %Size Bytes , încărcat - %SaveTime.'; ru='Файл - %File, размер - %Size байт, загружен - %SaveTime.'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Procedure ErrorLogonInternetMail ( Params ) export

	s = NStr ( "en='Error connecting to Internet mail. Error description - %ErrorDescription.'; ro='A apărut o eroare la conectarea la poșta Internet. Descrierea erorii este %ErrorDescription.'; ru='Ошибка при подключении к интернет-почте. Описание ошибки - %ErrorDescription.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure EMailLogonOK () export

	s = NStr ( "en='Connection to the e-mail was successful!'; ro='Conectarea la e-mail a avut succes!'; ru='Подключение к почте прошло успешно!'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Function SubjectErrorReport ( Params ) export

	s = NStr ( "en='Error when downloading data from node-to-peer ""%Node"". Date of download - %CurrentDate.'; ro='Erori la încărcarea datelor din schimbul de noduri ""%Node"". Data încărcării datelor este %CurrentDate.'; ru='Ошибки при загрузке данных от узла-обмена ""%Node"". Дата загрузки данных - %CurrentDate.'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function TextMessageEmailErrorReport ( Params ) export

	s = NStr ( "en='Exchange data with the node ""%Node"".
				|The maximum number of errors when loading data from a file exchange has been exceeded.
				|Number of errors allowed - %MaximumErrors.
				|Date of last boot failure - %CurrentDate.
				|Description of the error - %Error.
				|The cause of the error must be removed in order for successful data exchange to continue. Tenant Code - %Tenant.'; ro='Schimbul de datele cu nodul ""%Node"".
				|A depășit numărul maxim de erori la încărcarea datelor dintr-un fișier de schimb.
				|Numărul de erori permise - %MaximumErrors.
				|Data ultimului eșec de încărcare - %CurrentDate.
				|Descrierea erorii - %Error.
				|Este necesar să eliminați cauza erorii pentru un schimb de date cu succes. Cod de chiriaș - %Tenant.'; ru='Обмен данными с узлом ""%Node"".
				|Превышено максимальное количество ошибок при загрузке данных из файла-обмена.
				|Количество допустимых ошибок - %MaximumErrors.
				|Дата последней неудачной загрузки - %CurrentDate.
				|Описание ошибки - %Error.
				|Необходимо устранить причину ошибку для дальнейшего успешного обмена данными. Код арендатора - %Tenant.'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function TextMessageEmailErrorReportXML ( Params ) export

	s = NStr ( "en='Exchange data with the node ""%Node"".
				|The maximum number of errors when loading data from file-sharing has been exceeded.
				|Number of errors allowed - %MaximumErrors.
				|Date of last boot failure - %CurrentDate.
				|Description of the error - %Error.
				|The cause of the error must be removed in order for successful data exchange to continue. Tenant Code - %Tenant.'; ro='Schimb de date cu nodul ""%Nod"" "".
				|Depășirea numărului maxim de erori la încărcarea datelor din schimbul de fișiere.
				|Numărul de erori admise este %MaximumErrors.        
				|Data ultimei descărcări eșuate a fost %CurrentDate.
				|Descărcarea a fost efectuată utilizând procesarea universală a schimbului XML.
				|Un protocol de fișiere de schimb de date este atașat la mesaj.
				|Este necesară eliminarea cauzei erorii pentru continuarea schimbului de date reușit.
				|Codul chiriașului - %Tenant.'; ru='Обмен данными с узлом ""%Node"".
				|Превышено максимальное количество ошибок при загрузке данных из файла-обмена.
				|Количество допустимых ошибок - %MaximumErrors.
				|Дата последней неудачной загрузки - %CurrentDate.
				|Загрузка производилась при помощи универсальной обработки XML-обмена.
				|К сообщению прикреплен файл-протокол обмена данными. 
				|Необходимо устранить причину ошибку для дальнейшего успешного обмена данными. Код арендатора - %Tenant.'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function TextMessageEmailErrorReportNoNewExchangeFiles ( Params ) export

	s = NStr ( "en='Exchange data with the node ""%Node"".
				|The maximum number of errors when loading data from file-sharing has been exceeded.
				|Number of errors allowed - %MaximumErrors.
				|Date of last boot failure - %CurrentDate.
				|Cause of the problem - the lack of file-sharing.
				|The cause of the error must be removed in order for successful data exchange to continue. Tenant Code - %Tenant.'; ro='Schimb de date cu nodul ""%Nod"".
				|Depășirea numărului maxim de erori la încărcarea datelor din schimbul de fișiere.
				|Numărul de erori admise este %MaximumErrors.
				|Data ultimei descărcări eșuate a fost %CurrentDate.
				|Cauza problemei - lipsa datelor de schimb.
				|Este necesară eliminarea cauzei erorii pentru continuarea schimbului de date reușit.
				|Codul chiriașului - %Tenant.'; ru='Обмен данными с узлом ""%Node"".
				|Превышено максимальное количество ошибок при загрузке данных из файла-обмена.
				|Количество допустимых ошибок - %MaximumErrors.
				|Дата последней неудачной загрузки - %CurrentDate.
				|Причина проблемы - отсутствие файлов-обмена.
				|Необходимо устранить причину ошибку для дальнейшего успешного обмена данными. Код арендатора - %Tenant.'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Procedure ItWasFoundFileExchange ( Params ) export

	s = NStr ( "en='An unread exchange file (- %File) was discovered in node %Node. Node %Node will not be unloaded.'; ro='Un fișier de schimb necitit a fost găsit pentru nodul %Nod (numele fișierului este %File). Pentru nodul %Node nu va fi efectuată descărcarea.'; ru='Для узла %Node был обнаружен непрочитанный файл обмена (имя файла - %File). Для узла %Node не будет произведена выгрузка.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure WillBeRunRereadFileExchange () export

	s = NStr ( "en='Exchange file will read again after the update configuration.'; ro='Fișierul de schimb va fi citit din nou după actualizarea configurației.'; ru='Файл обмена будет прочитан повторно, после обновления конфигурации.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure StartUpdateScriptProcedure () export

	s = NStr ( "en='Start the formation procedure and the update configuration file (script).'; ro='Porniți procedura pentru generarea și lansarea actualizării de configurare (fișier script).'; ru='Старт процедуры по формированию и запуску обновления конфигурации (файл-скрипт).'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure SaveUpdateConfigurationScript ( Params ) export

	s = NStr ( "en='Save the file script. File - %File.'; ro='Salvați script-ul de fișiere. Fișierul este %File.'; ru='Сохранили файл-скрипт. Файл - %File.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure SaveRereadExchange ( Params ) export

	s = NStr ( "en='Save the file dataprocessor, reread exchange data. File - %File.'; ro='Fișierul pentru procesarea fișierului de schimb a fost salvat. Fișierul este %File.'; ru='Сохранили файл обработки дочитывания файла обмена. Файл - %File.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure RunUpdateConfigurationScript () export

	s = NStr ( "en='Run the script configuration updates.'; ro='Lansarea scriptului de actualizare a configurației.'; ru='Запуск скрипта обновления конфигурации.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure StartReReadData () export

	s = NStr ( "en='Launched processing reread exchange file - RereadData.epf.'; ro='A început procesul de citire a fișierului de schimb - RereadData.epf.'; ru='Стартовала обработка дочитывания файла обмена - RereadData.epf.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure LoadFromEmail () export

	s = NStr ( "en='... started loading the data from the e-mail address'; ro='... a început importul de date de pe e-mail'; ru='... стартовала загрузка данных из электронной почты'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure LoadFromFTP () export

	s = NStr ( "en='... started downloading data from ftp'; ro='... a început importul de date de pe ftp'; ru='... стартовала загрузка данных с ftp'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure LoadFromWS () export

	s = NStr ( "en='... started downloading data through web-service'; ro='... a început importul de date prin intermediul serviciului web'; ru='... стартовала загрузка данных через веб-сервис'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure UnLoadFromWS () export

	s = NStr ( "en='... started uploading data through web-service'; ro='... a început exportul datelor prin intermediul serviciului web'; ru='... стартовала выгрузка данных через веб-сервис'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure ConnectToWS () export

	s = NStr ( "en='... connecting to web-service'; ro='... conectarea la serviciul web'; ru='... подключение к веб-сервису'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure ReadWS () export

	s = NStr ( "en='... getting data through web-service'; ro='... preluarea datelor prin intermediul serviciului web'; ru='... получение данных через веб-сервис'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure WriteWS () export

	s = NStr ( "en='... writing data through web-service'; ro='... înregistrarea datelor prin intermediul serviciului web'; ru='... запись данных через веб-сервис'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure LoadFromNetworkDisk () export

	s = NStr ( "en='... started downloading data from a network drive'; ro='... a început importul de date de pe o unitate de rețea'; ru='... стартовала загрузка данных с сетевого диска'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure UnLoadToEmail () export

	s = NStr ( "en='... started unloading the data by e-mail'; ro='... a început exportul datelor prin e-mail'; ru='... стартовала выгрузка данных на электронную почту'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure UnLoadToFTP () export

	s = NStr ( "en='... started uploading data to the ftp'; ro='... a început exportul de date pe ftp'; ru='... стартовала выгрузка данных на ftp'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure UnloadToDisk () export

	s = NStr ( "en='... started uploading data to a network drive'; ro='... a început exportul datelor pe o unitate de rețea'; ru='... стартовала выгрузка данных на сетевой диск'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure UnloadToWebService () export

	s = NStr ( "en='... started uploading data to throw web service'; ro='... a început exportul datelor către serviciul web'; ru='... стартовала выгрузка данных на через веб-сервис'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure StartReadRulesExchange () export

	s = NStr ( "en='Reading exchange file on the rules of exchange.'; ro='Citirea fișierelor de schimb în baza regulilor de schimb.'; ru='Чтение файла обмена по правилам обмена.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure CheckPreviousFileExchange () export

	s = NStr ( "en='Searching for an existing file exchange.'; ro='Căutați fișierul de schimb existent.'; ru='Поиск существующего файла обмена.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure FinishedRereadFileExchange () export

	s = NStr ( "en='The reread file exchange was completed after the updates to the configuration. '; ro='Finalizarea cititului fișierului de schimb după actualizarea configurației.'; ru='Завершение дочитывания файла обмена после обновления конфигурации.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Function StartBackgroundJob ( Params ) export

	s = NStr ( "en='Exchange data (%UserName, %Date, %ComputerName)'; ro='Schimb de date (%UserName, %Date, %ComputerName)'; ru='Обмен данными (%UserName, %Date, %ComputerName)'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtClient
Function ChooseFolderImage () export

	s = NStr ( "en='Choose directory image base:'; ro='Selectați directorul bază de imagini:'; ru='Выберите каталог базы образа:'" );
	return Output.FormatStr ( s, undefined );

EndFunction

&AtClient
Function OperationCompleted () export

	s = NStr ( "en='Operation completed'; ro='Operația este finalizată!'; ru='Операция завершена!'" );
	return Output.FormatStr ( s, undefined );

EndFunction

&AtClient
Procedure MasterNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Selected master node. Data exchange should be made of the slave nodes!'; ro='Nodul principal este selectat. Schimbul de date trebuie să fie efectuat de la nodurile subordonate!'; ru='Выбран главный узел. Обмен данными должен производиться из подчиненных узлов!'" );
	Output.PutMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Function CreateInitialImage () export

	s = NStr ( "en='Initial image creation in progress ...'; ro='Crearea imaginii inițiale ...'; ru='Создание начального образа ...'" );
	return  Output.FormatStr ( s, undefined );

EndFunction

&AtClient
Function InitialImageCompleted () export

	s = NStr ( "en='An initial image has been successfully created.'; ro='Crearea imaginii inițiale este finalizată.'; ru='Создание начального образа завершено.'" );
	return  Output.FormatStr ( s, undefined );

EndFunction

&AtClient
Function DataExchange () export

	s = NStr ( "en='Data exchange'; ro='Schimbul de date'; ru='Обмен данными'" );
	return  Output.FormatStr ( s, undefined );

EndFunction

&AtServer
Procedure ClassifiersNotSelected ( Params ) export

	s = NStr ( "en='Node of exchange plan ""Full"" - %Node is not selected in any node of exchange plan ""Classifiers.""'; ro='Nodul planului de schimb ""Complet"" - %Node nu este selectat în niciun nod al planului de schimb ""Clasificatori"".'; ru='Узел плана обмена ""Полный"" - %Node не выбран ни в одном узле плана обмена ""Классификаторы"".'" );
	putExchangeMessage ( s, Params);

EndProcedure

&AtServer
Procedure CloseCurrentSession () export

	s = NStr ( "en='The current session is complete (dataprocessor - RereadData.epf)'; ro='Finalizarea sesiunii curente (procesare - RereadData.epf) ...'; ru='Завершение текущего сеанса (обработка - RereadData.epf) ...'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure ReReadLoad () export

	s = NStr ( "en='Dataprocessor RereadData.epf: load data.'; ro='Procesarea RereadData.epf: încărcarea datelor.'; ru='Обработка RereadData.epf: загрузка данных.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure ReReadUnLoad () export

	s = NStr ( "en='Dataprocessor RereadData.epf: unload data.'; ro='Procesarea RereadData.epf: încărcarea datelor.'; ru='Обработка RereadData.epf: выгрузка данных.'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure LockBase () export

	s = NStr ( "en='Database is locked for configuration update'; ro='Baza de date este blocată pentru actualizarea configurației'; ru='Информационная база заблокирована для обновления конфигурации'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure UnlockBase ( Params ) export

	s = NStr ( "en='Unlocking the database Time - %Date.'; ro='Deblocarea bazei de date Ora -%Date.'; ru='Снята блокировка базы/ Время - %Date.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure ErrorReadClassifiers ( Params ) export

	s = NStr ( "en='Error reading classifiers. Error description - %Error'; ro='Eroare la citirea clasificatorilor. Descrierea erorii este %Error.'; ru='Ошибка при чтении классификаторов. Описание ошибки - %Error.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure ClassifiersNotFound () export

	s = NStr ( "en='File not found with change classifiers.'; ro='Nu s-a găsit niciun fișier cu modificările clasificatorului!'; ru='Не найден файл с изменениями классфикаторов!'" );
	putExchangeMessage ( s );

EndProcedure

&AtServer
Procedure ReceivedFromNode ( Params ) export

	s = NStr ( "en='Data exchange from node ""%Node"" accepted'; ro='Schimbul de date de la nodul ""%Node"" este acceptat'; ru='Данные обмена от узла ""%Node"" приняты!'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtServer
Procedure ExchangeDataItemAlreadyExist ( Params ) export

	s = NStr ( "en='Element node with the code: %Code already exists! To change or add data node, you must open an existing directory entry.'; ro='Elementul nod cu codul:% Code există deja! Pentru a schimba sau a adăuga un nod de date, trebuie să deschideți un element existent'; ru='Элемент с кодом узла: %Code уже существует! Для изменения или добавления данных узла необходимо открыть уже существующий элемент справочника.'" );
	putExchangeMessage ( s, Params, , false, false );

EndProcedure

&AtServer
Function ExchangeReadDataError ( Params ) export

	s = NStr ( "en='User %User does not have access to exchange data'; ro='Utilizatorul %User nu are dreptul de a face schimb de date.'; ru='У пользователя %User нет прав на обмен данными.'" );
	return FormatStr ( s, Params );

EndFunction

&AtServer
Function UnknownNode ( Params ) export

	s = NStr ( "en='Node not found. Code of node - %Code'; ro='Nu a fost găsit niciun nod. Codul nodului - %Code'; ru='Не найден узел. Код узла - %Code'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Procedure RemoveLockingBase ( Params ) export

	s = NStr ( "en='Unlocking the database Time - %Date.'; ro='Deblocarea bazei de date Ora -%Date.'; ru='Снята блокировка базы/ Время - %Date.'" );
	putExchangeMessage ( s, Params );

EndProcedure

&AtClient
Procedure BarcodeNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "BarcodeNotFound" ) export

	text = NStr ( "en='Barcode was not found'; ro='Codul de bare nu a fost găsit'; ru='Штрихкод не найден'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure ReplaceBarcode ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReplaceBarcode" ) export

	text = NStr ( "en='This barcode is already assigned to:
				|%Item
				|Would you like to assign the barcode to another item?'; ro='Acest cod de bare este deja folosit pentru:
				|%Item
				|Doriți să realocați acest cod de bare la elementul curent?'; ru='Этот штрихкод уже используется для:
				|%Item
				|Переназначить этот штрихкод текущему элементу?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtServer
Procedure InteractiveCreationRestricted ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This class of documents cannot be created interactively'; ro='Această clasă de documente nu poate fi creată interactiv'; ru='Этот класс документов не может создаваться интерактивно'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DefaultWarehouseError3 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The warehouse address is not defined in the list of allowed states/provinces'; ro='Adresa de depozit nu este specificată în lista de state / provincii disponibile pentru acest utilizator'; ru='Адрес склад не задан в списке доступных этому пользователю штатов/провинций'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DefaultWarehouseError4 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The user is not responsible for the warehouse. Open the warehouse and assign this user as a Salesman or Responsible person'; ro='Utilizatorul nu este responsabil pentru depozitul specificat. Deschideți depozitul și alocați acest utilizator ca agent de vânzări sau persoană responsabilă'; ru='Пользователь не является ответственным за указанный склад. Откройте склад и назначьте данного пользователя торговым агентом или ответственным'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function BarcodeAttachError () export

	text = NStr ( "en='Attaching barcode library returns an error'; ro='Eroare la conectarea componentei externe de imprimare codului de bare'; ru='Ошибка подключения внешней компоненты печати штрихкода'" );
	return text;

EndFunction

&AtClient
Procedure ItemNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ItemNotFound" ) export

	text = NStr ( "en='Item was not found'; ro='Marfa nu a fost găsit'; ru='Товар не найден'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure ShipmentNotSelected ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ShipmentNotSelected" ) export

	text = NStr ( "en='Please select at least one Shipment document'; ro='Selectați cel puțin un document de livrare, vă rog'; ru='Выберите пожалуйста как минимум один документ поставки'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure CreatePickupOrderConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CreatePickupOrderConfirmation" ) export

	text = NStr ( "en='Would you like to create an order fulfilment?'; ro='Doriți să creați o împlinire a comenzii?'; ru='Создать Подготовку к отгрузке?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure InvoicesNotReady ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "InvoicesNotReady" ) export

	text = NStr ( "en='No invoices for this document were found. '; ro='Nu a fost găsită nici o factură pentru acest document'; ru='По данному документу накладные не найдены'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function DataSetColumnNotFound ( Params ) export

	text = "Field not found, DataPath: %Path. Might be the field no longer exists in the source report or Mobile application (or mobile reports) is not up to date";
	return FormatStr ( text, Params );

EndFunction

&AtServer
Procedure EmailDescriptionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Please do not use these symbols ""%Chars"" in the address description'; ro='Vă rugăm să nu folosiți caracterele ""%Chars""  în descrierea adresei'; ru='Пожалуйста, не используйте символы ""%Chars"" в описании адреса'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function Open () export

	text = NStr ( "en='Open'; ro='Deschideți'; ru='Открыть'" );
	return text;

EndFunction

&AtClient
Procedure RemoveDetails ( Module, CallbackParams = undefined, Params = undefined, ProcName = "RemoveDetails" ) export

	text = NStr ( "en='All details in the table will be removed.
				|Are you sure you want to continue?'; ro='Toată analitica din tabel va fi ștearsă.
				|Doriți să continuați?'; ru='Вся аналитика в табличной части будет очищена.
				|Продолжить?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure JobScheduled ( Params, EventName ) export

	s = NStr ( "en='The job has been scheduled: %Description, Tenant: %Tenant, User: %User, Node: %Node'; ro='Sarcina programată: %Description, Chiriaș: %Tenant, Utilizator:%User, Nod: %Node'; ru='Запланировано задание: %Description, Tenant: %Tenant, User: %User, Node: %Node'" );
	putExchangeMessage ( s, Params, , , , EventName );

EndProcedure

&AtServer
Procedure BaseNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Distribution basis is not found. Linked documents might be not posted'; ro='Nu a fost găsită o bază pentru distribuire. Poate că documentele aferente nu sunt disponibile'; ru='База для распределения не найдена. Возможно, связанные документы не проведены'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure UpdateInventory ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UpdateInventory" ) export

	text = NStr ( "en='Would you like to fill the tabular section?
				|Note: Existing rows will be preserved'; ro='Doriți să completați secțiunea tabelară?
				|Notă: Rândurile existente vor fi păstrate'; ru='Обновить табличную часть?
				|Примечание: существующие строки будут сохранены'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtServer
Function DocumentNotFound () export

	text = NStr ( "en='Document not found'; ro='Documentul nu a fost găsit'; ru='Документ не найден'" );
	return text;

EndFunction

&AtServer
Function HelpPageHeader () export

	text = NStr ( "en='Click here to open help portal'; ro='Click aici pentru a merge la portalul de referință'; ru='Кликните здесь для перехода в справочный портал'" );
	return text;

EndFunction

&AtServer
Procedure AssetBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='%Item was not found in balance'; ro='%Item nu este găsit în sold'; ru='%Item на балансе не числится'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure AssetWrongLocation ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='%Item does not belong to %Department department'; ro='%Item nu aparține Departamentului %Department'; ru='%Item не найдено в подразделении %Department'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DoubleAssets ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Assets cannot be duplicated'; ro='Activele nu pot fi repetate'; ru='Активы не могут повторяться'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DoubleItems ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Items cannot be duplicated'; ro='Mărfurile nu pot fi repetate'; ru='ТМЦ не могут повторяться'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Function PushNotificationTitle ( Params ) export

	text = NStr ( "en='Message from: %User'; ro='Mesaj de la: %User'; ru='Сообщение от: %User'" );
	return FormatStr ( text, Params );

EndFunction

&AtClient
Procedure SelectSettingPlease ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "SelectSettingPlease" ) export

	text = NStr ( "en='Please select a setting '; ro='Vă rugăm să selectați setarea'; ru='Выберите пожалуйста настройку'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Procedure EmployeeDuplicated ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Employee record is duplicated'; ro='Au fost detectate rânduri duplicate ale angajaților'; ru='Обнаружены дубли строк сотрудника'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EmployeeAlreadyHired ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Employee is already hired'; ro='Angajatul a fost deja angajat'; ru='Сотрудник уже был принят на работу'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EmployeeAlreadyTerminated ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='%Employee is already terminated or does not work in our company'; ro='%Employee deja este concediat sau nu lucrează în compania noastră'; ru='%Employee уже уволен или не работает в нашей компании'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EmployeeNotHired ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='On the date of the changes you have attempted to make, %Employee is not employed by our company. Please check all compensations '; ro='La data modificărilor, %Employee a fost deja concediat sau nu a fost încă angajat de întreprinderea noastră (verificați și taxele suplimentare)'; ru='На дату изменений, %Employee уже уволен или еще не работает в нашей компании (проверьте также дополнительные начисления)'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EmployeeTransferError1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='%Employee has already received %Compensation'; ro='%Employeeul are deja %Compensation'; ru='%Employee уже имеет %Compensation'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EmployeeTransferError2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='On the date of the changes you have attempted to make, %Employee does not have registered compensation %Compensation. You cannot modify or remove compensation which is not yet registered'; ro='La data modificărilor, %Employee nu sunt calcule la %Compensation. Nu puteți modifica / șterge un calcul care nu este înregistrat la un angajat'; ru='На дату изменений, у %Employee нет начисления %Compensation. Нельзя изменить/удалить начисление, которое не зарегистрировано за сотрудником'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure InvalidAssetsAmortizationDate ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The calculation starting period is empty, or is not defined correctly'; ro='Luna începerii amortizării nu este setată sau este setată incorect'; ru='Месяц начала начисления износа не задан или задан некорректно'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EmptyAssetsAmortizationExpenses ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Expenses not filled'; ro='Modul de reflectare a cheltuielilor nu este completat'; ru='Способ отражения расходов не заполнен'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure AssetsCalculationPeriod ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This document has already been accessed on %Date. Document - %Ref.'; ro='Le data %Date, documentul a fost deja creat. Document -% Ref.'; ru='На дату %Date документ уже был создан. Документ - %Ref.'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PaymentExpired ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Payment %Option, %Amount has not been received'; ro='Plata %Option, %Amount nu a fost primită'; ru='Просрочена оплата %Option на сумму %Amount'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnexpectedPayments ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en = 'There is no planned %Amount payments in the %Document for this invoice';ro = 'Nu există %Amount plăți planificate în %Document pentru această factură';ru = 'В %Document нет запланированных %Amount платежей для этой накладной'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PeriodError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Period is incorrect'; ro='Perioadă specificată incorect'; ru='Некорректно задан период'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure DataCleaning ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DataCleaning" ) export

	text = NStr ( "en='All data will be cleaned.
				|Continue?'; ro='Toate datele vor fi șterse.
				|Doriți să continuați?'; ru='Данные будут очищены.
				|Продолжить?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure WrongTotalHours ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Evening and Night hours cannot be more that total work hours'; ro='Orele de noapte și de seară nu trebuie să depășească orele de baza'; ru='Ночные и вечерние часы не должны быть больше часов основного времени'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure SaveModifiedObject ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SaveModifiedObject" ) export

	text = NStr ( "en='The object will be saved.
				|Would you like to continue?'; ro='Obiectul va fi înregistrat, continuați?'; ru='Объект будет записан, продолжить?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure RecordAlreadyCanceled ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "LimitAlreadyNotUsed" ) export

	text = NStr ( "en='The selected record has already been canceled '; ro='Înregistrarea selectată a fost anulată anterior'; ru='Выбранная запись уже бала отменена ранее'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Function EnterFileName () export

	text = NStr ( "en='Enter a file name'; ro='Introduceți numele fișierului'; ru='Введите имя файла'" );
	return text;

EndFunction

&AtServer
Function PayrollNetAmount () export

	text = NStr ( "en='Payroll net amount'; ro='Salariu de plătit'; ru='Зарплата к выплате'" );
	return text;

EndFunction

&AtServer
Function PayrollPayment () export

	text = NStr ( "en='Payroll payment after all deductions'; ro='Plata salarială după toate deducerile'; ru='Зарплата на руки после вычета всех налогов'" );
	return text;

EndFunction

&AtClient
Function InfoDetected () export

	text = NStr ( "en='Information messages were detected'; ro='S-au găsit mesaje de informare'; ru='Найдены информационные сообщения'" );
	return text;

EndFunction

&AtClient
Procedure ListIsReadonly ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ListIsReadonly" ) export

	text = NStr ( "en='You do not have sufficient permissions to enter new documents '; ro='Nu aveți acces pentru a introduce noi documente'; ru='У вас нет доступа на ввод новых документов'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure ApplySimplicityConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ApplySimplicityConfirmation" ) export

	text = NStr ( "en='Unused records will be removed.
				|Would you like to continue?'; ro='Rândurile neutilizate vor fi șterse.
				|Doriți să continuați?'; ru='Неиспользуемые строки будут удалены.
				|Продолжить?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function IDIssued () export

	text = NStr ( "en='date'; ro='data'; ru='дата'" );
	return text;

EndFunction

&AtServer
Function IDIssuedBy () export

	text = NStr ( "en='issued by'; ro='emis'; ru='выдано'" );
	return text;

EndFunction

&AtServer
Function IDNumber () export

	text = NStr ( "en='#'; ro='№'; ru='№'" );
	return text;

EndFunction

&AtServer
Function IDSeries () export

	text = NStr ( "en='Series'; ro='seria'; ru='серия'" );
	return text;

EndFunction

&AtServer
Function NotHired () export

	text = NStr ( "en='Not hired'; ro='Nu este angajat'; ru='Еще не принят'" );
	return text;

EndFunction

&AtServer
Function HiredFrom () export

	text = NStr ( "en='Hired from '; ro='Lucrează de la'; ru='Работает с '" );
	return text;

EndFunction

&AtServer
Function FiredFrom () export

	text = NStr ( "en='Fired from '; ro='Concediat de la'; ru='Уволен с '" );
	return text;

EndFunction

Function Billable () export

	text = NStr ( "en='Billable+Non-billable'; ro='Achitat + Neachitat'; ru='Оплачиваемое+Неоплачиваемое'" );
	return text;

EndFunction

&AtClient
Procedure MarkForDeletion ( Module, CallbackParams = undefined, Params = undefined, ProcName = "MarkForDeletion" ) export

	text = NStr ( "en='Mark ""%Object"" for deletion?'; ro='Doriți să marcați ""%Object"" pentru ștergere?'; ru='Пометить ""%Object"" на удаление?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure Undelete ( Module, CallbackParams = undefined, Params = undefined, ProcName = "Undelete" ) export

	text = NStr ( "en='Clear ""%Object"" deletion mark?'; ro='Doriți să eliminați de pe ""%Object"" marcajul pentru ștergere?'; ru='Снять с ""%Object"" пометку на удаление?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function OpeningBalances () export

	text = NStr ( "en='Opening balances'; ro='Introducerea soldurilor'; ru='Ввод остатков'" );
	return text;

EndFunction

&AtServer
Procedure DocumentRightsPermissionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='You do not have access to the user/group: %Target'; ro='Nu există suficiente permisiuni pentru a stabili drepturi utilizator / grup: %Target'; ru='Недостаточно полномочий для установки прав пользователя/группы: %Target'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DocumentRightsUndefined ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Access rights for ""%User"" are undefined. User cannot change or create documents'; ro='Pentru utilizator ""%User"" nu sunt setate drepturi de creare / editare a documentelor'; ru='Для пользователя ""%User"" не заданы права на создание/изменение документов'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DocumentModificationIsNotAllowed ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='""%User"" does not have sufficient access to perform the ""%Action"" action. Please contact your administrator to resolve this issue.'; ro='Utilizatorul ""%User"" nu are drepturi suficiente pentru a efectua operația ""%Action"". Contactați administratorul rolurilor pentru a rezolva situația.'; ru='У пользователя ""%User"" недостаточно прав для совершения операции ""%Action"". Обратитесь к администратору ролей для разрешения ситуации'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ObjectNotOriginal ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='%Value already exists!'; ro='Valoarea% există deja!'; ru='%Value уже существует!'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function OpeningBalancesError () export

	text = NStr ( "en='Please create the document from the Opening Balances list'; ro='Vă rugăm să creați documentul din lista Introducerea soldurilor'; ru='Документ вводится из журнала Остатки'" );
	return text;

EndFunction

&AtClient
Procedure ActionNotSupported ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ActionNotSupported" ) export

	text = NStr ( "en='The selected action is not supported in the current window state'; ro='Comanda nu este disponibilă în modul curent de deschidere a ferestrei '; ru='Команда недоступна в текущем режиме открытия окна'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Procedure LimitReached ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='In order to create a new user, please purchase additional licenses (Settings / Licenses / My Orders)'; ro='Pentru a crea un utilizator nou, trebuie să achiziționați licențe suplimentare pentru utilizarea serviciului (Setări / Licențe / Comenzile mele)'; ru='Для создания нового пользователя, необходимо приобрести дополнительные лицензии на использование сервиса (Настройки / Лицензии / Мои заказы)'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ServicesList () export

	text = NStr ( "en='Services'; ro='Servicii'; ru='Услуги'" );
	return text;

EndFunction

&AtServer
Procedure EmployeePeriodErrorRows ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='In the line #%Line (%Employee) incorrect periods have been found '; ro='În rîndul #%Line (%Employee)  au fost găsite perioade incorecte'; ru='В строке %Line, по сотруднику %Employee обнаружено пересечение периодов'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EmployeePeriodErrorHours ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='In the line #%Line (%Employee), the system found conflicts for the following dates; %Days'; ro='În rîndul #%Line (%Employee), sistemul a găsit conflicte pentru următoarele date:%Days'; ru='В строке %Line, по сотруднику %Employee обнаружено пересечение периодов по следующим дням: %Days'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure MissedHours ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Work hours for %Employee are undefined. Check employee’s schedule for the following days: %Days'; ro='Angajatului %Employee nu au fost găsite ore din program de lucru în zilele următoare: %Days'; ru='По сотруднику %Employee не обнаружены часы по графику по следующим дням: %Days'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure CustomerPaymentError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Amount due is not equal to Payment amount'; ro='Suma datoriei nu este egală cu suma plății'; ru='Сумма долга не равна сумме оплаты'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

Function CustomerPaymentDifference ( Params = undefined ) export

	text = NStr ( "en='The difference between Amount Due and Payment Amount is %Amount'; ro='Diferența dintre suma datoriei și suma de plată este: %Amount'; ru='Разница между суммой долга и оплаты составляет: %Amount'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Procedure PaymentNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Amount due: <%Payment>, was not found. Payment of %Amount to this row has not been applied'; ro='Datoria de <%Payment> nu a fost găsită, suma %Amount nu a fost aplicată'; ru='Задолженность по <%Payment> не найдена, сумма %Amount не применена'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure PaymentDataUpdateConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "PaymentDataUpdateConfirmation" ) export

	text = NStr ( "en='Table will be updated.
				|Would you like to continue?'; ro='Tabelul va fi actualizat.
				|Doriți să continuați?'; ru='Таблица будет обновлена.
				|Продолжить?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure AdjustDebtsError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Amount due is not equal to Adjustment amount'; ro='Suma datoriilor nu este egală cu valoarea rectificării'; ru='Сумма долга не равна сумме корректировки'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

Function AdjustDebtsDifference ( Params = undefined ) export

	text = NStr ( "en='The difference between Amount Due and Adjustment Amount is %Amount'; ro='Diferența dintre valoarea datoriei și rectificării este: %Amount'; ru='Разница между суммой долга и корректировки составляет: %Amount'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Procedure AdjustmentNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Amount due: <%Adjustment>,  was not found. Adjustment of %Amount to this row has not been applied'; ro='Datoria pe <%Adjustment> nu a fost găsit, suma %Amount nu a fost aplicată'; ru='Задолженность по <%Adjustment> не найдена, сумма %Amount не применена'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure AdjustmentDataUpdateConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "AdjustmentDataUpdateConfirmation" ) export

	text = NStr ( "en='Table will be updated.
				|Would you like to continue?'; ro='Tabelul va fi actualizat.
				|Doriți să continuați?'; ru='Таблица будет обновлена.
				|Продолжить?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function TimeEntryCrossingDays () export

	text = NStr ( "en='A Time Entry cannot span more than one day'; ro='Timpul de înregistrare nu poate fi localizat la intersecția de zile'; ru='Запись времени не может находиться на пересечении дней'" );
	return text;

EndFunction

&AtServer
Function TimeEntryChangeDurationError () export

	text = NStr ( "en='The Time Entry cannot be adjusted because it contains more than one record'; ro='Este imposibil de a schimba durata timpului de înregistrare care cuprinde mai mult de un rând cu date'; ru='Нельзя изменить продолжительность записи времени содержащей более одной строки с данными'" );
	return text;

EndFunction

&AtClient
Function Performer () export

	text = NStr ( "en='Performer'; ro='Executant'; ru='Исполнитель'" );
	return text;

EndFunction

&AtServer
Function UserNotFound ( params ) export

	text = NStr ( "en='The associated user was not found.
				|In order to use the Time Entry document, please go to Main Menu / Settings / Users and create a system user'; ro='Utilizatorul asociat nu a fost găsit.
				|Pentru a utiliza documentul Înregistrare de timp, trebuie să creați un utilizator al sistemului
				|din Meniul principall / Setări / Utilizatori'; ru='Для выбранного сотрудника не ассоциирован пользователь системы.
				|Для ввода детальных записей времени, необходимо в справочнике
				|Пользователи, создать пользователя для табелируемого сотрудника'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function EmployeeNotAssigned ( Params ) export

	text = NStr ( "en='There is no associated employee for <%User>.
				|Open Main Menu / Settings / Users, and assign employee status to the user '; ro='Nu există niciun angajat asociat pentru <%User>.
				|Deschideți profilul utilizatorului (Meniul principal / Setări / Utilizatori)
				|și desemnați angajatul necesar'; ru='Для пользователя <%User> не указан сотрудник.
				|Откройте профиль пользователя в Меню / Настройки / Пользователи
				|и задайте ассоциированного с ним сотрудника'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Function ProjectDragAndDropError () export

	text = NStr ( "en='Drag & Drop Projects are supported only if ""filter by
				|performers"" is disabled or has only one selected user.
				|
				|Open Calendar Settings and select only one performer
				|(or deselect all of them) in the performers list'; ro='Operațiunea ""Drag & Drop"" pentru Proiecte este posibilă numai dacă filtrul dupa executant este dezactivaț sau este selectat numai un singur utilizator.
				|
				|Deschideți Setările Calendarului și selectați numai un executant
				|(sau deselectați-le pe toate) în lista executorilor'; ru='Для возможности перетаскивания проектов, необходимо установить отбор
				|только по одному исполнителю, либо отключить фильтрацию полностью.
				|
				|Откройте настройки календаря, и в списке исполнителей выберите только одного пользователя, либо отключите их всех'" );
	return text;

EndFunction

&AtClient
Function HintsProjectsInCalendar () export

	text = NStr ( "en='When viewing Projects, the calendar hides the following items: Tasks, Reminders, Meetings and Time Records'; ro='La afișarea proiectelor, sarcinile, întâlnirile, mementourile și înregistrările de timp nu sunt afișate'; ru='При выводе проектов, задачи, напоминания, встречи и записи времени не отображаются'" );
	return text;

EndFunction

&AtClient
Function HintsRoomsInCalendar () export

	text = NStr ( "en='When viewing Rooms, the calendar hides the following items: Tasks, Projects, Reminders, Meetings and Time Records'; ro='La afișarea camerelor sarcinile, întâlnirile, proiectele, mementourile și înregistrările de timp nu sunt afișate'; ru='При выводе помещений, задачи, напоминания, проекты, встречи и записи времени не отображаются'" );
	return text;

EndFunction

&AtServer
Procedure ProcessIsRemoved ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='This process was marked for deletion and can no longer be used'; ro='Acest proces a fost marcat pentru ștergere și nu mai poate fi utilizat'; ru='Этот процесс был помечен на удаление и уже не может быть использован'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function TaskCopyingError () export

	text = NStr ( "en='Tasks associated with the Assignment Process cannot be copied '; ro='Copierea sarcinilor procesului Comanda nu este permisă'; ru='Копирование задач процесса Распоряжение не допускается'" );
	return text;

EndFunction

&AtServer
Function TaskModifyingError () export

	text = NStr ( "en='The performer cannot be changed during the checking stage'; ro='Nu puteți modifica executantul când
				|sarcina se află în faza de verificare'; ru='Вы не можете сменить исполнителя, когда
				|задача находится на стадии проверки'" );
	return text;

EndFunction

&AtClient
Procedure DeleteCommand ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DeleteCommand" ) export

	text = NStr ( "en='Would you like to remove the command?'; ro='Doriți să ștergeți comanda?'; ru='Удалить распоряжение?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtServer
Function DeletedTaskExecution () export

	text = NStr ( "en='Deleted task cannot be executed'; ro='O sarcină ștearsă nu poate fi lansată'; ru='Удаленная задача не может быть запущена'" );
	return text;

EndFunction

&AtServer
Procedure TimesheetNotApproved ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Timesheet %Timesheet was missed because it is not in process of approval'; ro='Foaia de pontaj %Timesheet a fost ratată pentru că nu este în curs de aprobare'; ru='Табель %Timesheet пропущен, так как не находится в стадии утверждения'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ProcessingRow ( Params = undefined ) export

	text = NStr ( "en='Processing row #%Row from %Count'; ro='Se procesează rîndul #%Row din %Count'; ru='Обрабатывается строка №%Row из %Count'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Procedure UnbalancedEntry ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Debit Amount should be equal to Credit Amount'; ro='Suma de debit ar trebui să fie egală cu suma creditului'; ru='Сумма дебета должна быть равна сумме кредита'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function WorkshopsList () export

	text = NStr ( "en='Workshops'; ro='Ateliere'; ru='Цеха'" );
	return text;

EndFunction

&AtServer
Function ParametersCountError ( Params ) export

	text = NStr ( "en='%Name (): Count of parameters cannot be more than %Limit'; ro='%Name (): Numărul parametrilor nu poate fi mai mare decât %Limit'; ru='%Name (): Количество параметров не может быть больше %Limit'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function ExportDataUndefined () export

	text = NStr ( "en='Export data not found!'; ro='Datele pentru export nu au fost găsite!'; ru='Данные для экспорта не найдены!'" );
	return text;

EndFunction

&AtClient
Procedure ExportDataCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ExportDataCompleted" ) export

	text = NStr ( "en='Export completed!'; ro='Exportul este finisat!'; ru='Экспорт завершен!'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure SystemInDemoMode ( Params = undefined, NavigationLink = undefined ) export

	text = NStr ( "en='Warning'; ro='Avertizare'; ru='Внимание'" );
	explanation = NStr ( "en='System works in demo-mode and will be close in an hour. To get license key please call Contabilizare, phone: 22-54-88'; ro='Sistemul funcționează în regimul demo și va fi de o oră. Pentru a obține cheia de licență, vă rugăm să sunați la oficiul companiei Contabilizare, telefon: 22-54-88'; ru='За получением лицензии на использование конфигурации, обращайтесь в офис фирмы Contabilizare, телефон 22-54-88. Через час приложение будет закрыто'" );
	putUserNotification ( text, Params, NavigationLink, explanation, PictureLib.Warning );

EndProcedure

&AtClient
Procedure RestartSystem ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "RestartSystem" ) export

	text = NStr ( "en='Changes to the license necessitate a restart of the application. 
				|Would you line to restart now? '; ro='Modificările parametrilor licenței necesită restartarea aplicației.
				|Doriți să restartați aplicația?'; ru='Применение параметров лицензии требует перезапуск приложения.
				|Перезапустить приложение?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function LicenseNotDefined () export

	text = NStr ( "en='License is not defined'; ro='Licența nu este definită'; ru='Лицензия не задана'" );
	return text;

EndFunction

&AtServer
Function InfobaseWasCopied () export

	text = NStr ( "en='The infobase has been copied. License information cleared'; ro='Infobase-ul a fost copiat. Informațiile despre licență au fost șterse'; ru='Информационная база была скопирована. Информация о лицензии очищена'" );
	return text;

EndFunction

&AtServer
Function AccessKeyResettingError () export

	text = NStr ( "en='Something went wrong during the Access Key resetting process. Please try again later'; ro='A apărut o eroare în procesul de resetare a cheii de acces. Încercați din nou mai târziu'; ru='Возникла ошибка в процессе сброса ключа доступа. Попробуйте повторить операцию позже'" );
	return text;

EndFunction

&AtServer
Function OSNotSupported () export

	text = NStr ( "en = 'At present, the application is not supported on this operating system';ro = 'În prezent, aplicația nu este suportată pe acest sistem de operare';ru = 'В настоящее время, работа конфигурации в данной операционной системе не поддерживается'" );
	return text;

EndFunction

&AtServer
Procedure DoubleParticipants ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Participants cannot be duplicated'; ro='Participanții nu pot fi repetați'; ru='Участники не могут повторяться'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function MeetingSubject ( Params ) export

	text = NStr ( "en='Meeting at %StartTime in %StartDate, %Room'; ro='la întâlnirea la %StartTime în %StartDate, %Room'; ru='на встречу в %StartTime %StartDate, %Room'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingCanceled () export

	text = NStr ( "en='Canceled'; ro='Anulată'; ru='Отменена'" );
	return text;

EndFunction

&AtServer
Function MeetingUpdated () export

	text = NStr ( "en='Updates'; ro='Actualizări'; ru='Обновления'" );
	return text;

EndFunction

&AtServer
Function MeetingMessage ( Params ) export

	text = NStr ( "en='Message to participants: %Changes'; ro='Mesaj către participanți: %Changes'; ru='Сообщение участникам: %Changes'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingBodyWhat ( Params ) export

	text = NStr ( "en='Subject: %SubjectChanged %Subject'; ro='Subiect: %SubjectChanged %Subject'; ru='Тема: %SubjectChanged %Subject'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingBodyWhen ( Params ) export

	text = NStr ( "en='When: %TimeChanged from %StartTime %StartDate to %FinishTime %FinishDate (duration is %Duration)'; ro='Când: %TimeChanged de la %StartTime %StartDate la %FinishTime %FinishDate (durata %Duration)'; ru='Когда: %TimeChanged с %StartTime %StartDate по %FinishTime %FinishDate (продолжительность %Duration)'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingBodyWhere ( Params ) export

	text = NStr ( "en='Where: %RoomChanged %Room'; ro='Unde: %RoomChanged %Room'; ru='Где: %RoomChanged %Room'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingBodyAddress ( Params ) export

	text = NStr ( "en='Address: %Address'; ro='Adresa: %Address'; ru='Адрес: %Address'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingBodyWho ( Params ) export

	text = NStr ( "en='Who: %Members'; ro='Cine: %Members'; ru='Кто: %Members'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingBodyActions () export

	text = NStr ( "en='Will you attend?
				|
				|<a href=""%Yes"">&nbsp;&nbsp;&nbsp; Yes &nbsp;&nbsp;&nbsp;</a>
				| | <a href=""%No"">&nbsp;&nbsp;&nbsp; No &nbsp;&nbsp;&nbsp;</a>
				| | <a href=""%Maybe"">&nbsp;&nbsp;&nbsp; Maybe &nbsp;&nbsp;&nbsp;</a>'; ro='Veți veni?
				|<a href=""%Yes"">&nbsp;&nbsp;&nbsp; Da &nbsp;&nbsp;&nbsp;</a>
				| | <a href=""%No"">&nbsp;&nbsp;&nbsp; Nu &nbsp;&nbsp;&nbsp;</a>
				| | <a href=""%Maybe"">&nbsp;&nbsp;&nbsp; Poate &nbsp;&nbsp;&nbsp;</a>'; ru='Вы придете?
				|<a href=""%Yes"">&nbsp;&nbsp;&nbsp; Да &nbsp;&nbsp;&nbsp;</a>
				| | <a href=""%No"">&nbsp;&nbsp;&nbsp; Нет &nbsp;&nbsp;&nbsp;</a>
				| | <a href=""%Maybe"">&nbsp;&nbsp;&nbsp; Возможно &nbsp;&nbsp;&nbsp;</a>'" );
	return text;

EndFunction

&AtServer
Function MeetingBodyInvitation ( Params ) export

	text = NStr ( "en='<a href=""%Invitation"">Open the invitation</a>'; ro='<a href=""%Invitation"">Deschideți invitația</a>'; ru='<a href=""%Invitation"">Открыть приглашение</a>'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingChanged () export

	text = NStr ( "en='<font color=""red"">(changed)</font>'; ro='<font color=""red"">(modificat)</font>'; ru='<font color=""red"">(изменено)</font>'" );
	return text;

EndFunction

&AtServer
Function MeetingCanceledBody () export

	text = NStr ( "en='The meeting was canceled.'; ro='Întâlnirea a fost anulată.'; ru='Встреча была отменена.'" );
	return text;

EndFunction

&AtServer
Function MeetingCanceledReason ( Params ) export

	text = NStr ( "en='The reason: %Reason'; ro='Motivul: %Reason'; ru='Причина: %Reason'" );
	return FormatStr ( text, Params );

EndFunction

&AtClient
Procedure MeetingNotStarted ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'The meting has not been started'; ro = 'Această întâlnire încă nu s-a început'; ru = 'Эта встреча еще не началась'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function NotificationsPage ( Params ) export

	text = NStr ( "en='If you would like to disable notifications, open the <a href=""%MySettings"">My Settings</a> page.'; ro='Dacă doriți să deactivați notificările, deschideți pagina <a href=""%MySettings"">Setările mele</a>.'; ru='Если вы хотите отключить уведомления, откройте страницу <a href=""%MySettings"">Мои настройки</a>.'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MailTo ( Params ) export

	text = "<a href=""mailto:%Email"">%Name</a>";
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingOrganizer () export

	text = NStr ( "en='(organizer)'; ro='(organizator)'; ru='(организатор)'" );
	return text;

EndFunction

&AtServer
Function MeetingSaidYes () export

	text = NStr ( "en='Yes'; ro='Da'; ru='Да'" );
	return text;

EndFunction

&AtServer
Function MeetingSaidNo () export

	text = NStr ( "en='No'; ro='Nu'; ru='Нет'" );
	return text;

EndFunction

&AtServer
Function MeetingSaidMaybe () export

	text = NStr ( "en='Maybe'; ro='Posibil'; ru='Возможно'" );
	return text;

EndFunction

&AtServer
Function MeetingSaidNothing () export

	text = NStr ( "en='Awaiting'; ro='În așteptare'; ru='В ожидании'" );
	return text;

EndFunction

&AtServer
Function MeetingNotificationSubject ( Params ) export

	text = NStr ( "en='Meeting at %StartTime in %StartDate, %Room'; ro='la întâlnirea la %StartTime în %StartDate, %Room'; ru='на встречу в %StartTime %StartDate, %Room'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingNotificationAnswerYes () export

	text = NStr ( "en='will come'; ro='va veni'; ru='придет'" );
	return text;

EndFunction

&AtServer
Function MeetingNotificationAnswerMaybe () export

	text = NStr ( "en='might come'; ro='posibil va veni'; ru='возможно придет'" );
	return text;

EndFunction

&AtServer
Function MeetingNotificationAnswerNo () export

	text = NStr ( "en='will not come'; ro='nu va veni'; ru='не придет'" );
	return text;

EndFunction

&AtServer
Function MeetingNotificationBody ( Params ) export

	text = NStr ( "en='Subject: %Subject<br/>
				|Who: %MemberMailTo<br/>
				|Answer: %Answer'; ro='Subiect: %Subject<br/>
				|Care: %MemberMailTo<br/>
				|Răspuns: %Answer'; ru='Тема: %Subject<br/>
				|Кто: %MemberMailTo<br/>
				|Ответ: %Answer'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function MeetingNotificationBodyComment ( Params ) export

	text = NStr ( "en='%Member left a comment: %Comment'; ro='%Member a lăsat un comentariu: %Comment'; ru='%Member оставил комментарий: %Comment'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Function RemoteActionNotFound () export

	text = NStr ( "en='Remote action not found'; ro='Nu s-a găsit acțiunea la distanță'; ru='Удаленное действие не найдено'" );
	return text;

EndFunction

&AtServer
Function RemoteActionExpired () export

	text = NStr ( "en='Remote action is expired'; ro='Acțiunea la distanță a expirat'; ru='Удаленное действие истекло'" );
	return text;

EndFunction

&AtServer
Function RemoteActionApplied () export

	text = NStr ( "en='Thank you! The action has successfully been applied.'; ro='Mulțumesc! Acțiunea a fost aplicată cu succes.'; ru='Спасибо! Действие было успешно применено.'" );
	return text;

EndFunction

&AtClient
Function Meeting () export

	text = NStr ( "en='Meeting'; ro='Întâlnire'; ru='Встреча'" );
	return text;

EndFunction

&AtClient
Function Room () export

	text = NStr ( "en='Room'; ro='Cameră'; ru='Помещение'" );
	return text;

EndFunction

&AtServer
Procedure MeetingExpired ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The start date of the meeting has already passed'; ro='Data începerii întâlnirii a expirat deja'; ru='Дата начала встречи уже истекла'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RoomOccupied ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The room is already occupied at this time: %Meeting'; ro='În acest moment camera este deja ocupată: %Meeting'; ru='На это время помещение уже занято: %Meeting'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure MeetingShouldBeCanceled ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='A meeting is scheduled. You need to cancel it before marking it for deletion'; ro='Întâlnirea este formată. Trebuie să o anulați înainte de a o marca pentru ștergere'; ru='Встреча сформирована. Вам необходимо отменить встречу перед тем, как пометить ее на удаление'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Function UpdateNotPermitted () export

	text = NStr ( "en='Application data update is required but you do not have access to do that. Contact your system administrator or try to login later.'; ro='Este necesară actualizarea datelor bazei de date, dar nu aveți acces pentru a face acest lucru. Contactați administratorul de sistem sau încercați să vă conectați mai târziu.'; ru='Требуется обновление данных информационной базы, однако у вас недостаточно прав для выполнения данной операции. Свяжитесь с администратором вашей системы или повторите попытку входа в систему позднее.'" );
	return text;

EndFunction

&AtServer
Function UpdateAlreadyStarted () export

	text = NStr ( "en='Background job of updating infobase has been already  running. Try to login later again.'; ro='Lucrarea de fundal a actualizării bazei de date a fost deja executată. Încercați să vă conectați din nou mai târziu.'; ru='Фоновое задание обновления информационной базы уже запущено. Попробуйте войти позже.'" );
	return text;

EndFunction

&AtServer
Function UpdateError () export

	text = NStr ( "en='An error occurred during update'; ro='A apărut o eroare în timpul actualizării'; ru='Произошла ошибка во время обновления'" );
	return text;

EndFunction

&AtClient
Procedure ShowError ( Module = undefined, CallbackParams = undefined, Error, ProcName = "ShowError" ) export

	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( Error, undefined, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Function RequestError () export

	text = NStr ( "en='An error occurred during processing request:'; ro='A apărut o eroare în timpul solicitării de procesare:'; ru='Произошла ошибка во время обработки запроса:'" );
	return text;

EndFunction

&AtClient
Procedure DirectConnectionRequired ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DirectConnectionRequired" ) export

	text = NStr ( "en='Application update can''t be done via web-connection.
				|Direct connection to the database is required.'; ro='Actualizarea aplicației nu se poate realiza prin conexiunea web.
				|Este necesară conectarea directă la baza de date.'; ru='Обновление приложения не может быть сделано через веб-соединение.
				|Требуется прямое подключение к базе данных.'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure MasterNodeRequired ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "MasterNodeRequired" ) export

	text = NStr ( "en='Application update can be done for master node database only'; ro='Actualizarea aplicației poate fi făcută numai pentru nodul principal a bazei de date'; ru='Обновление конфигурации может быть выполнено только в центральном узле информационной системы'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure DesignerNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DesignerNotFound" ) export

	text = NStr ( "en='The executable file not found. In order to update your database, a 1cv8.exe application should be installed on the local computer'; ro='Fișierul executabil nu a fost găsit. Pentru a actualiza baza de date, trebui instalată aplicația 1cv8.exe pe computerul local'; ru='Исполняемый файл не найден. Чтобы обновить информационную базу, на локальном компьютере должно быть установлено приложение 1cv8.exe'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure PlatformNotSupported ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "PlatformNotSupported" ) export

	text = NStr ( "en='The update requires 1C:Enterprise version %RequiredVersion, but your installed version is %YourVersion.
				|Please, update your platform to designated version first and then the application update will be available to install.'; ro='Actualizarea necesită 1C:Enterprise versiunea %RequiredVersion, dar versiunea instalată este %YourVersion.
				|Vă rugăm să actualizați mai întâi platforma la versiunea indicată și apoi actualizarea aplicației va fi disponibilă pentru instalare.'; ru='Для обновления требуется версия 1С:Предприятия %RequiredVersion, ваша версия %YourVersion.
				|Пожалуйста, обновите вашу платформу до указанной версии, и после этого, обновление конфигурации будет доступно для установки.'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure LicenseExpired ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "LicenseExpired" ) export

	text = NStr ( "en='Unfortunately, your subscription has been expired in %Expired. New release dated %Issued can’t be installed.
				|To renew your subscription, please call Contabilizare, phone: 22-54-88'; ro='Din păcate, abonamentul dvs. a expirat în %Expired. Noua versiune din %Issued nu poate fi instalată.
				|Pentru a vă reînnoi abonamentul, vă rugăm să sunați la Contabilizare, telefon: 22-54-88'; ru='К сожалению, ваш срок подписки истек %Expired и обновление вышедшее %Issued не может быть установлено!
				|Для продления подписки, обращайтесь в офис фирмы Contabilizare по телефону 22-54-88'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure LicenseWillExpire ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "LicenseWillExpire" ) export

	text = NStr ( "en='Your license will expire in %Date'; ro='Licența dvs. va expira la %Date'; ru='Срок действия вашей лицензии истекает %Date'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure LicenseAlreadyExpired ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "LicenseAlreadyExpired" ) export

	text = NStr ( "en='Your license has been expired in %Date'; ro='Licența dvs. a expirat la data de %Date'; ru='Срок действия вашей лицензии истек %Date'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure CloseApplicationManually ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "CloseApplicationManually" ) export

	text = NStr ( "en='Please, close this application manually or with TestManager'; ro='Vă rugăm să închideți această aplicație manual sau cu TestManager'; ru='Пожалуйста, закройте это приложение вручную или с помощью Менеджера Тестирования'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure UpdatesNotFound ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "UpdatesNotFound" ) export

	text = NStr ( "en='Updates are not found'; ro='Actualizările nu au fost găsite'; ru='Обновления не найдены'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure InfobaseWillBeLocked ( Module, CallbackParams = undefined, Params = undefined, ProcName = "InfobaseWillBeLocked" ) export

	text = NStr ( "en='The database will be locked during the update.
				|For emergency access you can use this key: ""%Key"".
				|Would you like to continue?'; ro='Baza de date va fi blocată în timpul întregului proces de actualizare.
				|Pentru accesul de urgență puteți utiliza tasta ""%Key"".
				|Doriți să continuați?'; ru='База данных будет заблокирована в течение всего процесса обновления.
				|Для экстренного доступа вы можете использовать ключ ""%Key"".
				|Продолжить операцию?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Function InfobaseUpdateMessage ( Params ) export

	text = NStr ( "en='Infobase has been locked for %Period min since %Date'; ro='Baza de date a fost blocată timp de %Period min de la %Date'; ru='Информационная база была заблокирована на %Period мин начиная с %Date'" );
	return FormatStr ( text, Params );

EndFunction

&AtClient
Procedure DisconnectUsers ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DisconnectUsers" ) export

	text = NStr ( "en='Warning! All sessions will be forcibly disconnected without saving users’ work!
				|Please, confirm that you want to terminate these sessions.'; ro='Avertizare! Toate sesiunile vor fi deconectate forțat fără a salva munca utilizatorilor!
				|Vă rugăm să confirmați că doriți să încheiați aceste sesiuni.'; ru='Внимание! Все сеансы будут отключены без сохранения текущей работы пользователей!
				|Пожалуйста, подтвердите, что вы хотите принудительно завершить соединения.'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure V83ComError ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "V83ComError" ) export

	text = NStr ( "en='V83.COMConnector is not registered. Use the following command for registration: regsvr32.exe comcntr.dll -i'; ro='V83.COMConnector nu este înregistrat. Utilizați următoarea comandă pentru înregistrare: regsvr32.exe comcntr.dll -i'; ru='V83.COMConnector не зарегистрирован. Для регистрации, используйте следующую команду: regsvr32.exe comcntr.dll -i'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure UpdateSaved ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "UpdateSaved" ) export

	text = NStr ( "en='The file has been successfully saved!'; ro='Fișierul a fost salvat cu succes!'; ru='Файл был успешно сохранен!'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtClient
Procedure UndefinedCloudUser ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "UndefinedCloudUser" ) export

	text = NStr ( "en='Cloud User is not defined!
				|The user can be assigned in the menu Settings / System, in the Cloud User field.
				|The specified user should be a system administrator'; ro='Utilizatorul Cloud nu este definit!
				|Utilizatorul poate fi setat în meniul Setări / Sistem, în câmpul Utilizatorul Cloud.
				|Utilizatorul specificat trebuie să fie un administrator de sistem'; ru='Пользователь облака не определен!
				|Для задания пользователя, откройте Настройки / Система и укажите имя пользователя с ролью Администратор системы'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function AuthorizationError ( Params ) export

	text = NStr ("en='Authorization error: %User is not registered in the tenant %Tenant';ro='Eroare de autorizare: %User nu este înregistrat în chiriașul %Tenant';ru='Ошибка авторизации: %User не зарегистрирован в разделителе %Tenant'" );
	return FormatStr ( text, Params );

EndFunction

&AtClient
Function Street () export

	text = NStr ( "en='str.'; ro='str.'; ru='str.'" );
	return text;

EndFunction

&AtServer
Function AsOf () export

	text = NStr ( "en = 'As Of'; ro = 'De la'; ru = 'На дату'" );
	return text;

EndFunction

&AtServer
Function AutoEmployee () export

	text = NStr ("en = 'Will be created automatically on write'; ro = 'Va fi creat automat la înregistrare'; ru = 'Будет создан автоматически при записи'" );
	return text;

EndFunction

&AtServer
Procedure TimeEntryItemsNotValid ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'The row cannot be reconciled with the document %TimeEntry'; ro = 'Răndul de este în acord cu documentul %TimeEntry'; ru = 'Строка не согласована с документом %TimeEntry'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure WrongTenantAccess ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Login" ) export

	text = NStr ("en = 'You cannot create/change this user in the current tenant without giving access to this tenant. Probably, you need to switch your session to required tenant before working with user access'; ro = 'Nu aveți suficiente drepturi de a crea / modifica acest utilizator în cadrul chiriașului curent fără a-i acorda drepturi de acces. Probabil aveți nevoie să schimbați sesiune pe chiriașil necesar și să îndepliniți operația de acolo'; ru = 'Вы не можете создать/изменить этого пользователя в текущем арендаторе без предоставления доступа к нему. Вероятно, вам нужно переключить сессию на требуемого арендатора, и выполнить настройку оттуда'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure WrongMembershipTenantAccess ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Login" ) export

	text = NStr ("en = 'You cannot create/change this group in the current tenant without giving access to this tenant. Probably, you need to switch your session to required tenant before working with user access'; ro = 'Nu aveți suficiente drepturi de a crea / modifica acest grup în cadrul chiriașului curent fără a-i acorda drepturi de acces. Probabil aveți nevoie să schimbați sesiune pe chiriașil necesar și să îndepliniți operația de acolo'; ru = 'Вы не можете создать/изменить эту группу в текущем арендаторе без предоставления доступа к нему. Вероятно, вам нужно переключить сессию на требуемого арендатора, и выполнить настройку оттуда'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LoginAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Login already exists'; ro = 'Acest login deja există'; ru = 'Такой логин уже существует'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function UserAccessChangingError ( Params ) export

	text = NStr ("en = '%Tenant access changing error: %Error'; ro = 'Eroare de acces al %Tenant access changing error: %Error'; ru = 'Ошибка изменения доступа для %Tenant: %Error'" );
	return FormatStr ( text, Params );

EndFunction

&AtServer
Procedure FormRequired ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'The operation cannot be performed from the list. Please open the main form and repeat the operation'; ro = 'Operația nu poate fi executată din listă. Dechideți vă rog forma principală și repetați operația'; ru = 'Операция не может быть выполнена из списка. Пожалуйста, откройте основную форму и повторите операцию'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ValueDuplicated ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'This value already exists in the list'; ro = 'Această valoare deja există în listă'; ru = 'Это значение уже существует в списке'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function PrintFormEmailBody ( Params ) export

	text = "
	|Il s'agit d'un courriel généré automatiquement par %Company que vous avez récemment demandé. Votre document est en pièce jointe.
	|Veuillez ne pas répondre à cet e-mail.
	|
	|---
	|
	|This is an automatically generated email from %Company which you recently requested. Your document is in attachment.
	|Please, don’t reply to this email.
	|";
	return FormatStr ( text, Params );

EndFunction

&AtServer
Procedure WorkBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Not enough %Resource item %Item in billable time. The balance of %TimeEntry is %ResourceBalance '; ro = '%Resource insuficient/ă pentru serviciul %Item ăn soldul serviciilor cu plată. Sold la %TimeEntry este de %ResourceBalance'; ru = 'Не хватает %Resource услуги %Item в остатке оплачиваемых часов. В остатке %TimeEntry числится %ResourceBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function UndefinedCostPriceType () export

	text = NStr ("en = 'Please specify the type of accounting prices in the source document or company settings'; ro = 'Selectați vă ră rog tipul de preț din documentul inițial sau din setările companiei'; ru = 'Задайте пожалуйста тип учетных цен в исходном документе или настройках компании'" );
	return text;

EndFunction

&AtServer
Procedure InvoiceCheckFillingErrors ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Check filling errors have been found. Invoice can’t be produced'; ro = 'Vânzarea nu poate fi vlidată din cauza unor erori la cmpletarea documentului'; ru = 'Реализация не может быть проведена из-за наличия ошибок заполнения документа'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ShouldBe () export
	
	text = NStr ( "en = 'should be'; ru = 'должно быть'");
	return text;
	
EndFunction

&AtServer
Function ShouldNotBe () export
	
	text = NStr ( "en = 'should not be'; ru = 'не должно быть'");
	return text;
	
EndFunction

&AtServer
Function Filled () export
	
	text = NStr ("en = 'filled'; ru = 'заполненным'; ro = 'umplut'");
	return text;
	
EndFunction

&AtServer
Function Empty () export
	
	text = NStr ( "en = 'empty'; ru = 'пустым'");
	return text;
	
EndFunction

&AtServer
Function Existed () export
	
	text = NStr ("en = 'existed'; ru = 'существующим'; ro = 'a existat'");
	return text;
	
EndFunction

&AtServer
Function Between ( Params ) export
	
	text = NStr ( "en = 'between %Start and %Finish'; ru = 'между %Start и %Finish'");
	return Output.FormatStr ( text, Params );
	
EndFunction

&AtServer
Function ShouldContain () export
	
	text = NStr ( "en = 'should contain'; ru = 'должно содержать'");
	return text;
	
EndFunction

&AtServer
Function ShouldNotContain () export
	
	text = NStr ( "en = 'should not contain'; ru = 'не должно содержать'");
	return text;
	
EndFunction

&AtServer
Function ShouldHave () export
	
	text = NStr ( "en = 'should have size'; ru = 'должно иметь размер'");
	return text;
	
EndFunction

&AtServer
Function ShouldNotHave () export
	
	text = NStr ( "en = 'should not have size'; ru = 'не должно иметь размер'");
	return text;
	
EndFunction

&AtServer
Function Value () export
	
	text = NStr ( "en = 'Value'; ru = 'Значение'");
	return text;
	
EndFunction

&AtServer
Function YesNo () export
	
	text = NStr ( "en = 'BF=False; BT=True'; ru = 'BF=Ложь; BT=Истина'");
	return text;
	
EndFunction

&AtClient
Procedure CompleteMeetingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CompleteMeetingConfirmation" ) export

	text = NStr ("en = 'Would you like to complete the meeting?'; ro = 'Data finalizării nu poate fi anterioară datei începutului întâlnirii'; ru = 'Завершить это собрание?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure WrongFinishingDate1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Finishing date can’t be earlier then meeting start date'; ro = 'Data finalizării nu poate fi anterioară datei începutului întâlnirii'; ru = 'Дата завершения не может быть раньше начала встречи'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure WrongFinishingDate2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Finishing date can’t be in the future period'; ro = 'Data finalizării nu poate fi în periada viitoare'; ru = 'Дата завершения не может быть в будущем периоде'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EventExpired ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = ""The event can't be scheduled because the start date has already expired""; ro = 'Evenimentul nu poate fi planificat deoarece data începutul a expirat deja'; ru = 'Событие не может быть запланировано, потому что дата начала уже истекла'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EventNotStarted ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'The event has not been started'; ro = 'Evenimentul încă nu s-a început'; ru = 'Событие еще не началось'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ResponsibleBusy ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = '%Responsible is busy at this time: %Event'; ro = '%Responsible la moment este ocupat/ă, vezi evenimentul: %Event'; ru = '%Responsible занят в это время, см. %Event'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function EventBody ( Params ) export

	text = NStr ("en = 'Subject: %FullSubject"
"Organization: %Organization."
"Contact: %Contact."
"Scheduled: %Start %StartTime - %Finish."
"Dutation: %Duration"
"Content: %Content"
""
"The event can be opened here:"
"%URL'; ro = 'Subiect: %FullSubject"
"Terț: %Organization."
"Contract: %Contact."
"Planificat: %Start %StartTime - %Finish."
"Durata: %Duration"
"Conținut: %Content"
""
"Evenimentul poate fi accesat aici:"
"%URL'; ru = 'Тема: %FullSubject"
"Контрагент: %Organization."
"Контакт: %Contact."
"Запланировано: %Start %StartTime - %Finish."
"Продолжительность: %Duration"
"Содержание: %Content"
""
"Событие может быть открыто по ссылке:"
"%URL'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function EventSubject ( Params ) export

	text = NStr ("en = 'Event(%Severity): %Starting at %StartTime with duration of %Duration; %Organization; %Subject'; ro = 'Eveniment(%Severity): %Starting la %StartTime cu durata of %Duration; %Organization; %Subject'; ru = 'Событие(%Severity): %Starting в %StartTime продолжительностью %Duration; %Organization; %Subject'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function Today () export

	text = NStr ("en = 'today'; ro = 'astăzi'; ru = 'сегодня'" );
	return text;

EndFunction

&AtServer
Function Tomorrow () export

	text = NStr ("en = 'tomorrow'; ro = 'măine'; ru = 'завтра'" );
	return text;

EndFunction

&AtServer
Function CheckFillingError () export

	text = NStr ("en = 'Data filling errors detected'; ro = 'Erori de completare a datelor detectate'; ru = 'Обнаружены ошибки заполнения данных'" );
	return text;

EndFunction

&AtServer
Procedure WrongExternalLibrary ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Wrong or missing library in the %File."
"Internal library will be used instead'; ro = 'Bibliotecă greșită sau lipsă în %File."
"Se va utiliza biblioteca internă'; ru = 'Не удалось загрузить библиотеку из файла %File. Будет использована внутренняя компонента'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function CommonFieldInUse ( Params ) export

	text = NStr ("en = ""%Property can't be private because it is already used by %Owner""; ro = '%Property nu poate fi privat deoarece este deja utilizat de %Owner'; ru = 'Свойство не может быть приватным, потому что оно уже используется в %Owner'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function InteractiveCreationForbidden () export

	text = NStr ("en = 'This object cannot be created interactively'; ro = 'Acest obiect nu poate fi creat în mod interactiv'; ru = 'Этот объект не может создаваться интерактивно'" );
	return text;

EndFunction

&AtServer
Function AccessKeysNotAvailable ( Params ) export

	text = NStr ("en = 'Failed to access the access key in %Number attempts. Session will be terminated'; ro = 'Nu a reușit să acceseze cheia de acces în %Number de încercări. Sesiunea va fi terminată'; ru = 'Не удалось обратиться к ключу доступа за %Number попыток. Сессия будет завершена'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtClient
Procedure SelectFile ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "SelectFile" ) export

	text = NStr ("en = 'Please select a file'; ro = 'Vă rugăm să selectați un fișier'; ru = 'Выберите пожалуйста файл'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Procedure CannotApplyDiscount ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en = 'Can''t apply the discount %Discount. Perhaps, Items and Services tables are empty or VAT rates are incorrect';ro = 'Nu se poate aplica reducerea %Discount. Poate că tabelele Articole și Servicii sunt goale sau cotele de TVA sunt incorecte';ru = 'Не могу применить скидку %Discount. Вероятно, таблицы товаров/услуг не заполнены или неверно заданы ставки НДС'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure CannotCloseDiscount ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en = 'The registered discount is exceeded by %Amount';ro = 'Reducerea înregistrată este depășită cu %Amount';ru = 'Превышена зарегистрированная скидка на %Amount'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function AccountCurrencyError () export

	return NStr ( "en='The currency of the Bank statement does not match the currency of the Bank account'; ro='Valuta extrasului bancar nu se potrivește cu valuta contului bancar'; ru='Валюта банковской выписки не совпадает с валютой банковского счета'" );

EndFunction

&AtServer
Procedure SymbolCountInPaymentContentError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Number of symbols in text of payment exceeds 210'; ro='Numărul de caractere din textul de plată depășește 210'; ru='Количество символов в тексте платежа превышает 210'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RowCountInPaymentContentError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Number of lines in payment destination exceeds 5'; ro='Numărul de rînduri din destinație de plată depășește 5'; ru='Количество строк в назначении платежа превышает 5'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function NationalBankHostNotSet () export

	return NStr ( "en='National Bank host not set'; ro='Site-ul băncii naționale nu este setat'; ru='Хост национального банка не установлен'" );

EndFunction

&AtClient
Procedure InvalidDateEnd ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Getting courses of currencies is possible only till current date. Change date end of loading period.'; ro='Obținerea de cursuri de valute este posibilă numai până la data curentă. Modificați sfârșitul perioadei de încărcare.'; ru='Получение курсов валют возможно только до текущей даты. Измените дату конца периода загрузки.'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ProxyServerNotSet ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Proxy server not filled'; ro='Serverul proxy nu este completat'; ru='Прокси сервер не заполнен'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function InternetConnectionFailed () export

	return NStr ( "en='Unsuccessful trial of connection.'; ro='Procesul nereușit al conexiunii.'; ru='Неудачная попытка соединения.'" );

EndFunction

&AtServer
Function InternetConnectionFailedProxy () export

	return NStr ( "en='Unsuccessful trial of connection. Incorect user name and/or password'; ro='Procesul nereușit al conexiunii. Nume de utilizator și / sau parolă incorecte'; ru='Неудачная попытка соединения. Неверные имя пользователя и/или пароль.'" );

EndFunction

&AtServer
Function LoadingRatesOnDate ( Params ) export

	text = NStr ( "en='Getting rates at date %Date'; ro='Obținerea de cursuri la data %Date'; ru='Получение курсов на дату %Date'" );
    return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function NoInformationRates ( Params ) export

	text = NStr ( "en='Information about rates on date %Date is missing'; ro='Începând cu data de %Date, nu există informații despre cursuri.'; ru='На дату %Date информация о курсах отсутствует.'" );
    return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function ErrorGettingInformationRates ( Params ) export

	text = NStr ( "en='On date %Date server returned error ""%Error"" '; ro='Pentru data %Date, serverul a întors eroarea ""%Error""'; ru='На дату %Date cервер возвратил ошибку ""%Error""'" );
    return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Function NotFilledFileRates () export

	return NStr ( "en='Transfer file not filled'; ro='Fișierul de date nu este completat.'; ru='Файл передачи данных не заполнен.'" );

EndFunction

&AtServer
Procedure WrongFileFormatRates ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Incorrect format of received file. Loading rates is interrupted.'; ro='Formatul de fișier primit este nevalid. Încărcarea cursurilor a fost întreruptă.'; ru='Неверный формат полученного файла. Загрузка курсов прервана.'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure CurrencyNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Currency ""%Description-%FullDescription"" with code ""%Code"" is not found in file, received from server. Check accordance of currency coed to international classifier of currencies.'; ro='Valuta ""%Description-%FullDescription"" cu codul ""%Code"" nu a fost găsită în fișierul primit de la server. Verificați dacă codul de monedă corespunde clasificatorului valutar internațional.'; ru='Валюта ""%Description-%FullDescription"" с кодом ""%Code"" не найдена в файле, полученном с сервера. Проверьте соответствие кода валюты международному классификатору валют.'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure WrongCurrencyCode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Code of currency ""%Description-%FullDescription"" differs from file, received from server. Code in catalog ""%Code"", code in file ""%FileCode"".'; ro='Codul valutei ""%Description-%FullDescription"" este citit din codul de valută din fișierul primit de la server. Codul din catalogul ""%Code"", codul din fișierul ""%FileCode"".'; ru='Код валюты ""%Description-%FullDescription"" отчичается от кода валюты в файле, полученном с сервера. Код в справочнике ""%Code"", код в файле ""%FileCode"".'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EndOfExchageRatesLoad ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Loading currencies rates complete'; ro='Încărcarea cursurilor valutare este completă'; ru='Загрузки курсов завершена'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure CheckCurrency ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Select please a currency'; ro='Selectați vă rugăm o valută'; ru='Отметьте пожалуйста загружаемые валюты'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

Function CommonError ( Params ) export

	text = NStr ( "en='Error: %Error'; ro='Eroare: %Error'; ru='Ошибка: %Error'" );
	return Output.FormatStr ( text, Params );

EndFunction

&AtServer
Procedure ResidualValueIgnored ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Actual cost of unit LVI ""%Item %Details"" is less than the limit value of LVI. Actual value
				|%Price, the limit of value %CostLimit. This residual value %ResidualValue is ignored. LVI is fully written off to costs.'; ro='Valoarea reală a unității OMVSD ""%Item %Details"" este mai mică decât limita de cost a OMVSD. Costul real 
				|%Price, limita costurilor %CostLimit. Valoarea reziduală specificată de %ResidualValue este ignorată. OMVSD este pe deplin casat la cheltuiei.'; ru='Фактическая стоимость единицы МБП ""%Item %Details"" меньше предела стоимости МБП. 
				|Фактическая стоимость %Price, предел стоимости %CostLimit. Указанная остаточная стоимость %ResidualValue проигнорирована. МБП полностью списан на затраты.'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PriceIsLessThenResidualValue ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Pointing residual value of unit LVI ""%Item %Details"" is more than actual cost. Residual value of unit %ResidualValue, actual cost %Price'; ro='Valoarea reziduală indicată a unității OMVSD ""%Item %Details"" este mai mare decât valoarea reală. Valoare reziduală a unității %ResidualValue, Cost real %Price'; ru='Указанная остаточная стоимость единицы МБП ""%Item %Details"" больше фактической стоимости. Остаточная стоимость единицы %ResidualValue, фактическая стоимость %Price'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PrintFormsTabularSectionIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Tabular part of print form is empty. Print form does not contain data'; ro='Tabelul formularului tipărit este gol. Formularul de tipărire nu conține date'; ru='Табличная часть печатной формы пустая. Печатная форма не содержит данных'" );
    Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure CustomsGroupAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='It is forbidden to duplicate customs groups, customs group: %CustomsGroup, was deleted'; ro='Duplicarea grupurilor vamale nu este permisă, grupul vamal introdus: %CustomsGroup a fost șters.'; ru='Не допускается дублирование таможенных групп, введенная таможенная группа: %CustomsGroup была удалена.'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure ChargeAlreadyExist ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='It is forbidden to duplicate customs charges, customs charge: %Charge, was deleted'; ro='Dublarea plăților vamale nu este permisă, plata vamală introdusă: %Charge a fost eliminată.'; ru='Не допускается дублирование таможенных выплат, введенная таможенная выплата: %Charge была удалена.'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure DoubleCustomsCharges ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Duplicated сharge'; ro='Plata duplicată'; ru='Дублируется выплата'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure OnlyImportAllowed ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The Import flag should be installed in %VendorInvoice'; ro='Este obligatoriu să bifați ""Import"" în %VendorInvoice'; ru='В %VendorInvoice не установлен признак операции импорта'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure FillingDataNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Filling data was not found'; ro='Nu au fost găsite date pentru completare'; ru='Данные для заполнения не найдены'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PeriodYearError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Period is incorrect. The period should be within one year'; ro='Perioada specificată incorect. Perioada trebuie să fie inclusa într-un an'; ru='Некорректно задан период. Период должен быть в рамках одного года'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure CompanyEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Company not filled'; ro='Întreprinderea nu este completată'; ru='Компания не заполнена'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure InvoicePrinted ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Documents are printed, the further change of the document is impossible '; ro='Documentele sunt imprimate, modificarea ulterioară a documentului este imposibilă'; ru='Документы выписаны, дальнейшее изменение документа невозможно'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function CloseAdvances () export

	text = NStr ( "en='Closing advances'; ro='Închiderea avansurilor'; ru='Закрытие авансов'" );
	return text;

EndFunction

&AtServer
Function ReceiptAdvances () export

	text = NStr ( "en='Receipt advances'; ro='Primirea avansurilor'; ru='Получение авансов'" );
	return text;

EndFunction

&AtServer
Function CloseAdvancesVAT () export

	text = NStr ( "en='VAT on closing advances'; ro='TVA-ul pentru închiderea avansurilor'; ru='НДС при закрытии авансов'" );
	return text;

EndFunction

&AtServer
Function ReceiptAdvancesVAT () export

	text = NStr ( "en='VAT on receipt advances'; ro='TVA la primirea avansurilor'; ru='НДС при получении авансов'" );
	return text;

EndFunction

&AtServer
Function CloseAdvancesGiven () export

	text = NStr ( "en='Closing given advances'; ro='Închiderea avansurilor eliberate'; ru='Закрытие выданных авансов'" );
	return text;

EndFunction

&AtServer
Function GivenAdvances () export

	text = NStr ( "en='Given advances'; ro='Avansuri emise'; ru='Выданные авансы'" );
	return text;

EndFunction

&AtServer
Procedure EmptyUploadList ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Unload list is empty. Before operation please mark with ""Upload"" necessary documents'; ro='Lista de descărcare este goală. Înainte de operație, marcați documentele necesare cu bifa ""Descărcați""'; ru='Список для выгрузки пуст. Перед операцией, отметьте флажками необходимые документы'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure EmptyLoadList ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Load list is empty. Before operation please mark with ""Load"" necessary documents'; ro = 'Lista de încărcare este goală. Înainte de operație, marcați documentele necesare cu bifa ""Încărcați""'; ru = 'Список для загрузки пуст. Перед операцией, отметьте флажками необходимые документы'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UndefinedCodeFiscal1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Code Fiscal is empty'; ro = 'Codul fiscal nu este completat'; ru = 'Не заполнен фискальный код'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UndefinedCodeFiscal2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = '%Row: Code Fiscal is empty'; ro = '%Row: Codul fiscal nu este completat'; ru = '%Row: Не заполнен фискальный код'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UndefinedAccountNumber ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = '%Row: Bank Account Number is empty'; ro = '%Row: Numărul contului bancar nu este completat'; ru = '%Row: Не указан номер банковского счета'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure DataSuccessfullyLoaded ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DataSuccessfullyLoaded" ) export

	text = NStr ( "en='Data loaded successfully'; ro='Datele au fost încărcate cu succes'; ru='Данные успешно загружены'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function UnableToSaveData ( Params = undefined ) export

	s = NStr ( "en='Unable to save data. Description of error: %Error'; ro='Salvarea datelor nu a reușit. Descrierea erorii: %Error'; ru='Не удалось сохранить данные. Описание ошибки: %Error'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function DBFErrorCreate ( Params = undefined ) export

	s = NStr ( "en='Unable to create DBF file. Description of error: %Error'; ro='Fișierul DBF nu a putut fi creat: %Error'; ru='Не удалось создать DBF файл: %Error'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function UnableToOpenFile ( Params = undefined ) export

	s = NStr ( "en='Unable to open file for reading data!
				|Description of error: %Error'; ro='Nu s-a putut deschide fișierul pentru citirea datelor!
				|Descrierea erorii: %Error '; ru='Не удалось отрыть файл для чтения данных!
				|Описание ошибки: %Error'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function UnableToReadFile ( Params = undefined ) export

	s = NStr ( "en='Unable to read file!
				|Description of error: %Error'; ro='Imposibil de citit datele!
				|Descrierea erorii: %Error'; ru='Не удалось прочитать данные!
				|Описание ошибки: %Error'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function DBFFileNotOpened () export

	return NStr ( "en='DBF-file of data loading, is not opened.
				|Loading is interrupted!'; ro='Fișierul DBF de încărcare a datelor nu este deschis.
				|Încărcarea este întreruptă!'; ru='DBF-файл загрузки данных, не открыт.
				|Загрузка прервана!'" );

EndFunction

&AtServer
Function DBFInvalidStructure () export

	return NStr ( "en='Invalid structure of DBF-file.
				|Loading is interrupted!'; ro='Structura câmpurilor pentru fișierul DBF pentru încărcarea datelor nu este corectă.
				|Descărcare întreruptă! '; ru='Неправильная структура полей DBF-файла загрузки данных.
				|Загрузка прервана!'" );

EndFunction

&AtServer
Procedure ProducerPriceEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" )  export

	text = NStr ( "en='For socially significant item <%Item> producer price is not set'; ro='Pentru bunurile social importante <%Item> nu este specificat nici un preț de producător'; ru='Для социально значимого товара <%Item> не задана цена производителя'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure CannotCopyBankingApp ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Bank client copy is not allowed'; ro='Copierea unui client bancar nu este permisă'; ru='Копирование клиент банка не допускается'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function WrongFileFormat () export

	return NStr ( "en='Unknown file format. Perhaps the selected file is not a source for downloading Bank payments'; ro='Formatul de fișier necunoscut. Poate fișierul selectat nu este o sursă pentru importul plăților bancare'; ru='Неизвестный формат загружаемого файла. Возможно, выбранный файл не является источником для загрузки банковских платежей'" );

EndFunction

&AtServer
Function ProcessingLine ( Params = undefined ) export

	s = NStr ( "en='Processing line: %Line'; ro='Procesarea rîndului: %Linie'; ru='Обработка строки: %Line'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function DataNotFound () export

	return NStr ( "en='No documents found to download!
				|The source file may be empty'; ro='Nu s-au găsit documente de descărcat!
				|Fișierul sursă poate fi gol'; ru='Не обнаружено ни одного документа для загрузки!
				|Возможно, исходный файл пустой'" );

EndFunction

&AtServer
Procedure RowContainsError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='The line: %Line contains an error. Posibly the fiscal code of the payer and / or recipient do not match the selected company or amount or date is empty'; ro='Rîndul: %Linia conține o eroare. Eventual codul fiscal al plătitorului și / sau al destinatarului nu se potrivește cu întreprinderea selectată sau suma sau data sunt goale'; ru='Строка: %Line содержит ошибку. Возможно фискальный код плательщика и/или получателя не соответствуют выбранной компании или сумма или дата не заполнены'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function DownloadedFromClientBank () export

	return NStr ( "en='<Downloaded from Client-Bank>'; ro='<Descărcat de la Client-Bank>'; ru='<Загружено из Клиент-Банка>'" );

EndFunction

&AtServer
Function ErrorSavingBankDocument ( Params = undefined ) export

	s = NStr ( "en='Could not save the Bank document created by line #%Line
				|Error description: %Error'; ro='Nu a putut fi salvat documentul bancar creat de rîndul #%Line
				|Descrierea erorii: %Error'; ru='Не удалось сохранить документ банковской операции, созданный согласно строке №%Line.
				|Полное описание ошибки: %Error'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function ErrorPostingBankDocument ( Params = undefined ) export

	s = NStr ( "en='Could not post the Bank document created by line #%Line
				|Error description: %Error'; ro='Nu s-a putut valida documentul bancar creat prin rîndul #%Line
				|Descrierea erorii: %Error'; ru='Не удалось провести документ банковской операции, созданный согласно строке №%Line.
				|Полное описание ошибки: %Error'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function CloseEmployeeDebts () export

	text = NStr ( "en='Closing employee debts'; ro='Închiderea creanțelor contabile ale persoanelor responsabile'; ru='Закрытие дебиторской задолженности подотчетных лиц'" );
	return text;

EndFunction

&AtServer
Function FormationEmployeeDebts () export

	text = NStr ( "en='Formation employee debts'; ro='Formarea obligațiilor față de persoanele responsabile'; ru='Формирование обязательства подотчетным лицам'" );
	return text;

EndFunction

&AtServer
Function ItemsNotFoundByCustomsGroup ( Params ) export

	s = NStr ( "en='By customs group: %CustomsGroup and vendor invoice: %Invoice, filling data are not found'; ro='În funcție de grupul vamal: %CustomsGroup și intrare: %Invoice, nu au fost găsite date pentru completare'; ru='По таможенной группе: %CustomsGroup и поступлению: %Invoice, данные для заполнения не найдены'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Procedure LVIBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='Not enough %Quantity LVI %Item by department %Department and employee %Employee. In stock is listed %QuantityBalance'; ro='Nu este suficient %Quantity de OMVSD %Item pentru subdiviziunea %Department și angajatul %Employee. În balanța sunt %QuantityBalance'; ru='Не хватает %Quantity МБП %Item. В остатках числится %QuantityBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

Function Transfer () export

	return "Non livrare";

EndFunction

&AtServer
Function RangeFinished ( Params ) export

	s = NStr ( "en='There is no available number in the %Range range. Please, use another range';ro='Nu există număr disponibil în diapazonul %Range. Vă rugăm să folosiți un alt diapazon';ru='Больше нет свободных номеров в диапазоне %Range. Выберите другой диапазон пожалуйста'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function RangeInactive ( Params ) export

	s = NStr ("en='The range %Range is not active yet';ro='Diapazonul %Range nu este încă activat';ru='Диапазон %Range еще не активирован'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function RangeError ( Params ) export

	s = NStr ("en='The %Series %Number does not belong to the range %Range';ro='%Series %Number nu aparține diapazonului %Range';ru='%Series %Number не принадлежит диапазону %Range'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function RangeJumpstart ( Params ) export

	s = NStr ("en='The %Number is out of order of range %Range';ro='%Number este în afara ordinii diapazonului %Range';ru='%Number идет не по порядку согласно диапазона %Range'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Procedure FormExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'The number is not unique'; ro = 'Numărul nu este unic'; ru = 'Номер не уникальный'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure FormCostBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='There is no lot for %Item form in warehouse %Warehouse for auto-writing off';ro='La depozit %Warehouse nu sunt in stoc formulare %Item pentru casarea conform lotului';ru='На складе %Warehouse нет бланков %Item для автосписания по партионному учету'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure FormBalanceError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='There is no %Item form in warehouse %Warehouse for auto-writing off';ro='La depozit %Warehouse nu sunt în stoc formulare %Item pentru casare';ru='На складе %Warehouse нет бланков %Item для автосписания'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure FormNotReady ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='Printing of the form %Ref is not allowed in the current status';ro='În stare curentă formularul %Ref nu poate fi imprimat';ru='В текущем статусе форма %Ref не может быть распечатана'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RangeIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='Range is not defined';ro='Diapazonul nu este definit';ru='Не задан диапазон'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RangeNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='The range %Range is not registered in the warehouse %Warehouse';ro='La depozit %Warehouse nu este inregistrat diapazonul %Range';ru='На складе %Warehouse не числится диапазон %Range'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RangeIsBroken ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='It is not allowed to transfer or write off %Quantity elements from range %Range partially. The number of elements listed for %Warehouse is %Balance';ro='Nu este permisă transferul sau casarea parțială %Quantity a formularelor din depozit %Warehouse. În diapaxonul %Range sunt enumerate %Balance elemente';ru='Нельзя частично переместить или списать %Quantity элементов со склада %Warehouse. В диапазоне %Range числится %Balance элементов'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RangeIncomplete ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='The size of the range does not equal to quantity of receiving forms';ro='Dimensiunea diapazonului nu corespunde numărului de formulare primite';ru='Размер диапазона не совпадает с количеством поступающих бланков'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure FormInUse ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "FormInUse" ) export

	text = NStr ("en='The form is already in use."
"The flag can’t be turned off';ro='Formularul este deja utilizat în documentele primare,"
"semnul nu poate fi dezactivat';ru='Бланк уже используется в первичных документах,"
"признак не может быть отключен'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

&AtServer
Function ItemIsNotForm ( Params ) export

	s = NStr ("en='%Item is not a Form regulated by government. The Form flag can be installed in the object form of the Item catalog';ro='% Item nu este un formular cu regim special. Semnul FRS poate fi instalat în elementul nomenclatorului.';ru='%Item не является БСО. Признак БСО задается в форме элемента справочника Номенклатура'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Procedure RangeAlreadyInUse ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='The range %Range has already been received earlier';ro='Diapazonul %Range a fost deja primit mai devreme';ru='Диапазон %Range уже был ранее оприходован'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RangeDoubled ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='The range has been defined many time in the tabular section';ro='Diapazonul este duplicat în partea tabelară';ru='Диапазон дублируется в табличной части'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RangeIncorrect ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='The range is incorrect';ro='Diapazonul este incorect';ru='Неверно задан диапазон'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function DocumentCannotBeCopied () export

	text = NStr ("en='Document of this type can’t be copied';ro='Documentul de acest tip nu poate fi copiat';ru='Копирование документов данного типа не допускается'" );
	return text;

EndFunction

&AtServer
Procedure RangeSplitError1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='There is no forms to split the range into two parts';ro='Numărul rămas de formulare în diapazon nu permite divizarea acestuia în două părți';ru='Оставшееся кол-во бланков в диапазоне не позволяет разбить его на две части'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RangeSplitError2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='The entered number is overlapping an acceptable range for splitting operation.';ro='Numărul introdus depășește diapazonul acceptabil pentru operația de divizare.';ru='Введенный номер выходит за границы диапазона возможности его разделения на две части'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure RangeSplitError3 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='Range isn’t active';ro='Diapazonul nu este activ';ru='Диапазон не активен'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function SplitRangeMemo () export

	text = NStr ("en='Automatically created by Split Range document';ro='Creat automat de documentul Divizarea diapazonului';ru='Создан автоматически на основании документа Разделение диапазона'" );
	return text;

EndFunction

&AtClient
Procedure CloseDocumentConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CloseDocumentConfirmation" ) export

	text = NStr ("en='Would you like to close the document?';ro='Doriți să închideți documentul?';ru='Закрыть документ?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );

EndProcedure

&AtClient
Procedure SplitRangeConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SplitRangeConfirmation" ) export

	text = NStr ("en='Would you like to split the range?"
"Warning: this operation is not reversible';ro='Doriți să divizați intervalul?"
"Atenție: operația este ireversibilă.';ru='Произвести разбиение диапазона?"
"Внимание: операция необратима'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure RangeAlreadyEnrolled ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en='The range has already been registered earlier';ro='Diapazonul a fost deja înregistrat anterior';ru='Диапазон уже был ранее зарегистрирован'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function UndefinedRangeLocation ( Params = undefined ) export

	s = NStr ("en='A location of range %Range is undefined."
"Probably, this range has not been enrolled yet on the document date';ro='Amplasarea diapazonului %Range este nedefinită."
"Probabil, acest diapazon încă nu a fost înregistrat la data introducerii documentului';ru='Не удалось получить данные о местонахождении диапазона %Range."
"Возможно, он еще не был зарегистрирован на дату ввода документа'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtClient
Procedure WorkTimeOnTwoDays ( Module, CallbackParams = undefined, Params = undefined, ProcName = "WorkTimeOnTwoDays" ) export
	
	text = NStr ( "en = 'Would you like to split the period?'; ro = 'Doriți să împărțiți perioada?'; ru = 'Хотите разделить период?'" );
	title = NStr ( "ru = ''; en = ''" );
	Output.OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtServer
Procedure IncorrectDateOpening ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ("en = 'The document period is incorrect: the opening date of the waybill cannot be later than the closing date'; ro = 'Perioada documentului este setată incorect: data deschiderii foii de parcurs nu poate fi mai târziu de data de închidere'; ru = 'Неверно задан период документа: дата открытия путевого листа не может быть позже даты закрытия'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure WrongWaybillPeriod ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ("en = 'For the period from %DateStart to %DateEnd, for the vehicle %Car, the %Document has already been entered'; ro = 'Pentru perioada %DateStart până la %DateEnd, pentru automobilul %Car, deja este înregistrată foaia de parcurs %Document'; ru = 'За период с %DateStart по %DateEnd, для автомобиля %Car, уже введен путевой лист %Document'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure BackSideIncorrectDateStart ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ("en = 'The date of commencement of work cannot be less than the date of the document'; ro = 'Data începerii a activității nu poate fi mai mică decât data documentului'; ru = 'Дата начала работ не может быть меньше даты документа'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure BackSideIncorrectDateEnd ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ("en = 'The end date cannot be greater than the closing date of the waybill'; ro = 'Data de finalizare a activității nu poate depăși data închiderii foii de parcurs'; ru = 'Дата окончания работ не может быть больше даты закрытия путевого листа'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure WorkSequenceIncorrect ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ("en = 'Start time is later than end time. See table %Table, line %LineNumber'; ro = 'Începerea orei de activitate mai târzie decât ora de finalizare. Vedeți tabelul %Table, rândul %LineNumber'; ru = 'Время начала работ позже времени окончания. См. таблицу %Table, cтрока %LineNumber'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure CarAccountingDataError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ("en = 'The %Warehouse and/or asset %FixedAsset is already defined for the %Car. You cannot use one warehouse (or fixed asset) for different cars'; ro = 'Depozitul %Warehouse și/sau Imobilizare corporală %FixedAsset este deja setat pentru masina %Car. Nu puteți utiliza un depozit (sau imobilizări corporale) pentru diferite autovehicule.'; ru = 'Склад %Warehouse и/или Основное средство %FixedAsset уже заданы для автомобиля %Car. Нельзя использовать один склад (или основное средство) для разных автомобилей'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure WaybillWriteOffError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ("en='The waybill does not have fuel inventory data';ro='În foaie de parcurs nu sunt specificate datele privind inventarierea combustibilului';ru='В путевом листе не указаны данные по инвентаризации топлива'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Function IncomeTaxRetained ( Params = undefined ) export

	s = NStr ( "en='(impozit reţinut %Rate% = %Amount)';ro='(impozit reţinut %Rate% = %Amount)';ru='(impozit reţinut %Rate% = %Amount)'" );
	return Output.FormatStr ( s, Params );

EndFunction

&AtServer
Function AverageIncome ( Params = undefined ) export
	
	s = NStr ("en='%BaseAmount ( Base amount ) / %WorkedDays ( Actually worked days ) + %Bonuses ( ( %QuarterlyBonuses ( Quarterly bonuses ) * 1/3 + %AnnualBonuses ( Annual bonuses ) * 1/12 ) ) / %AverageDays ( Average number of working days in a month ) ) = %AverageDailyIncome';ro='%BaseAmount ( Suma de bază ) / %WorkedDays ( Zile lucrate efectiv ) + %Bonuses ( ( %QuarterlyBonuses ( Premii trimestriale ) * 1/3 + %AnnualBonuses ( Premii anuale ) * 1/12 ) ) / %AverageDays ( Numărul mediu de zile lucrătoare într-o lună ) ) = %AverageDa';ru='%BaseAmount ( Базовая сумма ) / %WorkedDays ( Фактически отработанные дни ) + %Bonuses ( ( %QuarterlyBonuses ( Квартальные премии ) * 1/3 + %AnnualBonuses ( Годовые премии ) * 1/12 ) ) / %AverageDays ( Среднее количество рабочих дней в месяце ) ) = %AverageDailyIncome'" );
	return Output.FormatStr ( s, Params );	
	
EndFunction

&AtServer
Function DailyRate ( Params = undefined ) export
	
	s = NStr ("en='%AverageDailyIncome ( Average daily income ) * %ScheduledDays ( Scheduled working days ) / ( %CalendarDays ( Calendar days ) - %BaseHolidays ( Holidays ) ) = %DailyRate';ro='%AverageDailyIncome ( Venitul mediu zilnic ) * %ScheduledDays ( Zile lucrate programate ) / ( %CalendarDays ( Zile calendaristice ) - %BaseHolidays ( Sărbătoare ) ) = %DailyRate';ru='%AverageDailyIncome ( Средний доход в день ) * %ScheduledDays ( Рабочие дни по графику ) / ( %CalendarDays ( Календарные дни ) - %BaseHolidays ( Праздничные дни ) ) = %DailyRate'" );
	return Output.FormatStr ( s, Params );	
	
EndFunction

&AtServer
Function SicknessResult ( Params = undefined ) export
	
	s = NStr ("en='%DailyRate ( Daily estimated sick leave rate ) * %SickDays ( Calendar days of sickness ) * %SeniorityAmendment ( Payout ratio ) = %Result';ro='%DailyRate ( Indiciu calculabil zilnic al concediului medical ) * %SickDays ( Zile calendaristice ale concediului medical ) * %SeniorityAmendment ( Coeficientul de plată ) = %Result';ru='%DailyRate ( Дневной расчетный показатель больничных ) * %SickDays ( Календарные дни болезни ) * %SeniorityAmendment ( Коэффициент выплаты ) = %Result'" );
	return Output.FormatStr ( s, Params );	
	
EndFunction

&AtServer
Function VacationsResult ( Params = undefined ) export
	
	s = NStr ("en='%DailyRate ( Daily estimated vacation rate ) * %VacationDays ( Vacation calendar days minus ( only ) holiday ) = %Result';ro='%DailyRate ( Indiciu calculabil zilnic al concediului de odihnă ) * %VacationDays ( Zile calendaristice ale concediului de odihnă cu excepția ( doar ) zilele de odihnă ) = %Result';ru='%DailyRate ( Дневной расчетный показатель отпускных ) * %VacationDays ( Календарные дни отпуска за минусом ( только ) праздничных ) = %Result'" );
	return Output.FormatStr ( s, Params );	
	
EndFunction

&AtServer
Procedure EmployeeAlreadySick ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ("en='Sick leave already exists in %Ref';ro='Concediul medical există deja în %Ref';ru='Больничный по сотруднику уже был введен документом %Ref'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure EmployeeAlreadyOnVacation ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ("en='Vacation for %Employee already exists in %Ref';ro='Concediul de odihnă pentru %Employee există deja în %Ref';ru='Отпуск по сотруднику %Employee уже был введен документом %Ref'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure VendorReturnDifferentPackages ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Packaging on return (%Package) is different from packaging on receipt (%PackageReceipt)'; ro = 'Ambalajul de retur (%Package) diferă de ambalajul de primire (%PackageReceipt)'; ru = 'Упаковка при возврате (%Package) отличается от упаковки при поступлении (%PackageReceipt)'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure VendorReturnExcessQuantity ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'The quantity %Quantity of item %Item is insufficient. The amount of stock listed for %VendorInvoice is %QuantityBalance'; ro = 'Nu este suficient %Quantity de marfă %Item. Conform documentului %VendorInvoice, sunt disponibile %QuantityBalance.'; ru = 'Не хватает %Quantity товара %Item. По документу %VendorInvoice доступно %QuantityBalance'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

Procedure NoItemsToReturn ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'There are no items to return in the %Document'; ro = 'În documentul %Document nu există bunuri pentru returnare'; ru = 'В документе %Document нет товаров для возврата'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ChoiceInvoice () export

	return NStr ("en='Choice Invoice';ro='Selectați factura de vânzare';ru='Выбрать реализацию'" );

EndFunction

&AtServer
Function ChooseVendorInvoice () export

	return NStr ("en='Choose Vendor Invoice';ro='Selectați factură de cumpărare';ru='Выбрать поступление'" );

EndFunction

&AtClient
Procedure WrongVATUse ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Application of VAT in the selected document is different from the current'; ro = 'Aplicarea TVA pentru documentul selectat diferă de cea actuală'; ru = 'Применение НДС у выбранного документа отличается от текущего'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function DataInputErrorsFound () export

	text = NStr ( "en='Data input errors found!'; ro='Erori la introducerea datelor'; ru='Обнаружены ошибки ввода данных!'" );
	return text;

EndFunction

&AtClient
Procedure LoadPaymentsConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "LoadPaymentsConfirmation" ) export

	text = NStr ("en = 'Would you like to load the file?'; ro = 'Doriți să încărcați fișierul?'; ru = 'Загрузить файл?'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure LoadPaymentsFirst ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'Payments’ file has not been uploaded yet'; ro = 'Fișierul de plăți nu a fost încărcat încă'; ru = 'Не загружен файл с платежами'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure PaymentsNotSelected ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'No payments selected for loading'; ro = 'Nu au fost selectate plăți pentru încărcare'; ru = 'Не выбраны платежи для загрузки'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure UpdateByCodeFiscal ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UpdateByCodeFiscal" ) export

	text = NStr ("en = 'Organization data will be updated. Would you like to continue?'; ro = 'Datele terțului vor fi actualizate, doriți să continuați?'; ru = 'Данные контрагента будут обновлены, продолжить?'" );
	title = NStr ( "en = ''; ro= ''; ru= ''" );
	Output.OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtClient
Procedure UpdateByWrongCodeFiscal ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UpdateByCodeFiscal" ) export

	text = NStr ("en = 'An organization with the specified fiscal code already exists in the system. Would you like to continue?'; ro = 'O organizație cu codul fiscal specificat există deja în sistem. Doriți să сontinuați?'; ru = 'В системе уже существет организация с указанным фискальным кодом. Продолжить?'" );
	title = NStr ( "en = ''; ro= ''; ru= ''" );
	Output.OpenQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );

EndProcedure

&AtServer
Procedure OrganizationNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = 'There is no data for this fiscal code in the national registry'; ro = 'Nu există date pentru acest cod fiscal în registrul național'; ru = 'По этому фискальному коду в национальном реестре данных нет'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure WeakInvoice ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ("en = '%Invoice does not have registered Tax Invoice'; ro = '%Invoice nu are o factură fiscală înregistrată'; ru = 'Для %Invoice нет зарегистрированной налоговой накладной'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ReconciliationPeriod ( Params, Language = undefined ) export
	
	s = NStr ("en='from %DateStart till %DateEnd';ro='de la %DateStart până la %DateEnd';ru='с %DateStart по %DateEnd'", Language );
	return Output.FormatStr ( s, Params );	
	
EndFunction

&AtServer
Function ReconciliationPeriodFrom ( Params, Language = undefined ) export
	
	s = NStr ("en='starting with %DateStart';ro='începând cu %DateStart';ru='начиная с %DateStart'", Language );
	return Output.FormatStr ( s, Params );	
	
EndFunction

&AtServer
Function ReconciliationPeriodTo ( Params, Language = undefined ) export
	
	
	s = NStr ("en='at %DateEnd';ro='până la %DateEnd';ru='по %DateEnd'", Language );	
	return Output.FormatStr ( s, Params );	
	
EndFunction

&AtServer
Function ReconciliationPeriodAll ( Params, Language = undefined ) export
	
	s = NStr ("en='whole period';ro='toată perioada';ru='весь период'", Language );
	return Output.FormatStr ( s, Params );
	
EndFunction

&AtServer
Function ReconciliationInformation ( Params = undefined, Language = undefined ) export
	
	s = NStr ( "en = 'We, undersigned, %Company, on the one hand, and %Organization, on the other hand,
	|amounted a real act of reconciliation, that the state of mutual settlements according to accounting data is the following:';ro = 'Noi, subsemnaţii, %Company, pe de o parte, şi %Organization, pe de altă parte,
	|am efectuat verificarea decontărilor reciproce:';ru = 'Мы, нижеподписавшиеся, %Company, с одной стороны, и %Organization, с другой стороны,
	|составили настоящий акт сверки в том, что состояние взаимных расчетов по данным учета следующее:'", Language );
	return Output.FormatStr ( s, Params );
		
EndFunction

&AtServer
Function ReconciliationTotalPlus ( Params, Language = undefined ) export
	
	s = NStr ( "en = 'Total, debt of %Organization before %Company is %Amount.'
	|;ro = 'Total, datorie %Organization la %Company este %Amount.';
	|ru = 'Итого, долг %Organization перед %Company составляет %Amount.'", Language );
	return Output.FormatStr ( s, Params ); 
	
EndFunction

&AtServer
Function ReconciliationTotalMinus ( Params, Language = undefined ) export
	
	s = NStr ( "en = 'Total, debt of %Company before %Organization is %Amount.'
	|;ro = 'Total, datorie %Company la %Organization este %Amount.'
	|;ru = 'Итого, долг %Company перед %Organization составляет %Amount.'", Language );
	Return Output.FormatStr ( s, Params ); 
	
EndFunction

&AtServer
Function ReconciliationTotalZero ( Params, Language = undefined ) export
	
	
	s = NStr ( "en = 'In currency of calculations %Currency mutual settlements are closed.'
	|;ro = 'În valuta %Currency decontările sunt închise.'
	|;ru = 'В валюте расчетов %Currency взаиморасчеты закрыты.'", Language );
	return Output.FormatStr ( s, Params ); 
	
EndFunction

&AtServer
Function ReconciliationContract ( Params = undefined, Language = undefined ) export
	
	s = NStr ( "ru = 'по договору %Contract'; ro = 'prin contractul %Contract'; en = 'by contract %Contract'", Language );
	return Output.FormatStr ( s, Params ); 
	
EndFunction

&AtServer
Function PrintVATInfo0 ( Language ) export
	
	return NStr ( "ru = 'НДС не применяется'; ro = 'TVA nu se aplică'; en = 'VAT Not Applicable'", Language );
	
EndFunction

&AtServer
Function PrintVATInfo1 ( Language ) export
	
	return NStr ( "ru = 'НДС включен в цену'; ro = 'TVA inclus in preț'; en = 'VAT Included in Price'", Language );
	
EndFunction

&AtServer
Function PrintVATInfo2 ( Language ) export
	
	return NStr ( "ru = 'НДС не включен в цену'; ro = 'TVA exclus din preț'; en = 'VAT Excluded from Price'", Language );
	
EndFunction

&AtServer
Function UndefinedFilesFolder () export

	text = NStr ( "en = 'The folder for storing uploaded files is not set, contact your system administrator to resolve the situation. This setting is defined in menu Settings / System / Folder of Object''s Service Files';ro = 'Dosarul pentru stocarea fișierelor încărcate nu este setat, contactați administratorul de sistem pentru a rezolva situația. Această setare este definită în meniul Settings / System / Folder of Object''s Service Files (Setări / Sistem / Dosar de fișiere de serviciu)';ru = 'Не задана папка для хранения загружаемых файлов, обратитесь в системному администратору для разрешения ситуации. Настройка пути выполняется в меню Настройки / Система / Папка служебных файлов объектов'" );
	return text;

EndFunction

&AtClient
Procedure SelectFilesFolder ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "SelectFilesFolder" ) export

	text = NStr ("en = 'Please specify a folder for storing uploaded files';ro = 'Vă rugăm să specificați un folder pentru stocarea fișierelor încărcate';ru = 'Задайте пожалуйста путь к папке, где будут храниться загружаемые в систему файлы'" );
	title = NStr ( "en=''; ro=''; ru=''" );
	Output.OpenMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );

EndProcedure

Function SalaryExportNotSupported () export

	text = NStr ( "en = 'Payroll data export is not supported for this bank';ro = 'Exportul de salarii nu este acceptat pentru această bancă';ru = 'Для данного банка экспорт данных по заработной плате не поддерживается'" );
	return text;

EndFunction

&AtServer
Function BaseNotPosted () export

	text = NStr ( "en = 'Base document should be posted';ro = 'Documentul de bază ar trebui să fie înregistrat';ru = 'Документ-основание должен быть проведен'" );
	return text;

EndFunction

&AtServer
Function LinuxNotSupported () export

	text = NStr ( "en = 'This operation is not currently supported on the Linux operating system';ro = 'Această operațiune nu este acceptată în prezent pe sistemul de operare Linux';ru = 'В настоящий момент, в операционной системе Linux, эта операция не поддерживается'" );
	return text;

EndFunction

&AtServer
Procedure AdditionalCompensationBroken ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en = 'The additional compensation is not found in the calculations';ro = 'Compensația suplimentară nu se regăsește în calcule';ru = 'Дополнительное начисление не отражено в расчетах'" );
	Output.PutMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ChangeDisconnectedDocumentError () export

	text = NStr ( "en = 'This document is disabled and cannot change its status';ro = 'Acest document este dezactivat și nu își poate schimba statutul';ru = 'Этот документ отключен и не может изменить свой статус'" );
	return text;

EndFunction

&AtServer
Function GevernmentInvoiceRecord () export

	text = NStr ( "en = 'A tax invoice cannot be issued for a government entity';ro = 'Nu se poate emite o factură fiscală pentru o entitate guvernamentală';ru = 'Налоговая накладная не может быть выписана для государственной организации'" );
	return text;

EndFunction
