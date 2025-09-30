
UPDATE tblProcedureName SET TemplateName = 'ImportAttendanceSheetRawData' WHERE ProcName = 'ImportTimeSheet'

UPDATE tblExportList SET TemplateFileName = 'ImportAttendanceSheetRawData.xlsx' WHERE ExportName = 'Template_ImportTimeSheet'