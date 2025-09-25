
IF OBJECT_ID('tempdb..#Paradise') IS NOT NULL DROP TABLE #Paradise

  create table #Paradise (
   [name] [nvarchar](MAX) NULL 
 , [IsEncrypted] [bit] NULL 
 , [type_desc] [nvarchar](MAX) NULL 
 , [ss_ViewDependencyOBject] [nvarchar](MAX) NULL 
)


 INSERT INTO #Paradise([name],[IsEncrypted],[type_desc],[ss_ViewDependencyOBject])
Select  N'sp_tblMST_ContractType' as [name],N'False' as [IsEncrypted],N'SQL_STORED_PROCEDURE' as [type_desc],NULL as [ss_ViewDependencyOBject] UNION ALL

Select  N'tblMST_ContractType' as [name],NULL as [IsEncrypted],N'USER_TABLE' as [type_desc],NULL as [ss_ViewDependencyOBject]
select * from #Paradise
GO

--#region tblDataSetting
IF OBJECT_ID('tempdb..#tblDataSetting') IS NOT NULL DROP TABLE #tblDataSetting
  create table #tblDataSetting (
   [TableName] [nvarchar](MAX) NULL 
 , [ViewName] [nvarchar](MAX) NULL 
 , [AllowAdd] [bit] NULL 
 , [ReadOnlyColumns] [nvarchar](MAX) NULL 
 , [ComboboxColumns] [nvarchar](MAX) NULL 
 , [ColumnOrderBy] [nvarchar](MAX) NULL 
 , [ColumnHide] [nvarchar](MAX) NULL 
 , [ReadOnly] [bit] NULL 
 , [TableEditorName] [nvarchar](MAX) NULL 
 , [IsProcedure] [bit] NULL 
 , [PaintColumns] [nvarchar](MAX) NULL 
 , [FormatFontColumns] [nvarchar](MAX) NULL 
 , [PaintRows] [nvarchar](MAX) NULL 
 , [IsProcessForm] [bit] NULL 
 , [IsShowLayout] [bit] NULL 
 , [IsBatch] [bit] NULL 
 , [LoadDataAfterShow] [bit] NULL 
 , [GroupColumns] [nvarchar](MAX) NULL 
 , [FixedColumns] [nvarchar](MAX) NULL 
 , [ExportName] [nvarchar](MAX) NULL 
 , [CheckLockAttStore] [nvarchar](MAX) NULL 
 , [RptTemplate] [nvarchar](MAX) NULL 
 , [spAction] [nvarchar](MAX) NULL 
 , [DefaultValue] [nvarchar](MAX) NULL 
 , [FilterColumn] [nvarchar](MAX) NULL 
 , [IsEditForm] [bit] NULL 
 , [ColumnEditSpecial] [nvarchar](MAX) NULL 
 , [ColumnsFormatExtend] [nvarchar](MAX) NULL 
 , [AllowDelete] [bit] NULL 
 , [PaintCells] [nvarchar](MAX) NULL 
 , [LayoutDataConfig] varbinary(max) NULL 
 , [ColumnDataType] [nvarchar](MAX) NULL 
 , [ProcBeforeSave] [nvarchar](MAX) NULL 
 , [ProcAfterSave] [nvarchar](MAX) NULL 
 , [IsLayoutParam] [bit] NULL 
 , [ColumnSearch] [nvarchar](MAX) NULL 
 , [AlwaysReloadColumn] [bit] NULL 
 , [NotReloadAfterSave] [bit] NULL 
 , [ColumnChangeEventProc] [nvarchar](MAX) NULL 
 , [RowFontStyle] [nvarchar](MAX) NULL 
 , [isWrapHeader] [bit] NULL 
 , [ContextMenuIDs] [nvarchar](MAX) NULL 
 , [ColumnNotLock] [nvarchar](MAX) NULL 
 , [Import] [nvarchar](MAX) NULL 
 , [ProcBeforeDelete] [nvarchar](MAX) NULL 
 , [ProcAfterDelete] [nvarchar](MAX) NULL 
 , [ConditionFormatting] varbinary(max) NULL 
 , [ViewGridInShowLayout] [bit] NULL 
 , [ShortcutsControl] [nvarchar](MAX) NULL 
 , [LblMessage] [nvarchar](MAX) NULL 
 , [MinWidthColumn] [nvarchar](MAX) NULL 
 , [IsLayoutCommandButton] [bit] NULL 
 , [LayoutDataConfigCrazy] varbinary(max) NULL 
 , [NavigatorProcedure] [nvarchar](MAX) NULL 
 , [ValidateRowConditions] [nvarchar](MAX) NULL 
 , [ExecuteProcBeforeLoadData] [nvarchar](MAX) NULL 
 , [LayoutDataConfigWeb] varbinary(max) NULL 
 , [LayoutDataConfigMobile] varbinary(max) NULL 
 , [GridBandConfig] [nvarchar](MAX) NULL 
 , [ControlStateProcedure] [nvarchar](MAX) NULL 
 , [ValidationProcedures] [nvarchar](MAX) NULL 
 , [ReadonlyCellCondition] [nvarchar](MAX) NULL 
 , [ComboboxColumn_BackupForTransfer] [nvarchar](MAX) NULL 
 , [IsOpenSubForm] [bit] NULL 
 , [Validation] [nvarchar](MAX) NULL 
 , [ControlHiddenInShowLayout] [nvarchar](MAX) NULL 
 , [IgnoreColumnOrder] [bit] NULL 
 , [IgnoreLock] [bit] NULL 
 , [ReadonlyCellCondition_Backup] [nvarchar](MAX) NULL 
 , [SubDataSettingNames] [nvarchar](MAX) NULL 
 , [IsViewReportForm] [bit] NULL 
 , [ExportSeparateButton] [bit] NULL 
 , [HashLayoutConfig] [nvarchar](MAX) NULL 
 , [LayoutDataConfigFillter] varbinary(max) NULL 
 , [LayoutParamConfig] varbinary(max) NULL 
 , [OpenFormLink] [nvarchar](MAX) NULL 
 , [SaveTableByBulk] [nvarchar](MAX) NULL 
 , [IsNotPaintSaturday] [bit] NULL 
 , [IsNotPaintSunday] [bit] NULL 
 , [IsViewWeekName] [bit] NULL 
 , [IgnoreCheckEECode] [bit] NULL 
 , [ParadiseCommand] [int] NULL 
 , [Labels] [nvarchar](MAX) NULL 
 , [ColumnHideExport] [nvarchar](MAX) NULL 
 , [ColumnWidthCalcData] [bit] NULL 
 , [HideHeaderFilterButton] [bit] NULL 
 , [HideColumnGrid] [bit] NULL 
 , [TypeGrid] [int] NULL 
 , [ProcBeforeAdd] [nvarchar](MAX) NULL 
 , [ProcAfterAdd] [nvarchar](MAX) NULL 
 , [ExecuteProcAfterLoadData] [nvarchar](MAX) NULL 
 , [LayoutDataConfigColumnView] varbinary(max) NULL 
 , [LayoutDataConfigCardView] varbinary(max) NULL 
 , [HideFooter] [int] NULL 
 , [IsFilterBox] [bit] NULL 
 , [GetDefaultParamFromDB] [bit] NULL 
 , [TaskTimeLine] [int] NULL 
 , [HtmlCell] [int] NULL 
 , [MinPageSizeGrid] [int] NULL 
 , [ClickHereToAddNew] [int] NULL 
 , [IgnoreQuestion] [bit] NULL 
 , [FormLayoutJS] [int] NULL 
 , [CheckBoxText] [int] NULL 
 , [ColumnHideMobile] [nvarchar](MAX) NULL 
 , [LayoutMobileLocalConfig] varbinary(max) NULL 
 , [ViewMode] [int] NULL 
 , [Mode] [int] NULL 
 , [Template] [nvarchar](MAX) NULL 
 , [NotResizeImage] [int] NULL 
 , [DeleteOneRowReloadData] [int] NULL 
 , [AutoHeightGrid] [bit] NULL 
 , [ProcFileName] [nvarchar](MAX) NULL 
 , [HeightImagePercentHeightFont] [float] NULL 
 , [ColumnMinWidthPercent] [nvarchar](MAX) NULL 
 , [GridViewAutoAddRow] [int] NULL 
 , [GridViewNewItemRowPosition] [int] NULL 
 , [LastColumnRemainingWidth] [int] NULL 
 , [IsAutoSave] [bit] NULL 
 , [VirtualColumn] [nvarchar](MAX) NULL 
 , [GridTypeview] [int] NULL 
 , [selectionMode] [int] NULL 
 , [deleteMode] [int] NULL 
 , [ClearDataBeforeLoadData] [int] NULL 
 , [LockSort] [bit] NULL 
 , [HightLightControlProc] [nvarchar](MAX) NULL 
 , [ScriptInit0] [nvarchar](MAX) NULL 
 , [ScriptInit1] [nvarchar](MAX) NULL 
 , [ScriptInit2] [nvarchar](MAX) NULL 
 , [ScriptInit3] [nvarchar](MAX) NULL 
 , [ScriptInit4] [nvarchar](MAX) NULL 
 , [ScriptInit5] [nvarchar](MAX) NULL 
 , [ScriptInit6] [nvarchar](MAX) NULL 
 , [ScriptInit7] [nvarchar](MAX) NULL 
 , [ScriptInit8] [nvarchar](MAX) NULL 
 , [ScriptInit9] [nvarchar](MAX) NULL 
 , [FontSizeZoom0] [float] NULL 
 , [FontSizeZoom1] [float] NULL 
 , [FontSizeZoom2] [float] NULL 
 , [FontSizeZoom3] [float] NULL 
 , [FontSizeZoom4] [float] NULL 
 , [FontSizeZoom5] [float] NULL 
 , [FontSizeZoom6] [float] NULL 
 , [FontSizeZoom7] [float] NULL 
 , [FontSizeZoom8] [float] NULL 
 , [FontSizeZoom9] [float] NULL 
 , [NotBuildForm] [bit] NULL 
 , [NotUseCancelButton] [bit] NULL 
 , [GridUICompact] [float] NULL 
 , [DisableFilterColumns] [nvarchar](MAX) NULL 
 , [DisableFilterAll] [int] NULL 
)

 INSERT INTO #tblDataSetting([TableName],[ViewName],[AllowAdd],[ReadOnlyColumns],[ComboboxColumns],[ColumnOrderBy],[ColumnHide],[ReadOnly],[TableEditorName],[IsProcedure],[PaintColumns],[FormatFontColumns],[PaintRows],[IsProcessForm],[IsShowLayout],[IsBatch],[LoadDataAfterShow],[GroupColumns],[FixedColumns],[ExportName],[CheckLockAttStore],[RptTemplate],[spAction],[DefaultValue],[FilterColumn],[IsEditForm],[ColumnEditSpecial],[ColumnsFormatExtend],[AllowDelete],[PaintCells],[LayoutDataConfig],[ColumnDataType],[ProcBeforeSave],[ProcAfterSave],[IsLayoutParam],[ColumnSearch],[AlwaysReloadColumn],[NotReloadAfterSave],[ColumnChangeEventProc],[RowFontStyle],[isWrapHeader],[ContextMenuIDs],[ColumnNotLock],[Import],[ProcBeforeDelete],[ProcAfterDelete],[ConditionFormatting],[ViewGridInShowLayout],[ShortcutsControl],[LblMessage],[MinWidthColumn],[IsLayoutCommandButton],[LayoutDataConfigCrazy],[NavigatorProcedure],[ValidateRowConditions],[ExecuteProcBeforeLoadData],[LayoutDataConfigWeb],[LayoutDataConfigMobile],[GridBandConfig],[ControlStateProcedure],[ValidationProcedures],[ReadonlyCellCondition],[ComboboxColumn_BackupForTransfer],[IsOpenSubForm],[Validation],[ControlHiddenInShowLayout],[IgnoreColumnOrder],[IgnoreLock],[ReadonlyCellCondition_Backup],[SubDataSettingNames],[IsViewReportForm],[ExportSeparateButton],[HashLayoutConfig],[LayoutDataConfigFillter],[LayoutParamConfig],[OpenFormLink],[SaveTableByBulk],[IsNotPaintSaturday],[IsNotPaintSunday],[IsViewWeekName],[IgnoreCheckEECode],[ParadiseCommand],[Labels],[ColumnHideExport],[ColumnWidthCalcData],[HideHeaderFilterButton],[HideColumnGrid],[TypeGrid],[ProcBeforeAdd],[ProcAfterAdd],[ExecuteProcAfterLoadData],[LayoutDataConfigColumnView],[LayoutDataConfigCardView],[HideFooter],[IsFilterBox],[GetDefaultParamFromDB],[TaskTimeLine],[HtmlCell],[MinPageSizeGrid],[ClickHereToAddNew],[IgnoreQuestion],[FormLayoutJS],[CheckBoxText],[ColumnHideMobile],[LayoutMobileLocalConfig],[ViewMode],[Mode],[Template],[NotResizeImage],[DeleteOneRowReloadData],[AutoHeightGrid],[ProcFileName],[HeightImagePercentHeightFont],[ColumnMinWidthPercent],[GridViewAutoAddRow],[GridViewNewItemRowPosition],[LastColumnRemainingWidth],[IsAutoSave],[VirtualColumn],[GridTypeview],[selectionMode],[deleteMode],[ClearDataBeforeLoadData],[LockSort],[HightLightControlProc],[ScriptInit0],[ScriptInit1],[ScriptInit2],[ScriptInit3],[ScriptInit4],[ScriptInit5],[ScriptInit6],[ScriptInit7],[ScriptInit8],[ScriptInit9],[FontSizeZoom0],[FontSizeZoom1],[FontSizeZoom2],[FontSizeZoom3],[FontSizeZoom4],[FontSizeZoom5],[FontSizeZoom6],[FontSizeZoom7],[FontSizeZoom8],[FontSizeZoom9],[NotBuildForm],[NotUseCancelButton],[GridUICompact],[DisableFilterColumns],[DisableFilterAll])
