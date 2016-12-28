VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "GffSheet"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
'Copyright 2007 European Bioinformatics Institute.
'
'Licensed under the Apache License, Version 2.0 (the "License");
'you may not use this file except in compliance with the License.
'You may obtain a copy of the License at
'
'  http://www.apache.org/licenses/LICENSE-2.0
'
'Unless required by applicable law or agreed to in writing, software
'distributed under the License is distributed on an "AS IS" BASIS,
'WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
'See the License for the specific language governing permissions and
'limitations under the License.


Option Explicit
Option Compare Text

'GFF template.
'
'@author  Antony Quinn <aquinn@ebi.ac.uk>
'@version $Id: GffSheet.cls,v 1.3 2007/06/27 15:48:20 aquinn Exp $

'TODO: switch to turn error trap on or off

'General comments formats
Private Const GFF_GLOBAL_COMMENT As String = "##"
Private Const GFF_LINE_COMMENT As String = "#"
'TRANSFOG-specific comments
Private Const GFF_LINE_COMMENT_SYMBOL As String = "symbol="
Private Const GFF_LINE_COMMENT_METHOD As String = "method="
Private Const GFF_LINE_COMMENT_FEATURE As String = "feature="
'Column numbers in GFF file
Private Const GFF_COL_ID As Integer = 0
Private Const GFF_COL_METHOD As Integer = 1
Private Const GFF_COL_FEATURE As Integer = 2
Private Const GFF_COL_START As Integer = 3
Private Const GFF_COL_END As Integer = 4
Private Const GFF_COL_SCORE As Integer = 5
Private Const GFF_COL_STRAND As Integer = 6
Private Const GFF_COL_FRAME As Integer = 7
Private Const GFF_COL_MAX_REQUIRED As Integer = GFF_COL_FRAME
'Attributes column is optional
Private Const GFF_COL_ATTRIBUTES As Integer = 8
'Attributes separator, eg. ID "P38398" ; Note "BRCA1"
Private Const GFF_ATTRIBUTE_SEP As String = ";"
'Attribute names
Private Const GFF_ATTR_ID As String = "ID"
Private Const GFF_ATTR_NAME As String = "Name"
Private Const GFF_ATTR_NOTE As String = "Note"
Private Const GFF_ATTR_TARGET As String = "Target"
Private Const GFF_ATTR_LINK As String = "Link"

'Columns
Private Const COL_SYMBOL As Integer = 1
Private Const COL_ID As Integer = 2
Private Const COL_METHOD As Integer = 3
Private Const COL_TYPE As Integer = 4
Private Const COL_SCORE As Integer = 5
Private Const COL_NOTE As Integer = 6
Private Const COL_TARGET As Integer = 7
Private Const COL_FEATURE As Integer = 8
Private Const COL_URL As Integer = 9
Private Const COL_START As Integer = 10
Private Const COL_END As Integer = 11
Private Const COL_STRAND As Integer = 12
Private Const COL_FRAME As Integer = 13

'Rows
Private Const ROW_START As Integer = 5

'String used for ontology IDs, eg. apoptosis (GO:00006950)
'TODO: Pass these into ontology form
Private Const ID_OPEN As String = "("
Private Const ID_CLOSE As String = ")"

'Cells
Private Const CELL_INFO As String = "C1"
Private Const CELL_PATH As String = "C2"
Private Const CELL_ERROR As String = "C3"

'Defaults
Private Const DEFAULT_SCORE  As Integer = 0
Private Const DEFAULT_START  As Integer = 0
Private Const DEFAULT_END  As Integer = 0
Private Const DEFAULT_STRAND  As String = "."
Private Const DEFAULT_FRAME  As String = "."

' Export
Private Sub btnExport_Click()
    On Error GoTo Error_Trap
    export
    Exit Sub
Error_Trap:
    showError Err.number, "btnExport_Click | " & Err.source, Err.description
End Sub

' Import
Private Sub btnImport_Click()
    On Error GoTo Error_Trap
    import
    Exit Sub
Error_Trap:
    showError Err.number, "btnImport_Click | " & Err.source, Err.description
End Sub

'Close all open files
Private Sub Worksheet_Deactivate()
    On Error GoTo Error_Trap
    reset
    Exit Sub
Error_Trap:
    showError Err.number, "Worksheet_Deactivate | " & Err.source, Err.description
End Sub

