// Please do not use NStr () function in complex expressions!
//
// The following variant is incorrect:
//	text = "<" + NStr ( "en='test'" ) + ">";
//	return text;
//
// The following is incorrect:
//	text = NStr ( "en='test'" );
//	return "<" + text + ">";

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
