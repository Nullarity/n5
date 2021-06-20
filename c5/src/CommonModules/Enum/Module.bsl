#region Minutes

Function Minutes1 () export
	
	return 60;
	
EndFunction 

Function Minutes15 () export
	
	return 900;
	
EndFunction 

Function Minutes30 () export
	
	return 1800;
	
EndFunction 

#endregion

#region Hours

Function Hours1 () export
	
	return 3600;
	
EndFunction 

#endregion

#region Messages

&AtClient
Function MessageUserTaskUpdated () export
	
	return "2";
	
EndFunction 

&AtClient
Function MessageUserGroupCreated () export
	
	return "13";
	
EndFunction 

&AtClient
Function MessageUserRightsChanged () export
	
	return "14";
	
EndFunction 

&AtClient
Function MessageUserGroupModified () export
	
	return "15";
	
EndFunction 

&AtClient
Function MessageUserIsSaved () export
	
	return "40";
	
EndFunction 

&AtClient
Function MessageCommandSaved () export
	
	return "MessageCommandSaved";
	
EndFunction 

&AtClient
Function MessageTimeEntryUpdated () export
	
	return "1";
	
EndFunction 

&AtClient
Function MessageProjectChanged () export
	
	return "MessageProjectChanged";
	
EndFunction 

&AtClient
Function MessageCalendarAppearanceChanged () export
	
	return "MessageCalendarAppearanceChanged";
	
EndFunction 

&AtClient
Function MessageScheduleChanged () export
	
	return "MessageScheduleChanged";
	
EndFunction 

&AtClient
Function MessageMailLabelChanged () export
	
	return "3";
	
EndFunction 

&AtClient
Function MessageNewMail () export
	
	return "4";
	
EndFunction 

&AtClient
Function MessageEmailIsRead () export
	
	return "5";
	
EndFunction 

&AtClient
Function MessageMailBoxChanged () export
	
	return "6";
	
EndFunction 

&AtClient
Function MessageMailLabelWasAttached () export
	
	return "7";
	
EndFunction 

&AtClient
Function MessageEmailDeleted () export
	
	return "8";
	
EndFunction 

&AtClient
Function MessageQuoteCanceled () export
	
	return "9";
	
EndFunction 

&AtClient
Function MessageSalesOrderIsSaved () export
	
	return "10";
	
EndFunction 

&AtClient
Function MessageShipmentIsSaved () export
	
	return "11";
	
EndFunction 

&AtClient
Function MessageBarcodeScanned () export
	
	return "12";
	
EndFunction 

&AtClient
Function MessagePurchaseOrderIsSaved () export
	
	return "20";
	
EndFunction 

&AtClient
Function MessageInternalOrderIsSaved () export
	
	return "30";
	
EndFunction 

&AtClient
Function MessageInvoiceIsSaved () export
	
	return "40";
	
EndFunction 

&AtClient
Function MessageVendorInvoiceIsSaved () export
	
	return "50";
	
EndFunction 

&AtClient
Function MessageBillIsSaved () export
	
	return "60";
	
EndFunction 

&AtClient
Function MessageVendorBillIsSaved () export
	
	return "70";
	
EndFunction 

&AtClient
Function MessagePaymentIsSaved () export
	
	return "80";
	
EndFunction 

&AtClient
Function MessageVendorPaymentIsSaved () export
	
	return "90";
	
EndFunction 

&AtClient
Function MessageProductionOrderIsSaved () export
	
	return "100";
	
EndFunction 

&AtClient
Function MessageProductionIsSaved () export
	
	return "110";
	
EndFunction 

&AtClient
Function MessageMeetingIsSaved () export
	
	return "120";
	
EndFunction 

&AtClient
Function MessageRoomIsSaved () export
	
	return "130";
	
EndFunction 

&AtClient
Function MessageItemsPurchaseIsSaved () export
	
	return "140";
	
EndFunction

&AtClient
Function MessageServicesPurchaseIsSaved () export
	
	return "150";
	
EndFunction