Select  N'sp_tblMST_ContractType' as [TableName],N'sp_tblMST_ContractType' as [ViewName],N'True' as [AllowAdd],N'' as [ReadOnlyColumns],N'' as [ComboboxColumns],N'ContractName&0,ContractNameEN&1,ShortTermTax&2,Limit&3,Duration&4,ContractPrefix&5,RemainDayNotification&6,ContractTemplateList&7' as [ColumnOrderBy],N'ContractCode,ContributeSI,ContributeJI,isReadOnlyRow,dtftxxENGColumns' as [ColumnHide],N'False' as [ReadOnly],N'tblMST_ContractType' as [TableEditorName],N'True' as [IsProcedure],N'' as [PaintColumns],N'' as [FormatFontColumns],N'' as [PaintRows],N'False' as [IsProcessForm],N'False' as [IsShowLayout],N'False' as [IsBatch],N'True' as [LoadDataAfterShow],N'' as [GroupColumns],N'' as [FixedColumns],N'' as [ExportName],N'' as [CheckLockAttStore],N'' as [RptTemplate],N'' as [spAction],N'' as [DefaultValue],N'' as [FilterColumn],N'False' as [IsEditForm],N'' as [ColumnEditSpecial],N'' as [ColumnsFormatExtend],N'False' as [AllowDelete],N'' as [PaintCells],0x1F8B0800000000000400ED9D4D6FDBC819C77B2ED0EF40A8C09EDCC4F25BECDD5858C78E63038E13D84A9C9C0A5A1ACB8429522029BFE4BA879EF7D0532F5B147BE8620B6CBB3DC5873D78B1DFC39FA05FA1C31745B24D4A33941C59E2EF8720C80B9FE1709E99E133FF793CFCDFE52F4FDF059EB92F3CCBB4AD0FC2334E85E75BAEB35A2A3F9A2D1966AB655B353388FE65BDED076E73C7BC70DBC1BAEB049E6B972A7FF8BD613C6D796E4B78C185E1984DB15AFA637CCDDBB8A892F138F5AA57ADB0587FD3ADB5FD9261F94EDBB6574B81D716E1DF4EC445F297C8F8AEF95A2DB04ECD40EC0B5BD402514F6AF4CA79E106719995D0FCE9E38E5D5639B6ED9E45069F4AD8310F85BD2E1FFCA45439326D7F7021CF1DF3D0166BEDC0AD9A87AFBCBAF0F2DFBDF3607559D46BB32154EBD02DEA85E7B65BFACF2FEF7728EA398DF78459771DFBE279DD0A5C4FD5FEA57B2A6273AB711C54DD1D7114A83EEF27DB0DCB933D20EC6995B59AE7FA7EF558381BEE9973AB88DB7FBD55DE8EEB9EAC39F54D21EC1CDD71FFC47276E59F4A950D71FAFCBCE509DF37F6830B7BF0834457952A610903AF7DE38B0D7164B6EDA0B7BA6A8D2D6D0F2CA7EE9EF9EF5ECB266A66F4AC01CDB41D88A67FB3498C53D36ECBFF2A2F64B54E68545668D5BB96D58B9688DB359E54A2EE79E75153ECBA9DF9B5E90927880A49A6A23483E8D2676E3876FDB7966F1DDA99232F631C6C78E6D933B376D2902539F50CA764CD1DDB4E5D56D23FB08263F994493D4A95AA5A19C95C1A3673559C074A2D9DD266D2B4EA2613D186E507A6539306F3291548375EB3AD86F3D2AD4B23D9D9E2764FAA96F610839F6BDD8CACB79B721EFCE414C576DD0C5DD29D1AC2A9A5EA46F38C8271DCD9E247D9138DB66D7A9AD5DD71E3F7663821440356D33EEC10E7A5CA9FCAAADD2FEE33EBAEED7ACF6CE1D42DA7A1D90735FAEC79CB74EAAFE42CDB96767D5F9559C61A77EBCC78914FC209A15491B1452003135BC17AFFD83D4B5EA5EBB6EB8B67ED2008DDA235B6B782A6BD1F78B24DB79DC44BCAD58F0A78615FB48EC329DE89FCA2DE2792F1F35ADE3BEFB85E6BB584E98583399AE43AF5572B2C6560B99E88BA59EF749A76614F8F1C78A99C37F52E9C1B74E5A69CC74A9597561812B84781B16F3AF28D2C23DDA319A35C6EA5B57D5A312F3CB36EC9792C9E0BB65CCFFA200B4EED7959B5D89791F586B003B35499D5310BE382C42E7B0E4A9D47333A61D4896EF481AC3EACFC72489D9FFADD5EE396DD7E1BBED8E8AF85EAAF377CDF596E16A20BEC8B862B8C37DBD2EDB3C576BB462C8BCFA7C4E74427533FDBAB47BDD57059D2B3F0CF1900EFC995A038B21C2B2A345DBC98BDE9B13B4B33D76E371DBD52541627B2F14B95AF17660EAC7A70BC5A9E5F9EFD7A7E664B84CBD4D5E5F93487A42FA7E2558DB670D16B1CF7A15DD76B2AADABB68429C74F6CEAE759ED461E4DC4AF6DE758F6FD40D455A49DF44854A5AD42D36E55ABAE8A92D49D9E3A826CBE4E18B717F3DAF4CE6B593E8F147DD56E83E7A7C8F372768A85357C5F38DF6FB941D5932D88F78BE5FD58680E1F04BF4FAFDFB502C761D62E197D41B92728F603D55E30923E30540FC8E5FFFCDE57DB6B0E077DB484535B8724CBDB38A3C6FA606A281EA9CAFA8667F6DD54CA34735B7D576C7916EA1A5A7DCA3A3DD9F654F3A2BC7E5FAE5F4B15B54D88780DAF7587D824FB261A2DE4BA76D5CA3B0B7CB2EE3716938BAA56600BA52BB76BAE13EFA7EEBA8EDA9ECC76B329EA9619884E8D32A5868C3ED7DD49D5EBB0515D555AA1E7428596E8B93A476B24B91B3D5553DFDD0AAD8669CDD05EA345157AEAAE19E6D9ECB9AE8A7A338C6A9B314472C74B6F7C112A3B9D62FAF840EDDDF0A0DFB8BD4F9AB7C10E64DD0F3C53F6B7F0F7619A4A71F362CADEF86A2965A1A7B41559F9AEA945437976C6487E2955A85ED7B7EA4AA15F9767DEADCECADFDFAFAA18863935DBCE8DF0458E9AA6724A4CB4B197FE42BDFD02BE7D8FD8349CA4BE7CBBAB52D5C0F4825D71B663391A5E88DC66D9567051AAACD967E6C5DD04B681F996E1BC383792A4C744EB0E0B5469B2F8EAB880E03CD8B4EC40A8A4AF0D9DE9942307F0B6B7E4B096F5F703CFB49CC08F5FC7EA5B0A51E6DCED26CF1EA0DA89769141F4844D11AF7BEA7519F78A23E5CA55DDB091BABB168B2A8D72DAD07CB08E45B2BD544EB697C2019EEC2D69AC5286493D236B4821124083216B68E82E4006095943C5F5395943533FDB2B042C2FCDF33B11CF5C27E2514AA67969394909F39D949CF2826619C96BA7274CACBA2DC51831B49526BA3FEBB2256B6787358C7E204ED4A3C847236EAE7A5633DEB35AF384F9296053BE7FA7DAF29F7A1E5BE3075F627BD9133FE4B2D7FDF99591FC4806EAFDCDC250EFB3EA817A8F7A9F627F1FEABD7D68ABEB3D2394F01FB8688E50ADBCB17343B5D610FE92B8692E899B1617BB61537945B10CC59F3E1EB1663E3F6324BFF434F3F99977AB0B4B1AAAF9CDC87265AE373A55911F4723BB57AF7E6C1A27D6F5C75F94D4E474015EAF907B13E1D39F717036BA92783F3F6EF1BEE1D5A3D02C3E5403051F051F051F4D27BD9889D47450F0517351F0F1390A7E1166FB9C0ABE56C49322E0CF2E759759734B08F8FDAA2D10F011F011F011F011F015ECEF49C0D7D47C50F1073AABE02ABEAAE0DA23E3E70CBF86389B634C227E9CF83E37F35E5182EF7760CB93A585CFA6E27F61075FD5C231B35A93B19FEF3A5F3482AF76AF3FFED2368263F3C2F8F5DBEBCBBF5A46EDF8FAF29F35A36E3AC7F2DFAF7E340EAF3F7EDF344EAFBE738DFAD57F9C86D1BCBEFC9B155DFE4D78C50FCD47BB8DABEF2E8C63EBFAF22F6DC3BEBEFC77CD3839BEFAAFBCD6BFBEFC9729AFFDEDA7EBCB7FD40CE7EA07C770A27B3A776D7CD38A6F797EF5B399DC2CFCB75FBFB566E41FDAF20F573FC7B734CA372A533B76C3FFFCE8341E858FF9387ACEF0F9F2EF57688CB6C9DCAC58E078E554DBBEC72B6B2F19EEE784E5B42D8491ECCD280C174E58E684E5B41396FB064969AF34CE582EEA19CB3D01F9DCA3C5E9D63033BA1E272BD34B1F762F655F953D36F6558BE773229129757CAEDDA1E29CA2DCCDAC5549D0E310650E5166327B486FB1E21D9D8CBF8B7660321E2FDE31C9C5F679D10E472E92B7B5C2C0A93F1259C9F343F93D97D7F3FB5C6D57988390C9C41CD0426462928979FBCE0F3113B36537FEBC79B0EE369BA6A322A9702232272293A27ACF29AA633D1E797EE6FDEA9315A51FF81E498E6738031D9DD5E219E8CB53277FFAA3EE5C36DE539317C77DF0C261E06C1EACD595667D8E5C50299F23173872412554409BE9634642D0A81D5FF0E41012828AE7731282A6D4F10AC149FF039255C2AAB4F315CA9A6570BE02E72BA0EA0F7E0854FDB48B50F551F58750F575A41D4E5618E8A62992AD7535528E58E86795FFDB8237C3CBB9A579CDF07244A72447E71244E711E497DD35269BC93C7560E94128F5FBE6E967F92963A4FA81C648F548F5C83848F5A3777CC1655BA4FAE2F91CA97E4A1DFF99A5FACE37799650EA95AB2D50EA51EA51EA51EA51EA15ECEF4DA957957690EA07FA09A91EA93ED5EAD6270D43C53DAF58BFBC3216B17EE7B79FDA43AAF48A13CD64CAF44F1E844CBF277CA11294A2D32B958F4E8F4EAF128FA0E1F43143A71FB5E30BAED9A2D317CFE7E8F453EAF831E9F4CBBA294FE8F4E8F4E8F4831F029D3EED22747A74FA61757A656D07A17EA0A310EA11EA53AD6E09F58B8B73B985FA274BE311EAAFBE6B1AF6F5C7BF0F9B54AF3ADF4CA65EBFFC00F4FAE7E72DD743AECFBA1CB91EB93EA518A49C81E60F54C343AE2FA2DB91EB8BE773E4FA2975FC6796EB390107BD1EBD1EBD1EBD1EBD3EE3CE0F54AF57D77690EB07FA09B91EB93ED5EA965CBF3CB73C6972FDBBF6F5C7EF03439CD784CAD74CB3057BE5096732F5FA9521F5FAE7CD567011764DA128D6E71E7823F9E6AB76D43E898B95BCEBB33C9B0943ED0D68EF44E4D94CB89BA456EE59389755FA50DAD25B6BDAEFDDA1526EDFC9DF9D621F877D9CEC6A164DE3631F074D9F7D1C7CCE3ECEF43A9EED84F4508CED849B85B19D90550FB613D84E48B1BF97CFE48A605C5FC9654721E3AE93BDA3309C6C3126857F61E6DD6AB93CBB306912BFE6F0CDFABEAC5E29E3FDBC6C79F601A4D7EF09DB35F9C06CD6E5A4D723CBA6BEA72668C9FED2AA79AEEF1E05C6BEE9F8C6BEF0AC23190594A77BF18E408B5887408BCF8B26D01673B6D7DAF75FE8A40E2C2D2FC9854F12F4ACCCAFE44A4058E9CDDC578913C9BA472647261FFC10C8E46917219323930F2193DB87B6BAE483463ED04F53A491EFB9AE522C40B2BD9A143FD4F766179674C3CA119E8CF372B8CFCD6AF4BFC9CCB32F97C7ADDCD74E0EE5DB61C76A5A1C8D937539DA3DDA7D4A31A8390F5ECD41BB47C745BBC7E768F74598EDB5B4FB94E372E69E68E9F6DDE372E635CB40B847B847B81FFC1008F7691721DC23DC0F27DCEB283E48F7033D3545D2FD8D37161AFEA835FCB999F7AB734BEA22FEA70493F927BD31E6C26753F17B268B2FDFEEE657F2B5CB99503D7FEE61E8F9D2F95E5015B2F5CD73647D647D647D849EF4622652E841D647E245D6C7E7C8FA4598EDC725EB2F3E41D657ADB640D647D647D647D647D657B0BF3F595F57F841DD1FE830D47DD4FD54AB6951F77BE78C1188FCFAC54DA8D63F3F12ADFF85E7B65B2A35370F0F453DBABA6748F79182A34BE3D9D6D71EC49DF0F42C9C5E1BB224473DC64EDEAE325E7302FFC00A8EE55326F5C8116C6B0A3B8A7349DAF81EC9B686C2E089DFB2914CAFBBDCDB0CBD6279A216F7DF706D5975F7C2694365BE8AFA5BFC287D5E297DAA9BEB8B093DF63A3B2E510FEC09169ED9C2892769AD6EA8D16DCFE572A1FECAD970DBD24E2E8A6B27EAE32536D6B85BD280B14FE2F0B56F6891F6029053C26BD9AAEBB6EB8B67ED20081DA335C087D9F21BC94A7A981DA66EEC1ACD748512020BADFF7EDA1BBCE177F5151C5B93F4D1FBEEA36C47E276B6238BE773A290A9747BAE1D95283CC9BFA5228369CBB1A2426F9A19A7A6DD96D7CCF6173CE33D10BD52D4B5ABCEA1654B65CDD325E29552BC5CD196257A8DE30EB4EB7A4DA505D39630E580894DFD3C0BD9C89D511F2A55B69D63E15981503D017C245F29ACBA2A3A51773E4A9687397B60DC5E4C6499A613399165F979AD1658A7AA5D056F4FB8B7E52C146B63F8BB10FEDE7283AA275B0D8F4FBFC76345387C107C3D5DBED60AFE86597C90C991D7E7F93DAEB6031C0EEE68DDA5B67E205F31B530F215B3EA41BE22F98A29F6F7F2993DBB31AECFEC254325777CF4C617A132D329A68F2FD4DE110FFA6DDBFBA4791BEC40D6FDC03365BF0B7F1FA6A98AF9E6FFEC399C43A6516A59DD49A39C9F79BFBAB8A894ED399A2F06EACD44595F0CD42B65CC5F0C5C18F739058781B37920C786083E4BB61207140C34E68002B2809067C802C2ED6401E1F3E1863A5940D3E87685C0A47B1041EE0499BB1F06D42E828308388800617FF04320ECA75D84B08FB03F84B0AFA9EC7002C1404F4D917AADA99216EE0082B2EC16F1AF3CCAB9E6270273C797A3D1DDF5268A0CD95DAF90877ED2C08DBF3E7DFC2EF0CCF09037D3960EF32ABF0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000D0E5FF56BB43C700000300 as [LayoutDataConfig],N'' as [ColumnDataType],N'' as [ProcBeforeSave],N'' as [ProcAfterSave],N'False' as [IsLayoutParam],N'' as [ColumnSearch],N'False' as [AlwaysReloadColumn],N'False' as [NotReloadAfterSave],N'' as [ColumnChangeEventProc],N'' as [RowFontStyle],N'False' as [isWrapHeader],N'' as [ContextMenuIDs],N'' as [ColumnNotLock],N'' as [Import],N'' as [ProcBeforeDelete],N'' as [ProcAfterDelete],0x1F8B08000000000004007D8FB10AC24010447BC17F38D6564CAECF052BB1B032106D97B898C34BEED8EC45E2AF59F849FE82C1602188DD30CC1B669EF7477614C682D8A2B33762D51377D6B706F42A058521385BA1BC9DD2D215F2F94CA92CB00FC432A8161B32B0D8E1E0A394130B2AF9972A2A74B4C14A3C43BED6CB833D496DF4A8B664CFB5189D251FF267CFC67383B28F8E3A50B6BBD060403812A81E5D1C03E9B4204BBEBFE52FA791B64FEF000000 as [ConditionFormatting],N'True' as [ViewGridInShowLayout],N'' as [ShortcutsControl],N'' as [LblMessage],N'' as [MinWidthColumn],N'True' as [IsLayoutCommandButton],NULL as [LayoutDataConfigCrazy],N'' as [NavigatorProcedure],N'' as [ValidateRowConditions],N'' as [ExecuteProcBeforeLoadData],NULL as [LayoutDataConfigWeb],0x1F8B0800000000000400ED9DCF4F1B4916C7F7BCD2FE0F2DAF342736C18660C8C4D6107E04244222EC09E4587617768BEA2EABBB0C38D739EC75E7B0A7BD64359AC38C66A5D99D3DC12107A2F93FFC17ECBFB055DD0D18D38D5FB709D8F0FD0A4540EA555757BD7AF5EAD345FB7FA79F5EEC299FD5B8EF30E17CE0BE75C8FDC0915EA5507C325BB058A7239C2653E16F56BA8192EE16EBC9AE5A919EF2A52854FFF447CB7AD1F16587FBAA6779CCE595C29FA332EFA2AA0AD6D3C4526F3AA6DA605D36BB41C17202AF2B44A5A0FC2E373F1DF05EFC43687CDD7CB9A99C43A6788D0BDE54DC8E5BF4C67B25555467D598BF787A6E97568F10F22834B8A8618B35B858D1377E50A8EE33118CAE64CD630DC197BB4AD659E38D6F733FFFD5CF6FCCD655BD652D4E6DC36555AF7CD9ED64BF7F7DBD06B7731AEF70664B4FF4D66C47499F6AFF5A1EF2C8DC69B5555D6EF17D45BDDF0BDB55C7D71E603CADBADCF46510D4DBDC5B9547DE5015C33F0ED5B725E5C1B267AF732E72B863EDC0F1B6F57785EA2A3F5C3BEEF83C08AC9AEA89D13712962A544D0D23CB7E1BF055BECFBA420D3697D6D9DA76D7F16C7914ECBDD55DE4A678D6886EDA54DC0DAE768975C84457FF57B194D63BC6A848E8D5EB96F55E8747FD1A0595D03DAFDD6A82DDA533BF653EF75458491C8A920CC2A22FA599BBC13B27701A2275E6A5CC83559F1DBD64CD8396AEC9B35306252D766C7AB66E64B0EBA8B6BECBB81D856A9D56471C4B4D37D7F9B122F574429F69D3BA8C03D1AA1328E635B5C15C4203928D9785D3F25E4B5B1B69678BFA3D6E5AD24D8CBEAF15165A6FBA3A0E5E0C0AB15FD7CD905C8606135AEA328C3304E3C8D9A25BD9E1ADAE607EC6E66EC968DD3401219CB019ED8D431C17AA7F2952DD2FF2991529A4FF5270CF76BC16DD8175C4629EFD4687CDAEEEE31BD7BE34634E77F9F3101676B299E185AA4E1694CE3404C1BAD69647F1DAB82264C05F769532FD9C69B26E2857D494AF3B69D38BBB9DDCFCB08257A2D7699B98ED851D4D1FE47842BCD5D7CE3B51973B1DCE7C333BC3A875DE7E5A65093345FA3CF49BC1F8985470C0C54616D581305BC1D2A892EB3A3015AAAF1DB3C6CB7D65D598A797589DBAEECF58C56227A9EF93AA79E533DBD181299ADC1BD2773EE88A133D2FAD15359D2AAF72A158A13A9BC5CC2CF4B15D7A50490C8C294E183AD1151F48F36172B44F0C38375D3EC3252FFDD6AC5470DB07EFB6F470583749D0408A973332EEE8359FEF3B9E13569A9CA6CE5E1DB16B8BB0145DD7CB560B65D5D29D5FA87E3337B3EBD8AA5D592ACDE9EF37B8C9472A4BF3493956F2321BAD769933D441E3C885B6A5EF92D6DB0DBDB5E37E641AE4496B52224D920F26995E5EB22E29A9FF659439DF41E7F3A5E8BE119E1E6E784A1BF310C150DD0623FF80465E4727B310D918FBC737F61B52D57DDD8318FDC735FA1148303782717FB8E39E29711C670B92E20B644F20FA01D50B6EC507C6F2805CE39F7FF4690F07CCA40F7762B47D48BC4B8D1E813A1F58067091F6ACE04668986A263B37EEBCF2ECB70D8BC9BFDD8E39356D1475F99ADE8716AA34C8146DC5335D213249BF48861E9252D49DBC51E0C2FAA6B91817AA3B4A7052C9CDA6F4225EBE2D3D1A73DB745D6E3B4CF1F316A5228391A43C9BC3866DA5F4C24041424F0C94CED11BF1C3B681A6D1E9A5B11AA7378D7D861E25786AF84CB3BA232585C28C035FA7728DABF196E4D6B79B33D6E293678F6361A33DEA36502D3340D421B5197AECEC8C157F911A64DBD9AD2E89DF37C599BDCAACFEF77D8562681E0D6E7A575669EDAA2EF9C95EF8F03C79DD185E6786AF11999AB9F8FCDD36A5A98AF96A9B1F6D395E86510887CD118EEA15AACBE288F5AE3F581F790EC44CFFD2AD1CC68891AEA990D26551E9A882966F872948745EE82E9EDAE638A0303C647A6EEB9B0894CF1C4F05D1D243C7E0E163FDE17E4F9FA5994F018406E11DBA3CCAF16D5BE7787C9FDCB8BA349D7449E89FDDCDE36C3C894C2A8AEDFF1D6FFF5FB3E3F821DD7CFC90AEB8542AE9B5277E4A4759805E3B5E5C4729AE43D7503AAFA154A287C981895C971DE22C36B6DA24EB51A90DDD3A615A189EA7E476B823CCF280CF77DC88A02DFB9C5D4CE5BB3D5083BD39F6E6D89B636F3E517B73D11019D35CECD21FD32E9D0A6F726DD98D519C8D14E36C64365B3A33C6C99D31794151A7A4D1571E5E509A795F995F18F3545679AE7C67C8E12BA1BE6E9A395369EA5C2A90DE572DF5F576FFE453D7526DD6B33E7FDF3FFDBB6335DBFDD39F9A96CDBCB6FEFDD92F56A37FF2A36B1D9E7D94967DF61FAF65B9FDD37F3861F1EF4C899FDD27DBADB38F3DABEDF44FFFDAB544FFF4DF4DEBA07DF65F5D36E89FFE8BE9B2BFFFDA3FFDA16979673F7B96175ED3BB6E133027BAE4F1D96F2CBE98F9DDE7EF9D19FD4D577F73F65B7449AB78A531CDB634FF79E2B59E98DB7C1ADEA7B9BFFC9825C364FB629C257928479F8F23F199B9FBE6330DE5ED7021990D340334033443C9838066EE1ACD5C8295F95C6CA6BC94B10AB019B019B019B0198ACF81CD4C3E9BA1A7B8C032A3070A58065866D02AFF318EEB54265B9E763B50E6F3DF42E8E29EFD0052914A2AE6278054ACEF2EDB001569C5012A68091B400519545C6607C5526A7A003C71BE66CDE73B3AB2B090B10AE009E009E009E0098ACF014F4C389EC892D7824E8C1E27D009D08941AB6B74626EE67DA5BC487913CF4D7C8294A8DD0E9FA887872DC24316F901458630339D80E2D944008A1D1E70D25FE9015150EA07A200A2486F2610C55D218A72D6950F8802880288028882E2734014D38028C8992D20C5E89102A400A418B44A84148B0B530429B6CE3EBA96E89FFC735C46418D33D3492916268052AC1D77A40F4891561C908296B6015200524C04A4385FFA8AB38BA014A4980E4A014A41EE21500A508AE12B4F28A5A067B68014A3070A90029062D02A11522CCD4E11A4D8EBF64F7E54D641BB7FF253D7F299C58F9B9CF2D948E9C0821C72A6935794278057ACEFD6D8E19D7CE22378C54863F00AF08A3463F08A4C872A16802B68211DB802B882DC43C015C015C3579E505C414F6C812B460F14700570C5A055F2998AD214E18AADDF7FED8E799A821860A6134E2CDE379C50C76ADD118AE3834DD28A034ED0D235C009329CC0DB3333608A7239E3C792241DABC85A073805380538053805C5E7C029269C538886A0E7B8E014A307EA91738A0CBB9DA1E725CF061EB91429A97D4A5E4E2200F7FDB126B4F75FDEF4024D4AA6764B2FA838FBC5B50E9CFEC927F7797E5E3150CB8325164BF74D2C9A070DBD486C39AE833F00492B0E66414BDDC02CC02CBE04B3B8F2891F944998F0BE8A72C62A802C802C802C802C283E076431F9C8224B920B68317AA81E10B4B8B264E194C5178117193E93F522EF9B2BDFCFC77FE868C18410265A3C3FA438440ABF18883ACFDF6D3F5884519C9D0C86A107DF5775AE7B9F1D036500650065503207A08C6943194BF34019A4E00E94019441EE21A00CA08CE12B4F2ECAC89AEB82688C1E31100D108D44AB874234021334940E1A8A1DDF02D8188C410F9A6F14EF9B6F3494B7E1D87A2B2ED6DC8EEA4559CF588823CB1C07E300E378EC8C63309F28E3FD17A3FEB0642EE7FB3A171733D601B401B401B401B441F139A08D49471BCD7C592EE0C6E83103DC18FB8F4D6607B6EE63D00DCAFEE05EE94671E63D89DE0C6780A5B9C11E2ADF19DC3041C3D251C30AC386458E1B6970235F149A52B6519A00B6B1BEAB43045778A1675A71000D5A8607A091076880667CA18F48C5DB3C69F11C30033083DC4380198019C3579E44989131AF7DC40C030483B269C1F10C02C0989FD9AB144B8B99194622E321819A5B2118E43071D38B3DC9954C3AA9B8F2E38BA77B7AA36DCE9433A1C7CAAFFE0182200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882200882A0C7A9FF03EB4702C5F07F0100 as [LayoutDataConfigMobile],N'' as [GridBandConfig],N'' as [ControlStateProcedure],N'' as [ValidationProcedures],N'' as [ReadonlyCellCondition],N'' as [ComboboxColumn_BackupForTransfer],N'False' as [IsOpenSubForm],N'' as [Validation],N'ckbAllLimit,ckbAllShortTermTax' as [ControlHiddenInShowLayout],N'False' as [IgnoreColumnOrder],N'False' as [IgnoreLock],N'' as [ReadonlyCellCondition_Backup],N'' as [SubDataSettingNames],N'False' as [IsViewReportForm],N'False' as [ExportSeparateButton],N'' as [HashLayoutConfig],NULL as [LayoutDataConfigFillter],NULL as [LayoutParamConfig],N'' as [OpenFormLink],N'' as [SaveTableByBulk],N'False' as [IsNotPaintSaturday],N'False' as [IsNotPaintSunday],N'False' as [IsViewWeekName],N'False' as [IgnoreCheckEECode],N'0' as [ParadiseCommand],N'' as [Labels],N'' as [ColumnHideExport],N'False' as [ColumnWidthCalcData],N'False' as [HideHeaderFilterButton],N'False' as [HideColumnGrid],N'0' as [TypeGrid],N'' as [ProcBeforeAdd],N'' as [ProcAfterAdd],N'' as [ExecuteProcAfterLoadData],NULL as [LayoutDataConfigColumnView],NULL as [LayoutDataConfigCardView],N'0' as [HideFooter],N'False' as [IsFilterBox],N'False' as [GetDefaultParamFromDB],N'0' as [TaskTimeLine],N'0' as [HtmlCell],N'0' as [MinPageSizeGrid],N'0' as [ClickHereToAddNew],N'False' as [IgnoreQuestion],N'2' as [FormLayoutJS],N'0' as [CheckBoxText],N'' as [ColumnHideMobile],NULL as [LayoutMobileLocalConfig],N'0' as [ViewMode],N'0' as [Mode],N'' as [Template],N'0' as [NotResizeImage],N'0' as [DeleteOneRowReloadData],N'False' as [AutoHeightGrid],N'' as [ProcFileName],N'0' as [HeightImagePercentHeightFont],N'' as [ColumnMinWidthPercent],N'0' as [GridViewAutoAddRow],N'0' as [GridViewNewItemRowPosition],N'0' as [LastColumnRemainingWidth],N'False' as [IsAutoSave],N'' as [VirtualColumn],N'0' as [GridTypeview],N'0' as [selectionMode],N'0' as [deleteMode],N'0' as [ClearDataBeforeLoadData],N'False' as [LockSort],N'' as [HightLightControlProc],N'' as [ScriptInit0],N'' as [ScriptInit1],N'' as [ScriptInit2],N'' as [ScriptInit3],N'' as [ScriptInit4],N'' as [ScriptInit5],N'' as [ScriptInit6],N'' as [ScriptInit7],N'' as [ScriptInit8],N'' as [ScriptInit9],N'0' as [FontSizeZoom0],N'0' as [FontSizeZoom1],N'0' as [FontSizeZoom2],N'0' as [FontSizeZoom3],N'0' as [FontSizeZoom4],N'0' as [FontSizeZoom5],N'0' as [FontSizeZoom6],N'0' as [FontSizeZoom7],N'0' as [FontSizeZoom8],N'0' as [FontSizeZoom9],N'False' as [NotBuildForm],N'False' as [NotUseCancelButton],N'0' as [GridUICompact],N'' as [DisableFilterColumns],N'0' as [DisableFilterAll]