'Show ontology lookup form if we're in the feature type or method column
Private Sub Worksheet_BeforeDoubleClick(ByVal target As Range, Cancel As Boolean)
    On Error GoTo Error_Trap
    'Ontology names
    Const ONT_ECO_NAME As String = "Evidence Codes"
    Const ONT_GO_NAME As String = "Gene Ontology"
    Dim ontologies As Dictionary
    Set ontologies = New Dictionary
    If target.Column = COL_METHOD Or target.Column = COL_TYPE Then
        Set ontologies = New Dictionary
        ontologies.Add "ECO", ONT_ECO_NAME
        ontologies.Add "EV", "eVOC"
        ontologies.Add "GO", ONT_GO_NAME
        ontologies.Add "MI", "Molecular Interaction"
        ontologies.Add "PSI", "Mass Spectroscopy"
        With frmOntologyLookup
            Set .ontologies = ontologies
            If target.Column = COL_METHOD Then
                .SelectedOntology = ONT_ECO_NAME
            Else
                .SelectedOntology = ONT_GO_NAME
            End If
            .SelectedTerm = target.value
            .Show
            'If get errors now, probably because use clicked the 'x' at the
            'top-left of the form, so can safely ignore (equivalent to clicking Cancel)
            On Error Resume Next
            If Not .Cancelled Then
                target.value = .SelectedTerm
            End If
        End With
    End If
    Exit Sub
Error_Trap:
    showError Err.number, "Worksheet_BeforeDoubleClick | " & Err.source, Err.description
End Sub

'Import GFF file from file system
Public Sub import()
    On Error GoTo Error_Trap
    Dim name As String, path As String, fileNumber As Integer
    'If first row contains data ...
    If Len(GffSheet.rows(ROW_START).Columns(COL_ID).value) > 0 Then
        ' ... check that we want to continue
        If MsgBox("The data in your spreadsheet will be overwritten. Are you sure you want to continue?", vbYesNo + vbQuestion) <> vbYes Then
            Exit Sub
        End If
    End If
    path = getFilePath(False)
    If Len(path) > 0 Then
        GffSheet.Range(CELL_INFO).value = ""
        GffSheet.Range(CELL_ERROR).value = ""
        'Clear
        Dim row As Range, i As Long
        For i = ROW_START To GffSheet.rows.Count
            Set row = GffSheet.rows(i).Columns
            If row(COL_ID).value = "" Then
                Exit For
            End If
            row.ClearContents
        Next i
        'path = GffSheet.Range(CELL_PATH).value
        fileNumber = FreeFile
        Open path For Input As #fileNumber
        deserialise fileNumber
        'Tidy up
        Close #fileNumber
        GffSheet.Range(CELL_INFO).value = "Last imported " & Now & " from: "
        GffSheet.Range(CELL_PATH).value = path
        GoTo Finally
    End If
    Exit Sub
Error_Trap:
    showError Err.number, "import | " & Err.source, Err.description
Finally:
    Close #fileNumber
End Sub

'Export to file system
Public Sub export()
    On Error GoTo Error_Trap
    Dim name As String, path As String, fileNumber As Integer
    path = getFilePath(True)
    If Len(path) > 0 Then
        GffSheet.Range(CELL_INFO).value = ""
        GffSheet.Range(CELL_PATH).value = ""
        GffSheet.Range(CELL_ERROR).value = ""
        fileNumber = FreeFile
        Open path For Output As #fileNumber
        serialise fileNumber
        'Tidy up
        Close #fileNumber
        GffSheet.Range(CELL_INFO).value = "Last exported " & Now & " to: "
        GffSheet.Range(CELL_PATH).value = path
        GoTo Finally
    End If
    Exit Sub
Error_Trap:
    showError Err.number, "export | " & Err.source, Err.description
Finally:
    Close #fileNumber
End Sub

'Allow user to choose file location for import/export
Private Function getFilePath(ByVal isExport As Boolean) As String
    On Error GoTo Error_Trap
    Const EXTENSION As String = "gff"
    Const FILTER As String = "GFF Files (*." & EXTENSION & "), *." & EXTENSION
    Dim path As String
    If isExport Then
        'Default: create GFF in same location as Excel file, using .gff in place of .xls as extension
        name = ThisWorkbook.name
        name = Left(name, InStr(name, ".")) & EXTENSION
        'path = ThisWorkbook.path & Application.PathSeparator & name
        path = Application.GetSaveAsFilename(InitialFileName:=name, FileFilter:=FILTER)
    Else
        path = Application.GetOpenFilename(FileFilter:=FILTER)
    End If
    If path = "False" Then
        'User pressed Cancel button
        path = ""
    End If
    getFilePath = path
    Exit Function