&AtClient
Function MessageVendorReturnIsSaved () export
	
	return "160";
	
EndFunction

&AtClient
Function MessageVendorRefundIsSaved () export
	
	return "170";
	
EndFunction

&AtClient
Function MessageReturnIsSaved () export
	
	return "180";
	
EndFunction

&AtClient
Function MessageRefundIsSaved () export
	
	return "190";
	
EndFunction

&AtClient
Function MessageBankingAppLoaded () export
	
	return "200";
	
EndFunction

&AtClient
Function MessageBankingAppUnloaded () export
	
	return "210";
	
EndFunction

&AtClient
Function MessageInvoicesExchnage () export
	
	return "220";
	
EndFunction

&AtClient
Function MessageEventIsSaved () export
	
	return "230";
	
EndFunction 

#endregion

#region DocumentCommands

Function DocumentCommandsPublish () export
	
	return 2;
	
EndFunction 

Function DocumentCommandsUpdateFiles () export
	
	return 3;
	
EndFunction 

Function DocumentCommandsUploadPrintForm () export
	
	return 4;
	
EndFunction 

Function DocumentCommandsUploadEmail () export
	
	return 1;
	
EndFunction 

#endregion

#region AttachmentsCommands

&AtClient
Function AttachmentsCommandsShow () export
	
	return 1;
	
EndFunction 

&AtClient
Function AttachmentsCommandsUpload () export
	
	return 2;
	
EndFunction 

&AtClient
Function AttachmentsCommandsDownload () export
	
	return 3;
	
EndFunction 

&AtClient
Function AttachmentsCommandsDownloadAll () export
	
	return 4;
	
EndFunction 

&AtClient
Function AttachmentsCommandsRemove () export
	
	return 5;
	
EndFunction 

&AtClient
Function AttachmentsCommandsRun () export
	
	return 6;
	
EndFunction 

&AtClient
Function AttachmentsCommandsPrint () export
	
	return 7;
	
EndFunction 

#endregion

#region BooksCommands

&AtClient
Function BooksActivate () export
	
	return "ActivateBook";
	
EndFunction 

#endregion

#region PictureCommands

Function PictureCommandsAdd () export
	
	return "add";
	
EndFunction 

Function PictureCommandsDelete () export
	
	return "del";
	
EndFunction 

Function PictureCommandsOpenGallery () export
	
	return "gal";
	
EndFunction 

#endregion

#region PictureMessages

&AtClient
Function RefreshItemPictures () export
	
	return "RefreshItemPictures";
	
EndFunction 

#endregion

#region EditorActions

Function EditorActionSave () export
	
	return "e27b59a0_9927_11e5_8994_feff819cdc9f";
	
EndFunction 

Function EditorActionSaveAndClose () export
	
	return "e27b6152_9927_11e5_8994_feff819cdc9f";
	
EndFunction 

Function EditorActionFiles () export
	
	return "e27b66fc_9927_11e5_8994_feff819cdc9f";
	
EndFunction 

Function EditorActionCancel () export
	
	return "e27b68aa_9927_11e5_8994_feff819cdc9f";
	
EndFunction 

#endregion

#region DocumentFilesCommands

Function DocumentFilesCommandsSelect () export
	
	return 1;
	
EndFunction 

Function DocumentFilesCommandsUpload () export
	
	return 2;
	
EndFunction 

#endregion

#region Settings

&AtServer
Function SettingsFirstLogin () export
	
	return "FirstLogin";
	
EndFunction 

&AtServer
Function SettingsShowBooksChoice () export
	
	return "ShowBooksChoice";
	
EndFunction 

&AtServer
Function SettingsCurrentBook () export
	
	return "CurrentBook";
	
EndFunction 

&AtServer
Function SettingsShowBooks () export
	
	return "ShowBooks";
	
EndFunction 

&AtServer
Function SettingsDocumentsSortByBooks () export
	
	return "DocumentsSortByBooks";
	
EndFunction 

&AtServer
Function SettingsDocumentsBooksManualSort () export
	
	return "DocumentsBooksManualSort";
	