EXEC sp_SaveData  @TableNameTmp = '#tblDataSetting' , @TableName = 'tblDataSetting' , @Command = 'insert,update' , @IsDropTableTmp =0,@IsPrint=0
IF OBJECT_ID('tempdb..#tblDataSetting') IS NOT NULL DROP TABLE #tblDataSetting
--#endregion _
GO

--#region tblDataSettingLayout
IF OBJECT_ID('tempdb..#tblDataSettingLayout') IS NOT NULL DROP TABLE #tblDataSettingLayout
  create table #tblDataSettingLayout (
   [TableName] [nvarchar](MAX) NULL 
 , [Name] [nvarchar](MAX) NULL 
 , [ControlName] [nvarchar](MAX) NULL 
 , [NamePa] [nvarchar](MAX) NULL 
 , [TabbedGroupParentName] [nvarchar](MAX) NULL 
 , [Type] [nvarchar](MAX) NULL 
 , [Lx] [int] NULL 
 , [Ly] [int] NULL 
 , [Sx] [int] NULL 
 , [Sy] [int] NULL 
 , [ShowCaption] [int] NULL 
 , [Padding] [int] NULL 
 , [TextLocation] [nvarchar](MAX) NULL 
 , [GroupBordersVisible] [int] NULL 
 , [TypeLayout] [nvarchar](MAX) NULL 
 , [Spacing] [int] NULL 
 , [BackColor] [nvarchar](MAX) NULL 
 , [ControlType] [nvarchar](MAX) NULL 
 , [ColumnSpan] [int] NULL 
 , [RowSpan] [int] NULL 
 , [CaptionHorizontalAlign] [nvarchar](MAX) NULL 
 , [CaptionVerticalAlign] [nvarchar](MAX) NULL 
 , [WidthPercentage] [int] NULL 
 , [FixMinSize] [bit] NULL 
 , [AlignContent] [nvarchar](MAX) NULL 
 , [BorderBottomColor] [nvarchar](MAX) NULL 
 , [BorderBottomSize] [nvarchar](MAX) NULL 
 , [BorderColor] [nvarchar](MAX) NULL 
 , [BorderLeftColor] [nvarchar](MAX) NULL 
 , [BorderLeftSize] [nvarchar](MAX) NULL 
 , [BorderRightColor] [nvarchar](MAX) NULL 
 , [BorderRightSize] [nvarchar](MAX) NULL 
 , [BorderSize] [nvarchar](MAX) NULL 
 , [BorderTopColor] [nvarchar](MAX) NULL 
 , [BorderTopSize] [nvarchar](MAX) NULL 
 , [BorderVisible] [bit] NULL 
 , [ControlBackColor] [nvarchar](MAX) NULL 
 , [ControlBorderBottomColor] [nvarchar](MAX) NULL 
 , [ControlBorderBottomSize] [nvarchar](MAX) NULL 
 , [ControlBorderColor] [nvarchar](MAX) NULL 
 , [ControlBorderLeftColor] [nvarchar](MAX) NULL 
 , [ControlBorderLeftSize] [nvarchar](MAX) NULL 
 , [ControlBorderRightColor] [nvarchar](MAX) NULL 
 , [ControlBorderRightSize] [nvarchar](MAX) NULL 
 , [ControlBorderSize] [nvarchar](MAX) NULL 
 , [ControlBorderTopColor] [nvarchar](MAX) NULL 
 , [ControlBorderTopSize] [nvarchar](MAX) NULL 
 , [ControlForeColor] [nvarchar](MAX) NULL 
 , [ControlHorizontalAlign] [nvarchar](MAX) NULL 
 , [ControlPadding] [int] NULL 
 , [ControlVerticalAlign] [nvarchar](MAX) NULL 
 , [FontSize] [nvarchar](MAX) NULL 
 , [IconName] [nvarchar](MAX) NULL 
 , [ItemBackColor] [nvarchar](MAX) NULL 
 , [ItemBorderBottomColor] [nvarchar](MAX) NULL 
 , [ItemBorderBottomSize] [nvarchar](MAX) NULL 
 , [ItemBorderColor] [nvarchar](MAX) NULL 
 , [ItemBorderLeftColor] [nvarchar](MAX) NULL 
 , [ItemBorderLeftSize] [nvarchar](MAX) NULL 
 , [ItemBorderRightColor] [nvarchar](MAX) NULL 
 , [ItemBorderRightSize] [nvarchar](MAX) NULL 
 , [ItemBorderSize] [nvarchar](MAX) NULL 
 , [ItemBorderTopColor] [nvarchar](MAX) NULL 
 , [ItemBorderTopSize] [nvarchar](MAX) NULL 
 , [ItemForeColor] [nvarchar](MAX) NULL 
 , [ItemPadding] [int] NULL 
 , [MinGridPageSize] [int] NULL 
 , [NotClientVisible] [bit] NULL 
 , [NullTextMessageID] [nvarchar](MAX) NULL 
 , [FullPageEmpty] [bit] NULL 
 , [PaddingTop] [int] NULL 
 , [PaddingLeft] [int] NULL 
 , [PaddingBottom] [int] NULL 
 , [PaddingRight] [int] NULL 
 , [ControlCellPadding] [int] NULL 
 , [MaxWidth] [float] NULL 
 , [MinWidth] [float] NULL 
 , [TabPageOrder] [int] NULL 
 , [SelectedTabPageIndex] [int] NULL 
 , [FixWidthClient] [int] NULL 
 , [ErrorMessage] [nvarchar](MAX) NULL 
 , [borderRadius] [nvarchar](MAX) NULL 
 , [boxShadow] [nvarchar](MAX) NULL 
 , [IsValidation] [bit] NULL 
 , [HorizontalAlign] [nvarchar](MAX) NULL 
 , [maxHeight] [int] NULL 
 , [TextAlignMode] [int] NULL 
 , [minHeight] [int] NULL 
 , [HeightPercentageClient] [float] NULL 
 , [ControlBorderRadius] [nvarchar](MAX) NULL 
 , [ControlBoxShadow] [nvarchar](MAX) NULL 
 , [ControlPaddingBottom] [float] NULL 
 , [ControlPaddingLeft] [float] NULL 
 , [ControlPaddingRight] [float] NULL 
 , [ControlPaddingTop] [float] NULL 
 , [ForeColor] [nvarchar](MAX) NULL 
 , [CaptionWrap] [int] NULL 
 , [LocationID] [int] NULL 
 , [ContainerType] [int] NULL 
 , [ControlNoBorder] [bit] NULL 
 , [BackgroundImage] varbinary(max) NULL 
 , [labelMode] [int] NULL 
 , [selectionMode] [int] NULL 
 , [deleteMode] [int] NULL 
)

 INSERT INTO #tblDataSettingLayout([TableName],[Name],[ControlName],[NamePa],[TabbedGroupParentName],[Type],[Lx],[Ly],[Sx],[Sy],[ShowCaption],[Padding],[TextLocation],[GroupBordersVisible],[TypeLayout],[Spacing],[BackColor],[ControlType],[ColumnSpan],[RowSpan],[CaptionHorizontalAlign],[CaptionVerticalAlign],[WidthPercentage],[FixMinSize],[AlignContent],[BorderBottomColor],[BorderBottomSize],[BorderColor],[BorderLeftColor],[BorderLeftSize],[BorderRightColor],[BorderRightSize],[BorderSize],[BorderTopColor],[BorderTopSize],[BorderVisible],[ControlBackColor],[ControlBorderBottomColor],[ControlBorderBottomSize],[ControlBorderColor],[ControlBorderLeftColor],[ControlBorderLeftSize],[ControlBorderRightColor],[ControlBorderRightSize],[ControlBorderSize],[ControlBorderTopColor],[ControlBorderTopSize],[ControlForeColor],[ControlHorizontalAlign],[ControlPadding],[ControlVerticalAlign],[FontSize],[IconName],[ItemBackColor],[ItemBorderBottomColor],[ItemBorderBottomSize],[ItemBorderColor],[ItemBorderLeftColor],[ItemBorderLeftSize],[ItemBorderRightColor],[ItemBorderRightSize],[ItemBorderSize],[ItemBorderTopColor],[ItemBorderTopSize],[ItemForeColor],[ItemPadding],[MinGridPageSize],[NotClientVisible],[NullTextMessageID],[FullPageEmpty],[PaddingTop],[PaddingLeft],[PaddingBottom],[PaddingRight],[ControlCellPadding],[MaxWidth],[MinWidth],[TabPageOrder],[SelectedTabPageIndex],[FixWidthClient],[ErrorMessage],[borderRadius],[boxShadow],[IsValidation],[HorizontalAlign],[maxHeight],[TextAlignMode],[minHeight],[HeightPercentageClient],[ControlBorderRadius],[ControlBoxShadow],[ControlPaddingBottom],[ControlPaddingLeft],[ControlPaddingRight],[ControlPaddingTop],[ForeColor],[CaptionWrap],[LocationID],[ContainerType],[ControlNoBorder],[BackgroundImage],[labelMode],[selectionMode],[deleteMode])