Error_Trap:
    Err.Raise Err.number, "getFilePath | " & Err.source, Err.description
End Function


' Deserialise spreadsheet from GFF
' TODO: Add comments and use array when serialise/deserialise so can use constants to get positions right
Private Sub deserialise(ByVal fileNumber As Integer)
    On Error GoTo Error_Trap
    Dim row As Range, rows As Long, i As Long, id As String, line As String, lineArray As Variant, s As String
    Dim symbol As String, method As String, feature As String, rowNumber As Long
    Dim start As Long, endX As Long, score As Double, strand As String, frame As String, attributes As String
    Dim attributesLineArray As Variant
    Dim featureId As String, featureLabel As String, name As String, note As String, target As String, l As Integer
    Dim link As String, symbolPos As Long, methodPos As Long, featurePos As Long, slen As Long
    rowNumber = ROW_START
    While Not EOF(fileNumber)
        Line Input #fileNumber, line
        'Ignore top-level comments
        If Left(line, Len(GFF_GLOBAL_COMMENT)) <> GFF_GLOBAL_COMMENT Then
            'Line comment
            If Left(line, Len(GFF_LINE_COMMENT)) = GFF_LINE_COMMENT Then
                'Reset
                id = ""
                symbol = ""
                method = ""
                feature = ""
                'Get values from comments lines, for example:
                '# symbol=FOXO4   method=inferred from biochemical trait (ECO:0000172)   feature=inhibition of neurotrophin
                symbolPos = InStr(line, GFF_LINE_COMMENT_SYMBOL)
                methodPos = InStr(line, GFF_LINE_COMMENT_METHOD)
                featurePos = InStr(line, GFF_LINE_COMMENT_FEATURE)
                If symbolPos > -1 Then
                    slen = symbolPos + Len(GFF_LINE_COMMENT_SYMBOL)
                    If methodPos > -1 Then
                        symbol = Mid(line, slen, methodPos - slen)
                    Else
                        If featurePos > -1 Then
                            symbol = Mid(line, slen, featurePos - slen)
                        Else
                            symbol = Mid(line, slen)
                        End If
                    End If
                End If
                If methodPos > -1 Then
                    slen = methodPos + Len(GFF_LINE_COMMENT_METHOD)
                    If featurePos > -1 Then
                        method = Mid(line, slen, featurePos - slen)
                    Else
                        method = Mid(line, slen)
                    End If
                End If
                If featurePos > -1 Then
                    slen = featurePos + Len(GFF_LINE_COMMENT_FEATURE)
                    feature = Mid(line, slen)
                End If
            Else
                'Data line
                lineArray = Split(line, vbTab)
                '-1 because is zero-based array
                If UBound(lineArray) > GFF_COL_MAX_REQUIRED - 1 Then
                    'We have data
                    id = lineArray(GFF_COL_ID)
                    If Len(method) = 0 Then
                        method = lineArray(GFF_COL_METHOD)
                    End If
                    If Len(feature) = 0 Then
                        feature = lineArray(GFF_COL_FEATURE)
                    End If
                    start = lineArray(GFF_COL_START)
                    endX = lineArray(GFF_COL_END)
                    score = lineArray(GFF_COL_SCORE)
                    strand = lineArray(GFF_COL_STRAND)
                    frame = lineArray(GFF_COL_FRAME)
                    '-1 because is zero-based array
                    If UBound(lineArray) > GFF_COL_ATTRIBUTES - 1 Then
                        'Get attributes, for example:
                        'ID "Q93009" ; Name "Q93009" ; Note "blah blah" ; Target "sample" "target"
                        attributes = lineArray(GFF_COL_ATTRIBUTES)
                        'Split string into array based on ";" eg. a[0]=[ID "Q93009"]
                        attributesLineArray = Split(attributes, GFF_ATTRIBUTE_SEP)
                        For i = 0 To UBound(attributesLineArray)
                            s = Trim(attributesLineArray(i))    'Remove leading and trailing spaces
                            s = Replace(s, """", "")            'Remove quotes
                            'TODO: Figure out why I used the magic number "+ 2" here...
                            If Left(s, Len(GFF_ATTR_ID)) = GFF_ATTR_ID Then
                                featureId = Mid(s, Len(GFF_ATTR_ID) + 2)
                            ElseIf Left(s, Len(GFF_ATTR_NAME)) = GFF_ATTR_NAME Then
                                featureLabel = Mid(s, Len(GFF_ATTR_NAME) + 2)
                            ElseIf Left(s, Len(GFF_ATTR_NOTE)) = GFF_ATTR_NOTE Then
                                note = Mid(s, Len(GFF_ATTR_NOTE) + 2)
                            ElseIf Left(s, Len(GFF_ATTR_TARGET)) = GFF_ATTR_TARGET Then
                                target = Mid(s, Len(GFF_ATTR_TARGET) + 2)
                            ElseIf Left(s, Len(GFF_ATTR_LINK)) = GFF_ATTR_LINK Then
                                link = Mid(s, Len(GFF_ATTR_LINK) + 2)
                            Else
                                Debug.Print "Unrecognised attribute: " + s
                            End If
                        Next i
                    End If
                    'Display in spreadsheet
                    Set row = GffSheet.rows(rowNumber)
                    row.Columns(COL_SYMBOL).value = symbol
                    row.Columns(COL_ID).value = id
                    row.Columns(COL_METHOD).value = method
                    row.Columns(COL_TYPE).value = feature
                    row.Columns(COL_SCORE).value = score
                    row.Columns(COL_START).value = start
                    row.Columns(COL_END).value = endX
                    row.Columns(COL_STRAND).value = strand
                    row.Columns(COL_FRAME).value = frame
                    If Len(featureLabel) = 0 Or featureLabel = featureId Then
                        row.Columns(COL_FEATURE).value = featureId
                    Else
                        row.Columns(COL_FEATURE).value = featureLabel & " " & ID_OPEN & featureId & ID_CLOSE
                    End If
                    row.Columns(COL_NOTE).value = note
                    row.Columns(COL_TARGET).value = target
                    row.Columns(COL_URL).value = link
                    rowNumber = rowNumber + 1
                    'Reset
                    symbol = ""
                    id = ""
                    method = ""
                    feature = ""
                    score = DEFAULT_SCORE
                    start = DEFAULT_START
                    endX = DEFAULT_END
                    strand = DEFAULT_STRAND
                    frame = DEFAULT_FRAME
                    featureId = ""
                    featureLabel = ""
                    note = ""
                    target = ""
                    link = ""
                End If
            End If
        End If
    Wend
    Exit Sub
Error_Trap:
    Err.Raise Err.number, "deserialise | " & Err.source, Err.description
End Sub

'Serialise spreadsheet to GFF
Private Sub serialise(ByVal fileNumber As Integer)
    On Error GoTo Error_Trap
    Dim row As Range, rows As Long, i As Long, id As String
    'Write each row until we find a row without an ID
    rows = GffSheet.rows.Count
    Print #fileNumber, GFF_GLOBAL_COMMENT & "gff-version 2"
    Print #fileNumber, GFF_GLOBAL_COMMENT & "date " & Year(Date) & "-" & Month(Date) & "-" & Day(Date)
    For i = ROW_START To rows
        Set row = GffSheet.rows(i).Columns
        id = row(COL_ID).value
        If id = "" Then
            Exit For
        End If
        writeRow fileNumber, id, row
    Next i
    Exit Sub
Error_Trap:
    Err.Raise Err.number, "serialise | " & Err.source, Err.description
End Sub

Private Sub ValidateColumn(ByVal value As String, ByVal columnName As String, ByVal rowName As String)
    Dim msg As String
    If Len(value) = 0 Then
        msg = "Please enter a " & columnName & " for row " & rowName & "."
        MsgBox msg
        Err.Raise 19710, "ValidateColumn | " & Err.source, msg
    End If
End Sub

'Write row to file
Private Sub writeRow(ByVal fileNumber As Integer, ByVal id As String, ByRef row As Range)
    On Error GoTo Error_Trap
    Dim line As String, attributes As String
    Dim typ As String, feature As String, method As String, target As String
    Dim typeLabel As String, methodLabel As String
    Dim typeId As String, methodId As String
    'Type
    typ = row(COL_TYPE).value
    ValidateColumn typ, "feature", row.row
    typeId = parseId(typ)
    typeLabel = parseLabel(typ)
    'Method
    method = row(COL_METHOD).value
    ValidateColumn method, "method", row.row
    methodId = parseId(method)
    methodLabel = parseLabel(method)
    'Comments
    line = line & GFF_LINE_COMMENT & " " & GFF_LINE_COMMENT_SYMBOL & row(COL_SYMBOL).value
    line = line & " " & GFF_LINE_COMMENT_METHOD & method
    line = line & " " & GFF_LINE_COMMENT_FEATURE & typ
    line = line & vbCrLf
    'Required columns
    line = line & id & vbTab
    line = line & methodId & vbTab
    line = line & typeId & vbTab
    'Optional columns
    line = line & doDefault(row(COL_START).value, DEFAULT_START) & vbTab
    line = line & doDefault(row(COL_END).value, DEFAULT_END) & vbTab
    line = line & doDefault(row(COL_SCORE).value, DEFAULT_SCORE) & vbTab
    line = line & doDefault(row(COL_STRAND).value, DEFAULT_STRAND) & vbTab
    line = line & doDefault(row(COL_FRAME).value, DEFAULT_FRAME) & vbTab
    'Attributes (all optional)
    target = Replace(row(COL_TARGET), " ", """ """)
    feature = Trim(row(COL_FEATURE).value)
    attributes = attributes & getOptionalAttribute(attributes, GFF_ATTR_ID, parseId(feature))
    attributes = attributes & getOptionalAttribute(attributes, GFF_ATTR_NAME, parseLabel(feature))
    attributes = attributes & getOptionalAttribute(attributes, GFF_ATTR_NOTE, row(COL_NOTE))
    attributes = attributes & getOptionalAttribute(attributes, GFF_ATTR_TARGET, target)
    attributes = attributes & getOptionalAttribute(attributes, GFF_ATTR_LINK, row(COL_URL))
    line = line & attributes
    Print #fileNumber, line
    Exit Sub
Error_Trap:
    Err.Raise Err.number, "writeRow | " & Err.source, Err.description
End Sub

Private Function getOptionalAttribute(ByVal attributes As String, ByVal name As String, ByVal value As String)
    On Error GoTo Error_Trap
    Dim attr As String, prefix As String
    attr = ""
    If Len(attributes) > 0 Then
        prefix = " " & GFF_ATTRIBUTE_SEP & " "
    End If
    If Len(value) > 0 Then
        attr = prefix & name & " """ & value & """"
    End If
    getOptionalAttribute = attr
    Exit Function
Error_Trap:
    Err.Raise Err.number, "getOptionalAttribute | " & Err.source, Err.description
End Function

Private Function doDefault(ByVal value As String, ByVal default As String) As String
    On Error GoTo Error_Trap
    If Len(value) = 0 Then
        value = default
    End If
    doDefault = value
    Exit Function
Error_Trap:
    Err.Raise Err.number, "doDefault | " & Err.source, Err.description
End Function

Private Function parseLabel(ByVal label As String) As String
    On Error GoTo Error_Trap
    Dim bracket As Integer
    bracket = InStr(label, ID_OPEN)
    If bracket > 0 Then
        label = Trim(Left(label, bracket - 1))
    End If
    parseLabel = label
    Exit Function
Error_Trap:
    Err.Raise Err.number, "parseLabel | " & Err.source, Err.description
End Function

Private Function parseId(ByVal label As String) As String
    On Error GoTo Error_Trap
    Dim id As String, bracket As Integer, bracket2 As Integer
    id = label
    bracket = InStr(id, ID_OPEN)
    If bracket > 0 Then
        id = Trim(Mid(id, bracket + 1))
        bracket2 = InStr(id, ID_CLOSE)
        If bracket2 > 0 Then
            id = Trim(Left(id, bracket2 - 1))
        End If
    End If
    parseId = id
    Exit Function
Error_Trap:
    Err.Raise Err.number, "parseId | " & Err.source, Err.description
End Function

Private Sub showError(ByVal number As Long, ByVal source As String, ByVal description As String)
    Dim s As String
    s = description & " (" & number & ") in " & source
    GffSheet.Range(CELL_ERROR).value = s
    MsgBox s
End Sub

'For testing
Public Sub main()
    'export
    import
End Sub