EndFunction 

&AtServer
Function SettingsDocumentsShowRemoved () export
	
	return "DocumentsShowRemoved";
	
EndFunction 

&AtServer
Function SettingsDocumentsShowFiles () export
	
	return "DocumentsShowFiles";
	
EndFunction 

&AtServer
Function SettingsDocumentsShowTags () export
	
	return "DocumentsShowTags";
	
EndFunction 

&AtServer
Function SettingsDocumentsSendNotification () export
	
	return "DocumentsSendNotification";
	
EndFunction 

&AtServer
Function SettingsShowSettingsButtonState () export
	
	return "ShowSettingsButtonState";
	
EndFunction 

&AtServer
Function SettingsCalendarSettings () export
	
	return "CalendarSettings";
	
EndFunction 

&AtServer
Function SettingsHideTree () export
	
	return "HideTree";
	
EndFunction 

&AtServer
Function SettingsSalesOrderPicturesEnabled () export
	
	return "SalesOrderPicturesEnabled";
	
EndFunction 

&AtServer
Function SettingsPurchaseOrderPicturesEnabled () export
	
	return "PurchaseOrderPicturesEnabled";
	
EndFunction 

&AtServer
Function SettingsInternalOrderPicturesEnabled () export
	
	return "InternalOrderPicturesEnabled";
	
EndFunction 

&AtServer
Function SettingsEmailsPreview () export
	
	return "EmailsPreview";
	
EndFunction 

&AtServer
Function SettingsBankPeriod () export
	
	return "BankPeriod";
	
EndFunction 

&AtServer
Function SettingsPinnedDate () export
	
	return "PinnedDate";
	
EndFunction 

&AtServer
Function SettingsPrintFormLanguage () export
	
	return "PringFormLanguage";
	
EndFunction 

#endregion

#region PhonesActions

Function PhonesActionsNew () export
	
	return 1;
	
EndFunction 

Function PhonesActionsList () export
	
	return 2;
	
EndFunction 

#endregion

#region MailCommands

Function MailCommandsReply () export
	
	return 1;
	
EndFunction 

Function MailCommandsForward () export
	
	return 2;
	
EndFunction 

Function MailCommandsForwardOutgoingEmail () export
	
	return 3;
	
EndFunction 

Function MailCommandsSendDocuments () export
	
	return 4;
	
EndFunction 

#endregion

#region MailboxLabels

Function MailboxLabelsBox () export
	
	return 0;
	
EndFunction 

Function MailboxLabelsIncoming () export
	
	return 1;
	
EndFunction 

Function MailboxLabelsIncomingLabel () export
	
	return 2;
	
EndFunction 

Function MailboxLabelsOutgoing () export
	
	return 3;
	
EndFunction 

Function MailboxLabelsOutgoingLabel () export
	
	return 4;
	
EndFunction 

Function MailboxLabelsIncomingIMAPLabel () export
	
	return 5;
	
EndFunction 

Function MailboxLabelsTrash () export
	
	return 6;
	
EndFunction 

#endregion

#region EmailBody

Function EmailBodyDownload () export
	
	return "d";
	
EndFunction 

Function EmailBodyOpen () export
	
	return "o";
	
EndFunction 

#endregion

#region MailboxPictures

&AtServer
Function MailboxPicturesBox () export
	
	return 0;
	
EndFunction 

&AtServer
Function MailboxPicturesIncomingFolder () export
	
	return 1;
	
EndFunction 

&AtServer
Function MailboxPicturesIncomingLabel () export
	
	return 2;
	
EndFunction 

&AtServer
Function MailboxPicturesLabelIMAP () export
	
	return 3;
	
EndFunction 

&AtServer
Function MailboxPicturesOutboxFolder () export
	
	return 4;
	
EndFunction 

&AtServer
Function MailboxPicturesOutboxLabel () export
	
	return 5;
	
EndFunction 

&AtServer
Function MailboxPicturesTrash () export
	
	return 6;
	
EndFunction 