Select  N'sp_tblMST_ContractType' as [TableName],N'btnexport' as [Name],N'btnexport' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'903' as [Ly],N'923' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#336633' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'Export' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'btnfwadd' as [Name],N'btnfwadd' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'783' as [Ly],N'923' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#339933' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'AddNew' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'btnfwreset' as [Name],N'btnfwreset' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'863' as [Ly],N'923' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#FFC000' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'refresh' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'btnfwsave' as [Name],N'btnfwsave' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'823' as [Ly],N'923' as [Sx],N'40' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#25205E' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'Save' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'lblfilter' as [Name],N'txtfilter' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'24' as [Ly],N'923' as [Sx],N'22' as [Sy],N'1' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'PopupContainerEdit' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'lblreload' as [Name],N'btnreload' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'0' as [Ly],N'923' as [Sx],N'24' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleButton' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#339933' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'lbltableeditor' as [Name],N'grdtableeditor' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'46' as [Ly],N'923' as [Sx],N'737' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'default' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'GridControl' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'1' as [PaddingTop],N'1' as [PaddingLeft],N'1' as [PaddingBottom],N'1' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'0' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'root' as [Name],N'' as [ControlName],N'' as [NamePa],N'' as [TabbedGroupParentName],N'g' as [Type],N'0' as [Lx],N'0' as [Ly],N'923' as [Sx],N'943' as [Sy],N'0' as [ShowCaption],N'0' as [Padding],N'top' as [TextLocation],N'0' as [GroupBordersVisible],N'1' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'' as [ControlType],N'0' as [ColumnSpan],N'0' as [RowSpan],N'default' as [CaptionHorizontalAlign],N'default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'0' as [PaddingTop],N'0' as [PaddingLeft],N'0' as [PaddingBottom],N'0' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'-1' as [TabPageOrder],N'0' as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'btnexport' as [Name],N'btnexport' as [ControlName],N'plg_fwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'828' as [Lx],N'0' as [Ly],N'276' as [Sx],N'35' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'20' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#336633' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'Export' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'btnfwadd' as [Name],N'btnfwadd' as [ControlName],N'plg_fwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'0' as [Ly],N'263' as [Sx],N'35' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'19' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#339933' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'AddNew' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'btnfwreset' as [Name],N'btnfwreset' as [ControlName],N'plg_fwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'552' as [Lx],N'0' as [Ly],N'276' as [Sx],N'35' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'20' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#FFC000' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'refresh' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'btnfwsave' as [Name],N'btnfwsave' as [ControlName],N'plg_fwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'263' as [Lx],N'0' as [Ly],N'289' as [Sx],N'35' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'SimpleFWButton' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'20' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#25205E' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'Save' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'lblfilter' as [Name],N'txtfilter' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'460' as [Lx],N'0' as [Ly],N'920' as [Sx],N'31' as [Sy],N'1' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'PopupContainerEdit' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'67' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'lblreload' as [Name],N'btnreload' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'0' as [Ly],N'460' as [Sx],N'31' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'ParadiseSimpleButtonBase' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'33' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'#339933' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'#FFFFFF' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'lbltableeditor' as [Name],N'grdtableeditor' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'i' as [Type],N'0' as [Lx],N'31' as [Ly],N'1380' as [Sx],N'764' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'GridControl' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblmst_contracttype' as [TableName],N'petfwcommand' as [Name],N'' as [ControlName],N'plg_fwcommand' as [NamePa],N'' as [TabbedGroupParentName],N'' as [Type],N'1104' as [Lx],N'0' as [Ly],N'276' as [Sx],N'35' as [Sy],N'0' as [ShowCaption],N'3' as [Padding],N'Default' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'21' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'3' as [PaddingTop],N'3' as [PaddingLeft],N'3' as [PaddingBottom],N'3' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],NULL as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],N'0' as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblmst_contracttype' as [TableName],N'plg_fwcommand' as [Name],N'' as [ControlName],N'root' as [NamePa],N'' as [TabbedGroupParentName],N'g' as [Type],N'0' as [Lx],N'795' as [Ly],N'1380' as [Sx],N'35' as [Sy],N'0' as [ShowCaption],N'0' as [Padding],N'Top' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'0' as [PaddingTop],N'0' as [PaddingLeft],N'0' as [PaddingBottom],N'0' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'-1' as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],NULL as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode] UNION ALL

