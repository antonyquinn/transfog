VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "GffSheet"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
'/*
' * Copyright 2005 European Bioinformatics Institute.
' *
' * Licensed under the Apache License, Version 2.0 (the "License");
' * you may not use this file except in compliance with the License.
' * You may obtain a copy of the License at
' *
' *   http://www.apache.org/licenses/LICENSE-2.0
' *
' * Unless required by applicable law or agreed to in writing, software
' * distributed under the License is distributed on an "AS IS" BASIS,
' * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
' * See the License for the specific language governing permissions and
' * limitations under the License.
' *
'*/

Option Explicit
Option Compare Text

'/**
' * GFF template.
' *
' * @author  Antony Quinn <aquinn@ebi.ac.uk>
' * @version $Id: GffSheet.cls,v 1.1 2006/05/16 17:02:39 aquinn Exp $
' */

Private Const COL_SYMBOL As String = "A"
Private Const COL_ID As String = "B"
Private Const COL_METHOD As String = "C"
Private Const COL_TYPE As String = "D"
Private Const COL_SCORE As String = "E"
Private Const COL_NOTE As String = "F"
Private Const COL_TARGET As String = "G"
Private Const COL_FEATURE As String = "H"
Private Const COL_URL As String = "I"
Private Const COL_START As String = "J"
Private Const COL_END As String = "K"
Private Const COL_STRAND As String = "L"
Private Const COL_FRAME As String = "M"

Private Const ROW_START As Integer = 5

Private Const ID_OPEN As String = "("
Private Const ID_CLOSE As String = ")"

Private Const CELL_INFO As String = "C1"
Private Const CELL_PATH As String = "C2"
Private Const CELL_ERROR As String = "C3"

'Defaults
Private Const DEFAULT_SCORE  As Integer = 0
Private Const DEFAULT_START  As Integer = 0
Private Const DEFAULT_END  As Integer = 0
Private Const DEFAULT_STRAND  As String = "."
Private Const DEFAULT_FRAME  As String = "."

'For testing
Public Sub main()
    export
End Sub

'Button click
Public Sub export_onclick()
    On Error GoTo Error_Trap
    export
    Exit Sub
Error_Trap:
    GffSheet.Range(CELL_ERROR).value = Err.Description & " (" & Err.Number & ") in " & Err.Source
End Sub

'Export to file system
Public Sub export()
    On Error GoTo Error_Trap
    Dim name As String, path As String
    Dim fso As New FileSystemObject, textStream As textStream
    GffSheet.Range(CELL_INFO).value = ""
    GffSheet.Range(CELL_PATH).value = ""
    GffSheet.Range(CELL_ERROR).value = ""
    'Create GFF in same location as Excel file, using .gff in place of .xls as extension
    name = ThisWorkbook.name
    name = Left(name, InStr(name, ".")) & "gff"
    path = ThisWorkbook.path & "\" & name
    Set textStream = fso.CreateTextFile(path)
    serialise textStream
    'Tidy up
    textStream.Close
    GffSheet.Range(CELL_INFO).value = "Last exported " & Now & " to: "
    GffSheet.Range(CELL_PATH).value = path
    Exit Sub
Error_Trap:
    GffSheet.Range(CELL_ERROR).value = Err.Description & " (" & Err.Number & ") in " & Err.Source
    On Error Resume Next
    textStream.Close
End Sub

'Serialise spreadsheet to GFF
Private Sub serialise(textStream As textStream)
    On Error GoTo Error_Trap
    Dim row As Range, rows As Long, i As Long, id As String
    'Write each row until we find a row without an ID
    rows = GffSheet.rows.Count
    textStream.writeLine "##gff-version 2"
    textStream.writeLine "##date " & Year(Date) & "-" & Month(Date) & "-" & Day(Date)
    For i = ROW_START To rows
        Set row = GffSheet.rows(i).Columns
        id = row(COL_ID).value
        If id = "" Then
            Exit For
        End If
        writeRow textStream, id, row
    Next i
    Exit Sub
Error_Trap:
    Err.Raise Err.Number, "serialise | " & Err.Source, Err.Description
End Sub

Private Sub ValidateColumn(ByVal value As String, ByVal columnName As String, ByVal rowName As String)
    Dim msg As String
    If Len(value) = 0 Then
        msg = "Please enter a " & columnName & " for row " & rowName & "."
        MsgBox msg
        Err.Raise 19710, "ValidateColumn | " & Err.Source, msg
    End If
End Sub

Private Sub writeRow(textStream As textStream, ByVal id As String, ByRef row As Range)
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
    line = line & "# symbol=" & row(COL_SYMBOL).value
    line = line & " method=" & method
    line = line & " feature=" & typ
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
    attributes = attributes & getOptionalAttribute(attributes, "ID", parseId(feature))
    attributes = attributes & getOptionalAttribute(attributes, "Name", parseLabel(feature))
    attributes = attributes & getOptionalAttribute(attributes, "Note", row(COL_NOTE))
    attributes = attributes & getOptionalAttribute(attributes, "Target", target)
    attributes = attributes & getOptionalAttribute(attributes, "Link", row(COL_URL))
    line = line & attributes
    textStream.writeLine line
    Exit Sub
Error_Trap:
    Err.Raise Err.Number, "writeRow | " & Err.Source, Err.Description
End Sub

Private Function getOptionalAttribute(ByVal attributes As String, ByVal name As String, ByVal value As String)
    Dim attr As String, prefix As String
    attr = ""
    If Len(attributes) > 0 Then
        prefix = " ; "
    End If
    If Len(value) > 0 Then
        attr = prefix & name & " """ & value & """"
    End If
    getOptionalAttribute = attr
End Function

Private Function doDefault(ByVal value As String, ByVal default As String) As String
    On Error GoTo Error_Trap
    If Len(value) = 0 Then
        value = default
    End If
    doDefault = value
    Exit Function
Error_Trap:
    Err.Raise Err.Number, "doDefault | " & Err.Source, Err.Description
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
    Err.Raise Err.Number, "parseLabel | " & Err.Source, Err.Description
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
    Err.Raise Err.Number, "parseId | " & Err.Source, Err.Description
End Function