#endregion

#region ShipmentCommands

&AtClient
Function ShipmentCommandsStart () export
	
	return 1;
	
EndFunction 

&AtClient
Function ShipmentCommandsComplete () export
	
	return 2;
	
EndFunction 

#endregion

#region SuperRoles

&AtServer
Function SuperRolesUnlimited () export
	
	return "Unlimited";
	
EndFunction 

&AtServer
Function SuperRolesSysadmin () export
	
	return "AdministratorSystem";
	
EndFunction 

#endregion

#region PickItemsCommands

Function PickItemsCommandsSelect () export
	
	return 1;
	
EndFunction 

Function PickItemsCommandsReserve () export
	
	return 2;
	
EndFunction 

Function PickItemsCommandsAllocate () export
	
	return 3;
	
EndFunction 

#endregion

#region ChoiceOperations

&AtClient
Function ChoiceOperationsPickItems () export
	
	return "PickItems";
	
EndFunction 

&AtClient
Function ChoiceOperationsReserveItems () export
	
	return "ReserveItems";
	
EndFunction 

&AtClient
Function ChoiceOperationsAllocateItems () export
	
	return "AllocateItems";
	
EndFunction 

&AtClient
Function ChoiceOperationsAllocateServices () export
	
	return "AllocateServices";
	
EndFunction 

&AtClient
Function ChoiceOperationsFixedAsset () export
	
	return "FixedAsset";
	
EndFunction 

&AtClient
Function ChoiceOperationsIntangibleAsset () export
	
	return "IntangibleAsset";
	
EndFunction 

&AtClient
Function ChoiceOperationsEntryRecord () export
	
	return "EntryRecord";
	
EndFunction 

&AtClient
Function ChoiceOperationsEntrySaveAndNew () export
	
	return "EntrySaveAndNew";
	
EndFunction 

&AtClient
Function ChoiceOperationsPayrollRecord () export
	
	return "PayrollRecord";
	
EndFunction 

&AtClient
Function ChoiceOperationsPayEmployeesRecord () export
	
	return "PayEmployeesRecord";
	
EndFunction 

&AtClient
Function ChoiceOperationsEmployeesTaxRecord () export
	
	return "EmployeesTaxRecord";
	
EndFunction 

&AtClient
Function ChoiceOperationsPayrollRecordSaveAndNew () export
	
	return "PayrollRecordSaveAndNew";
	
EndFunction 

&AtClient
Function ChoiceOperationsPayEmployeesRecordSaveAndNew () export
	
	return "PayEmployeesRecordSaveAndNew";
	
EndFunction 

&AtClient
Function ChoiceOperationsEmployeesTaxRecordSaveAndNew () export
	
	return "EmployeesTaxRecordSaveAndNew";
	
EndFunction 

&AtClient
Function ChoiceOperationsFixedAssetSaveAndNew () export
	
	return "FixedAssetSaveAndNew";
	
EndFunction 

&AtClient
Function ChoiceOperationsIntangibleAssetSaveAndNew () export
	
	return "IntangibleAssetSaveAndNew";
	
EndFunction 

&AtClient
Function ChoiceOperationsLVI () export
	
	return "LVI";
	
EndFunction

&AtClient
Function ChoiceOperationsLVISaveAndNew () export
	
	return "LVISaveAndNew";
	
EndFunction

#endregion

#region DocumentActions

Function DocumentActionsPost () export
	
	return "DocumentActionsPost";
	
EndFunction 

Function DocumentActionsUnpost () export
	
	return "DocumentActionsUnpost";
	
EndFunction 

Function DocumentActionsDelete () export
	
	return "DocumentActionsDelete";
	
EndFunction 

Function DocumentActionsUndelete () export
	
	return "DocumentActionsUndelete";
	
EndFunction 

Function DocumentActionsPostAndNew () export
	
	return "DocumentActionsPostAndNew";
	
EndFunction 

#endregion

#region Hints

&AtClient
Function HintsProjectsInCalendar () export
	
	return "HintProjectsInCalendar";
	