Select  N'sp_tblMST_ContractType' as [TableName],N'root' as [Name],N'' as [ControlName],N'' as [NamePa],N'' as [TabbedGroupParentName],N'g' as [Type],N'0' as [Lx],N'0' as [Ly],N'1380' as [Sx],N'830' as [Sy],N'0' as [ShowCaption],N'0' as [Padding],N'Top' as [TextLocation],N'0' as [GroupBordersVisible],N'6' as [TypeLayout],N'0' as [Spacing],N'' as [BackColor],N'' as [ControlType],NULL as [ColumnSpan],NULL as [RowSpan],N'Default' as [CaptionHorizontalAlign],N'Default' as [CaptionVerticalAlign],N'100' as [WidthPercentage],N'False' as [FixMinSize],N'' as [AlignContent],N'' as [BorderBottomColor],N'' as [BorderBottomSize],N'' as [BorderColor],N'' as [BorderLeftColor],N'' as [BorderLeftSize],N'' as [BorderRightColor],N'' as [BorderRightSize],N'' as [BorderSize],N'' as [BorderTopColor],N'' as [BorderTopSize],N'False' as [BorderVisible],N'' as [ControlBackColor],N'' as [ControlBorderBottomColor],N'' as [ControlBorderBottomSize],N'' as [ControlBorderColor],N'' as [ControlBorderLeftColor],N'' as [ControlBorderLeftSize],N'' as [ControlBorderRightColor],N'' as [ControlBorderRightSize],N'' as [ControlBorderSize],N'' as [ControlBorderTopColor],N'' as [ControlBorderTopSize],N'' as [ControlForeColor],N'' as [ControlHorizontalAlign],N'0' as [ControlPadding],N'' as [ControlVerticalAlign],N'' as [FontSize],N'' as [IconName],N'' as [ItemBackColor],N'' as [ItemBorderBottomColor],N'' as [ItemBorderBottomSize],N'' as [ItemBorderColor],N'' as [ItemBorderLeftColor],N'' as [ItemBorderLeftSize],N'' as [ItemBorderRightColor],N'' as [ItemBorderRightSize],N'' as [ItemBorderSize],N'' as [ItemBorderTopColor],N'' as [ItemBorderTopSize],N'' as [ItemForeColor],N'0' as [ItemPadding],N'0' as [MinGridPageSize],N'False' as [NotClientVisible],N'' as [NullTextMessageID],N'False' as [FullPageEmpty],N'0' as [PaddingTop],N'0' as [PaddingLeft],N'0' as [PaddingBottom],N'0' as [PaddingRight],N'0' as [ControlCellPadding],N'0' as [MaxWidth],N'0' as [MinWidth],N'-1' as [TabPageOrder],NULL as [SelectedTabPageIndex],N'0' as [FixWidthClient],N'' as [ErrorMessage],N'' as [borderRadius],N'' as [boxShadow],N'False' as [IsValidation],N'' as [HorizontalAlign],N'0' as [maxHeight],NULL as [TextAlignMode],N'0' as [minHeight],N'0' as [HeightPercentageClient],N'' as [ControlBorderRadius],N'' as [ControlBoxShadow],N'0' as [ControlPaddingBottom],N'0' as [ControlPaddingLeft],N'0' as [ControlPaddingRight],N'0' as [ControlPaddingTop],N'' as [ForeColor],N'0' as [CaptionWrap],N'0' as [LocationID],N'0' as [ContainerType],N'False' as [ControlNoBorder],NULL as [BackgroundImage],N'0' as [labelMode],N'0' as [selectionMode],N'0' as [deleteMode]

DECLARE @sql VARCHAR(MAX) = 'TableName'+char(10)+'TypeLayout'
EXEC sp_SaveData  @TableNameTmp = '#tblDataSettingLayout' , @TableName = 'tblDataSettingLayout' , @Command = 'DeleteNot',@ColumnDeleteNot=@sql , @IsDropTableTmp =0,@IsPrint=0
EXEC sp_SaveData  @TableNameTmp = '#tblDataSettingLayout' , @TableName = 'tblDataSettingLayout' , @Command = 'insert,update', @IsDropTableTmp =0,@IsPrint=0
IF OBJECT_ID('tempdb..#tblDataSettingLayout') IS NOT NULL DROP TABLE #tblDataSettingLayout
--#endregion _
GO

--#region tblMD_Message
IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message 
IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message
  create table #tblMD_Message (
   [MessageID] [nvarchar](MAX) NULL 
 , [Language] [nvarchar](MAX) NULL 
 , [Content] [nvarchar](MAX) NULL 
 , [Frequency] [bigint] NULL 
 , [IgnorePending] [bit] NULL 
)

 INSERT INTO #tblMD_Message([MessageID],[Language],[Content],[Frequency],[IgnorePending])
Select  N'sp_tblMST_ContractType.Duration' as [MessageID],N'CN' as [Language],N'学期（月）' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Limit' as [MessageID],N'CN' as [Language],N'有一个名词' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.RemainDayNotification' as [MessageID],N'CN' as [Language],N'提前通知（天）' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ShortTermTax' as [MessageID],N'CN' as [Language],N'短期' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ContractName' as [MessageID],N'EN' as [Language],N'Contract name (VN)' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ContractPrefix' as [MessageID],N'EN' as [Language],N'Contract Prefix' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Duration' as [MessageID],N'EN' as [Language],N'Term (month)' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Limit' as [MessageID],N'EN' as [Language],N'There is a term' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.RemainDayNotification' as [MessageID],N'EN' as [Language],N'Notification end contract remain in days' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ShortTermTax' as [MessageID],N'EN' as [Language],N'Short term tax' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Duration' as [MessageID],N'VN' as [Language],N'Thời hạn (tháng)' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Limit' as [MessageID],N'VN' as [Language],N'Có thời hạn' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblmst_contracttype.petFWCommand' as [MessageID],N'VN' as [Language],N'petFWCommand' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblmst_contracttype.plg_FWCommand' as [MessageID],N'VN' as [Language],N'plg_fwcommand:vn' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.RemainDayNotification' as [MessageID],N'VN' as [Language],N'T.báo trước (ngày)' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblmst_contracttype.ShortTermTax' as [MessageID],N'VN' as [Language],N'Tính thuế 10%
(Mặc định lũy tiến)' as [Content],N'0' as [Frequency],NULL as [IgnorePending]
EXEC sp_SaveData  @TableNameTmp = '#tblMD_Message' , @TableName = 'tblMD_Message' , @Command = 'insert,update' , @IsDropTableTmp =0,@IsPrint=0IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message
--#endregion _
GO

--#region tblMD_Message
IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message 
IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message
  create table #tblMD_Message (
   [MessageID] [nvarchar](MAX) NULL 
 , [Language] [nvarchar](MAX) NULL 
 , [Content] [nvarchar](MAX) NULL 
 , [Frequency] [bigint] NULL 
 , [IgnorePending] [bit] NULL 
)

 INSERT INTO #tblMD_Message([MessageID],[Language],[Content],[Frequency],[IgnorePending])