EndFunction 

&AtClient
Function HintsRoomsInCalendar () export
	
	return "HintRoomsInCalendar";
	
EndFunction 

#endregion

#region Licensing

Function LicensingOK () export
	
	return 0;
	
EndFunction 

Function LicensingLicenseNotDefined () export
	
	return 1;
	
EndFunction 

Function LicensingLicenseNotFound () export
	
	return 2;
	
EndFunction 

Function LicensingError () export
	
	return 3;
	
EndFunction 

Function LicensingLicenseWasDeleted () export
	
	return 4;
	
EndFunction 

#endregion

#region CalendarMenuActions

Function CalendarMenuNewTask () export
	
	return 1;
	
EndFunction

Function CalendarMenuNewCommand () export
	
	return 2;
	
EndFunction

Function CalendarMenuNewTimeEntry () export
	
	return 3;
	
EndFunction

Function CalendarMenuNewProject () export
	
	return 4;
	
EndFunction

Function CalendarMenuNewMeeting () export
	
	return 5;
	
EndFunction

Function CalendarMenuNewEvent () export
	
	return 6;
	
EndFunction

#endregion

#region LaunchParameters

&AtClient
Function LaunchParametersMode () export
	
	return "mode";
	
EndFunction

&AtClient
Function LaunchParametersSkipUpdate () export
	
	return "skipupdate";
	
EndFunction

&AtClient
Function LaunchParametersUpdateApplied () export
	
	return "updateapplied";
	
EndFunction

&AtClient
Function LaunchParametersUpdateCanceled () export
	
	return "updatecanceled";
	
EndFunction

&AtClient
Function LaunchParametersRunMainScenario () export
	
	return "RunMainScenario";
	
EndFunction

&AtClient
Function LaunchParametersInitNode () export
	
	return "InitialFillingNode";
	
EndFunction

#endregion

#region Constants

Function ConstantsApplicationCode () export
	
	return "000";
	
EndFunction

&AtServer
Function ConstantsUpdateLockingPeriod () export
	
	return 15 * 60;
	
EndFunction

&AtClient
Function ConstantsUpdateCheckingPeriod () export
	
	return 14400; // every 4 hours
	
EndFunction

#endregion

#region Framework

Function FrameworkManagedForm () export
	
	if ( Framework.VersionLess ( "8.3.14" ) ) then
		return "ManagedForm";
	else
		return "ClientApplicationForm";
	endif;
	
EndFunction

#endregion

#region DataProcessors

&AtServer
Function DataProcessorsLicensing () export
	
	return "Licensing";
	
EndFunction

#endregion

#region InvoiceRecords

Function InvoiceRecordsWrite () export
	
	return "InvoiceRecordsWrite";
	
EndFunction 

#endregion

#region AdditionalProperties

&AtServer
Function AdditionalPropertiesWritingUser () export
	
	return "AdditionalPropertiesWritingUser";
	
EndFunction

Function AdditionalPropertiesProposeEnrollment () export

	return "AdditionalPropertiesProposeEnrollment";
	
EndFunction

Function AdditionalPropertiesReceived () export

	return "AdditionalPropertiesReceived";
	
EndFunction

&AtServer
Function AdditionalPropertiesPassword () export
	
	return "AdditionalPropertiesPassword";
	
EndFunction

&AtServer
Function AdditionalPropertiesMembership () export
	
	return "AdditionalPropertiesMembership";
	
EndFunction

&AtServer
Function AdditionalPropertiesSelectedUsers () export
	
	return "AdditionalPropertiesSelectedUsers";
	
EndFunction

Function AdditionalPropertiesRemoving () export
	
	return "AdditionalPropertiesRemoving";
	
EndFunction

&AtServer
Function AdditionalPropertiesInteractive () export
	
	return "AdditionalPropertiesInteractive";
	
EndFunction

#endregion
#region Exceptions

Function ExceptionsUndefinedFilesFolder () export
	
	return "ExceptionsUndefinedFilesFolder";
	
EndFunction

#endregion