Select  N'0' as [MessageID],N'CN' as [Language],N'零' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0' as [MessageID],N'En' as [Language],N'Không đi làm' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0' as [MessageID],N'KR' as [Language],N'Không đi làm' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0' as [MessageID],N'vn' as [Language],N'Không đi làm' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0.vldt' as [MessageID],N'En' as [Language],N'Không đi làm' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0.vldt' as [MessageID],N'KR' as [Language],N'Không đi làm' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'0.vldt' as [MessageID],N'vn' as [Language],N'Không đi làm' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1' as [MessageID],N'EN' as [Language],N'Seniority allowance (long term)' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1' as [MessageID],N'VN' as [Language],N'Seniority allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1.vldt' as [MessageID],N'EN' as [Language],N'1' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1.vldt' as [MessageID],N'KR' as [Language],N'1' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'1.vldt' as [MessageID],N'VN' as [Language],N'1' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2' as [MessageID],N'EN' as [Language],N'Production bonus' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2' as [MessageID],N'VN' as [Language],N'Production bonus' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2.vldt' as [MessageID],N'EN' as [Language],N'2' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2.vldt' as [MessageID],N'KR' as [Language],N'2' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'2.vldt' as [MessageID],N'VN' as [Language],N'2' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3' as [MessageID],N'EN' as [Language],N'Foreign language allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3' as [MessageID],N'VN' as [Language],N'Foreign language allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3.vldt' as [MessageID],N'EN' as [Language],N'3' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3.vldt' as [MessageID],N'KR' as [Language],N'3' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'3.vldt' as [MessageID],N'VN' as [Language],N'3' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4' as [MessageID],N'EN' as [Language],N'Environmental allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4' as [MessageID],N'VN' as [Language],N'Environmental allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4.vldt' as [MessageID],N'EN' as [Language],N'4' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4.vldt' as [MessageID],N'KR' as [Language],N'4' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'4.vldt' as [MessageID],N'VN' as [Language],N'4' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5' as [MessageID],N'EN' as [Language],N'Shift allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5' as [MessageID],N'VN' as [Language],N'Shift allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5.vldt' as [MessageID],N'EN' as [Language],N'5' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5.vldt' as [MessageID],N'KR' as [Language],N'5' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'5.vldt' as [MessageID],N'VN' as [Language],N'5' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6' as [MessageID],N'EN' as [Language],N'Fuel allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6' as [MessageID],N'VN' as [Language],N'Fuel allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6.vldt' as [MessageID],N'EN' as [Language],N'5' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6.vldt' as [MessageID],N'KR' as [Language],N'5' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'6.vldt' as [MessageID],N'VN' as [Language],N'6' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7' as [MessageID],N'EN' as [Language],N'Professional allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7' as [MessageID],N'VN' as [Language],N'Professional allowance' as [Content],NULL as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7.vldt' as [MessageID],N'EN' as [Language],N'7' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7.vldt' as [MessageID],N'KR' as [Language],N'7' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'7.vldt' as [MessageID],N'VN' as [Language],N'7' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'CN' as [Language],N'导出到Excel' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'EN' as [Language],N'Export to excel' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'JP' as [Language],N'リセット' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'KO' as [Language],N'엑셀로 내보내기' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'KR' as [Language],N'Export to excel' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnExport' as [MessageID],N'VN' as [Language],N'Xuất excel' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'CN' as [Language],N'新增' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'EN' as [Language],N'Add new' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'JP' as [Language],N'追加' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'KO' as [Language],N'새로 추가' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'KR' as [Language],N'Add new' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWAdd' as [MessageID],N'VN' as [Language],N'Thêm mới' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'CN' as [Language],N'重做' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'EN' as [Language],N'Reset' as [Content],N'34' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'JP' as [Language],N'リセット' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'KO' as [Language],N'재실행' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'KR' as [Language],N'Reset' as [Content],N'34' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWReset' as [MessageID],N'VN' as [Language],N'Làm lại' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'CN' as [Language],N'保存数据' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'EN' as [Language],N'Save' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'JP' as [Language],N'保存' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'KO' as [Language],N'저장' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'BtnfwSave' as [MessageID],N'KR' as [Language],N'저장' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnFWSave' as [MessageID],N'VN' as [Language],N'Lưu' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnReload' as [MessageID],N'CN' as [Language],N'重新載入資料' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnReload' as [MessageID],N'EN' as [Language],N'Refresh' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnReload' as [MessageID],N'KO' as [Language],N'새로 고침' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'BtnReload' as [MessageID],N'KR' as [Language],N'새로 만들기' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'btnReload' as [MessageID],N'VN' as [Language],N'Làm Mới' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ContractName' as [MessageID],N'CN' as [Language],N'合同名称' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ContractName' as [MessageID],N'EN' as [Language],N'Contract name' as [Content],N'263' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ContractName' as [MessageID],N'VN' as [Language],N'Tên hợp đồng' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ContractNameEN' as [MessageID],N'EN' as [Language],N'Contract Name' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ContractNameEN' as [MessageID],N'VN' as [Language],N'Tên HĐ tiếng anh' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ContractPrefix' as [MessageID],N'VN' as [Language],N'ContractPrefix VN' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ContractTemplateList' as [MessageID],N'EN' as [Language],N'Template' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ContractTemplateList' as [MessageID],N'VN' as [Language],N'Mẫu hợp đồng' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Duration' as [MessageID],N'CN' as [Language],N'期限' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Duration' as [MessageID],N'EN' as [Language],N'Duration' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Duration' as [MessageID],N'VN' as [Language],N'Thời hạn' as [Content],N'1' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'grdTableEditor' as [MessageID],N'EN' as [Language],N'Training course list' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'grdTableEditor' as [MessageID],N'KR' as [Language],N'Training course list' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'grdTableEditor' as [MessageID],N'VN' as [Language],N'Danh sách đơn chờ duyệt' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'CN' as [Language],N'搜索' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'EN' as [Language],N'Search' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'KO' as [Language],N'검색' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'KR' as [Language],N'검색' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblFilter' as [MessageID],N'VN' as [Language],N'Tìm kiếm' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'CN' as [Language],N'影片播放清单' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'EN' as [Language],N'Resident address' as [Content],N'2' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'KO' as [Language],N'코드' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'KR' as [Language],N'Resident address' as [Content],N'2' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblReload' as [MessageID],N'VN' as [Language],N'Làm Mới' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'CN' as [Language],N'<color = crimson>如果更改标题，请单击新行以添加。生效日期无法更正，因此，如果生效日期不正确，请删除错误的行，然后添加一个新行以进行更正。</ color>' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'EN' as [Language],N'<color = crimson> If you change the title, click on a new line to add it. The effective date cannot be edited, so if the effective date is wrong, delete the wrong line, then add a new line to correct. </color>' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'KO' as [Language],N'<color = crimson> 제목을 변경하는 경우 추가 할 새 줄을 클릭하십시오. 유효 날짜를 편집 할 수 없으므로 유효 날짜가 틀린 경우 잘못된 줄을 삭제 한 다음 올바른 새 줄을 추가하십시오. </ color>' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'KR' as [Language],N'<color = crimson> If you change the title, click on a new line to add it. The effective date cannot be edited, so if the effective date is wrong, delete the wrong line, then add a new line to correct. </color>' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'lblTableEditor' as [MessageID],N'VN' as [Language],N'<color=crimson>Nếu thay đổi chức danh thì bấm vào dòng mới để thêm.Ngày hiệu lực không sửa được nên nếu ngày hiệu lực sai thì xóa dòng sai đi, sau đó thêm 1 dòng mới cho đúng.</color>' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Limit' as [MessageID],N'CN' as [Language],N'适用范围' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Limit' as [MessageID],N'EN' as [Language],N'Limit' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Limit' as [MessageID],N'VN' as [Language],N'Giới hạn' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'MnuMDT238' as [MessageID],N'CN' as [Language],N'合同类型表' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'MnuMDT238' as [MessageID],N'EN' as [Language],N'Contract type table' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'MnuMDT238' as [MessageID],N'VN' as [Language],N'Loại hợp đồng' as [Content],N'100000' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'petFWCommand' as [MessageID],N'CN' as [Language],N'petFWCommand' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'petFWCommand' as [MessageID],N'EN' as [Language],N'petFWCommand' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'petFWCommand' as [MessageID],N'KO' as [Language],N'petFWCommand' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'petFWCommand' as [MessageID],N'VN' as [Language],N'petFWCommand' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'plg_FWCommand' as [MessageID],N'EN' as [Language],N'plg_fwcommand:en' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'plg_FWCommand' as [MessageID],N'VN' as [Language],N'plg_fwcommand:vn' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'RemainDayNotification' as [MessageID],N'EN' as [Language],N'Notification end contract remai in days' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'RemainDayNotification' as [MessageID],N'VN' as [Language],N'T.báo trước' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Root' as [MessageID],N'CN' as [Language],N'根目錄' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Root' as [MessageID],N'EN' as [Language],N'Root' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Root' as [MessageID],N'KR' as [Language],N'Resident address' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'Root' as [MessageID],N'VN' as [Language],N'1' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ShortTermTax' as [MessageID],N'CN' as [Language],N'短期' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'ShortTermTax' as [MessageID],N'VN' as [Language],N'Tham gia tính thuế' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.band_contractnameen' as [MessageID],N'EN' as [Language],N'contractnameen:Missing' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.band_limit' as [MessageID],N'EN' as [Language],N'limit:Missing' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.band_shorttermtax' as [MessageID],N'EN' as [Language],N'shorttermtax:Missing' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ckbAllLimit' as [MessageID],N'EN' as [Language],N'All Limited' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ckbAllShortTermTax' as [MessageID],N'EN' as [Language],N'All Short term' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblmst_contracttype.ContractCode' as [MessageID],N'VN' as [Language],N'Mã hợp đồng' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ContractName' as [MessageID],N'EN' as [Language],N'Contract name (VN)' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ContractPrefix' as [MessageID],N'EN' as [Language],N'Contract Prefix' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Duration' as [MessageID],N'CN' as [Language],N'学期（月）' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Duration' as [MessageID],N'EN' as [Language],N'Term (month)' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Duration' as [MessageID],N'VN' as [Language],N'Thời hạn (tháng)' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.lblAllLimit' as [MessageID],N'EN' as [Language],N'All Limited' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.lblAllShortTermTax' as [MessageID],N'EN' as [Language],N'All Short term' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Limit' as [MessageID],N'CN' as [Language],N'有一个名词' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Limit' as [MessageID],N'EN' as [Language],N'There is a term' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.Limit' as [MessageID],N'VN' as [Language],N'Có thời hạn' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblmst_contracttype.petFWCommand' as [MessageID],N'VN' as [Language],N'petFWCommand' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblmst_contracttype.plg_FWCommand' as [MessageID],N'VN' as [Language],N'plg_fwcommand:vn' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.RemainDayNotification' as [MessageID],N'CN' as [Language],N'提前通知（天）' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.RemainDayNotification' as [MessageID],N'EN' as [Language],N'Notification end contract remain in days' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.RemainDayNotification' as [MessageID],N'VN' as [Language],N'T.báo trước (ngày)' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ShortTermTax' as [MessageID],N'CN' as [Language],N'短期' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.ShortTermTax' as [MessageID],N'EN' as [Language],N'Short term tax' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblmst_contracttype.ShortTermTax' as [MessageID],N'VN' as [Language],N'Tính thuế 10%
(Mặc định lũy tiến)' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'sp_tblMST_ContractType.SPName' as [MessageID],N'VN' as [Language],N'SPName VN' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'txtFilter' as [MessageID],N'CN' as [Language],N'筛选条件' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'txtFilter' as [MessageID],N'EN' as [Language],N'Filter' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'txtFilter' as [MessageID],N'KR' as [Language],N'검색' as [Content],N'0' as [Frequency],NULL as [IgnorePending] UNION ALL

Select  N'txtFilter' as [MessageID],N'VN' as [Language],N'Tìm kiếm' as [Content],N'0' as [Frequency],NULL as [IgnorePending]
EXEC sp_SaveData  @TableNameTmp = '#tblMD_Message' , @TableName = 'tblMD_Message' , @Command = 'insert' , @IsDropTableTmp =0,@IsPrint=0IF OBJECT_ID('tempdb..#tblMD_Message') IS NOT NULL DROP TABLE #tblMD_Message
--#endregion _

DELETE FROM tblRepresentativeSetting

insert into tblRepresentativeSetting(CommitmentKind,RepresentativeName,Sex,PositionName,PositionNameEN,Nationality,NationallityEN,PassportNo,P_IssueDate,P_IssuePlace,ID_Number,ID_Issue_Date,ID_Issue_Place,ID_Issue_PlaceEN,ID_ProvinceID,ResidentAdd,ResidentAddEN,tmpAddress,tmpAddressEN,Activated)
select CommitmentKind,RepresentativeName,Sex,PositionName,PositionNameEN,Nationality,NationallityEN,PassportNo,P_IssueDate,P_IssuePlace,ID_Number,ID_Issue_Date,ID_Issue_Place,ID_Issue_PlaceEN,ID_ProvinceID,ResidentAdd,ResidentAddEN,tmpAddress,tmpAddressEN,Activated
from (	select CAST(N'HDLD' as varchar(30)) CommitmentKind,CAST(N'LU CHENG MING' as nvarchar(50)) RepresentativeName,CAST(1 as bit) Sex,CAST(N'Tổng giám đốc' as nvarchar(50)) PositionName,CAST(N'General Director' as nchar(100)) PositionNameEN,CAST(N'Trung Quốc (Đài Loan)' as nvarchar(50)) Nationality,CAST(N'Chinese (Taiwanese)' as nvarchar(50)) NationallityEN,CAST(N'99999999' as varchar(25)) PassportNo,CAST(N'2017-11-01' as datetime) P_IssueDate,CAST(N'Ho Chi Minh' as nvarchar(50)) P_IssuePlace,CAST(NULL as varchar(20)) ID_Number,CAST(N'2017-11-22' as datetime) ID_Issue_Date,CAST(NULL as nvarchar(1000)) ID_Issue_Place,CAST(NULL as nvarchar(1000)) ID_Issue_PlaceEN,CAST(NULL as nvarchar(500)) ID_ProvinceID,CAST(NULL as nvarchar(500)) ResidentAdd,CAST(NULL as nvarchar(500)) ResidentAddEN,CAST(N'' as nvarchar(500)) tmpAddress,CAST(N'' as nvarchar(500)) tmpAddressEN,CAST(1 as bit) Activated) tmpData

DELETE FROM tblMST_ContractType
insert into tblMST_ContractType(ContractCode,ContractName,ContractNameEN,Limit,Duration,ContributeSI,Percentage,ContributeJI,TemplateContract,TemplateContract2,TemplateContract3,SPName,ContractPrefix,RemainDayNotification,ShortTermTax,ContractTemplateList,DefaultDuration,Ord,ProMonth13Data,ContractNameCN)
select ContractCode,ContractName,ContractNameEN,Limit,Duration,ContributeSI,Percentage,ContributeJI,TemplateContract,TemplateContract2,TemplateContract3,SPName,ContractPrefix,RemainDayNotification,ShortTermTax,ContractTemplateList,DefaultDuration,Ord,ProMonth13Data,ContractNameCN
from (	select CAST(N'003' as varchar(10)) ContractCode,CAST(N'Indefinite' as nvarchar(50)) ContractName,CAST(N'Indefinite Contract' as nvarchar(100)) ContractNameEN,CAST(0 as bit) Limit,CAST(0.0 as float) Duration,CAST(1 as bit) ContributeSI,CAST(28.500000000000000 as float) Percentage,CAST(1 as bit) ContributeJI,CAST(NULL as varchar(50)) TemplateContract,CAST(N'' as varchar(100)) TemplateContract2,CAST(NULL as varchar(100)) TemplateContract3,CAST(N'sp_CrystalRptLabourContract' as varchar(100)) SPName,CAST(N'' as varchar(50)) ContractPrefix,CAST(30 as int) RemainDayNotification,CAST(0 as bit) ShortTermTax,CAST(N'LabourContractIndefinite' as nvarchar(max)) ContractTemplateList,CAST(NULL as int) DefaultDuration,CAST(NULL as int) Ord,CAST(NULL as bit) ProMonth13Data,CAST(NULL as nvarchar(255)) ContractNameCN	union all select N'004',N'Probation',N'Probation',1,2.0,0,0.0,0,NULL,NULL,NULL,N'sp_CrystalRptLabourContract',N'',20,1,N'ProbationContract',NULL,NULL,NULL,NULL	union all select N'006',N'Definite',N'Definite Contract',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,N'LabourContractDefinite',12,NULL,NULL,NULL	union all select N'007',N'1st year',N'Definite Contract 1st year',1,12.0,1,NULL,1,NULL,NULL,NULL,NULL,N'',20,0,N'LabourContractDefinite1st',12,NULL,NULL,NULL	union all select N'008',N'2nd year',N'Definite Contract 2nd year',1,24.0,1,NULL,1,NULL,NULL,NULL,NULL,N'',20,0,N'LabourContractDefinite2nd',NULL,NULL,NULL,NULL	union all select N'009',N'Temporary',N'Temporary Contract',1,1.0,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL) tmpData

DELETE FROM tblExportList WHERE ExportName IN ('LabourContractIndefinite', 'ProbationContract','LabourContractDefinite','LabourContractDefinite1st','LabourContractDefinite2nd')


insert into tblExportList(ExportName,Description,ProcedureName,ExportType,TemplateFileName,StartRow,StartColumn,Catalog,ObjectId,Visible,OneSheet,TempStart,TempEnd,TempDataStart,TempRowEmpty,MergeFormat,IsAllBoder,ListSheetMerge,IsExportHeader,MultipleReport,BestFixColumn,BestFixHeaderCount,TemplateSheetIndex,OneHeaderPerRow,NotShowInExportList,InsertCellInsRow,ReloadFormAfterExport,FollowConfigTable,NotRequireSave,IsTemplateImport,RequireCheckHeader,Frequency,LockExportData,DescriptionEN,ProcExportCompleted,ExportMergeEmployeeCount,ProcAfterExport)
select ExportName,Description,ProcedureName,ExportType,TemplateFileName,StartRow,StartColumn,Catalog,ObjectId,Visible,OneSheet,TempStart,TempEnd,TempDataStart,TempRowEmpty,MergeFormat,IsAllBoder,ListSheetMerge,IsExportHeader,MultipleReport,BestFixColumn,BestFixHeaderCount,TemplateSheetIndex,OneHeaderPerRow,NotShowInExportList,InsertCellInsRow,ReloadFormAfterExport,FollowConfigTable,NotRequireSave,IsTemplateImport,RequireCheckHeader,Frequency,LockExportData,DescriptionEN,ProcExportCompleted,ExportMergeEmployeeCount,ProcAfterExport
from (	select CAST(N'LabourContractDefinite' as nvarchar(250)) ExportName,CAST(N'Hợp đồng xác định thời hạn' as nvarchar(100)) Description,CAST(N'sp_PrintLaborContractBlock' as varchar(250)) ProcedureName,CAST(N'Word' as varchar(20)) ExportType,CAST(N'DefiniteTerm_LaborContract.docx' as varchar(250)) TemplateFileName,CAST(NULL as int) StartRow,CAST(NULL as int) StartColumn,CAST(N'HR' as nvarchar(50)) Catalog,CAST(501 as bigint) ObjectId,CAST(0 as bit) Visible,CAST(NULL as bit) OneSheet,CAST(NULL as int) TempStart,CAST(NULL as int) TempEnd,CAST(NULL as int) TempDataStart,CAST(NULL as smallint) TempRowEmpty,CAST(NULL as nvarchar(200)) MergeFormat,CAST(NULL as bit) IsAllBoder,CAST(NULL as nvarchar(200)) ListSheetMerge,CAST(NULL as bit) IsExportHeader,CAST(NULL as bit) MultipleReport,CAST(1 as bit) BestFixColumn,CAST(NULL as int) BestFixHeaderCount,CAST(NULL as int) TemplateSheetIndex,CAST(NULL as int) OneHeaderPerRow,CAST(NULL as bit) NotShowInExportList,CAST(NULL as money) InsertCellInsRow,CAST(NULL as bit) ReloadFormAfterExport,CAST(1 as bit) FollowConfigTable,CAST(NULL as bit) NotRequireSave,CAST(NULL as bit) IsTemplateImport,CAST(NULL as bit) RequireCheckHeader,CAST(53 as int) Frequency,CAST(NULL as bit) LockExportData,CAST(N'Contract definite term' as nvarchar(1000)) DescriptionEN,CAST(NULL as varchar(1000)) ProcExportCompleted,CAST(NULL as int) ExportMergeEmployeeCount,CAST(NULL as varchar(1000)) ProcAfterExport	union all select N'LabourContractDefinite1st',N'LabourContractDefinite1st',N'sp_PrintLaborContractBlock',N'Word',N'DefiniteTerm_LaborContract.docx',NULL,NULL,N'HR',501,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL	union all select N'LabourContractDefinite2nd',N'LabourContractDefinite2nd',N'sp_PrintLaborContractBlock',N'Word',N'DefiniteTerm_LaborContract.docx',NULL,NULL,N'HR',501,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL	union all select N'LabourContractIndefinite',N'Hợp đồng không thời hạn',N'sp_PrintLaborContractBlock',N'Word',N'IndefiniteTerm_LaborContract.docx',NULL,NULL,N'HR',501,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,14,NULL,N'Unlimited contract',NULL,NULL,NULL	union all select N'ProbationContract',N'ProbationContract',N'sp_PrintLaborContractBlock',N'Word',N'ProbationContract_Staff.docx',NULL,NULL,N'HR',501,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,58,NULL,N'ProbationContract',NULL,NULL,NULL) tmpData