VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmOntologyLookup 
   Caption         =   "Ontology Lookup"
   ClientHeight    =   9435
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   10260
   OleObjectBlob   =   "frmOntologyLookup.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "frmOntologyLookup"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
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


' Ontology lookup form.
'
' @author  Antony Quinn <aquinn@ebi.ac.uk>
' @version $Id: frmOntologyLookup.frm,v 1.1 2007/06/27 15:47:30 aquinn Exp $

Option Explicit
Option Compare Text

' Optional item to show in drop-down list of ontologies
Private Const SEARCH_ALL As String = "All ontologies"
' Brackets to use around short label of ontology, eg. "Gene Ontology [GO]"
Private Const ONT_KEY_BRACKET_OPEN As String = "["
Private Const ONT_KEY_BRACKET_CLOSE As String = "]"
' Brackets to use around ontology term ID, eg. "lung development (GO:0030324)"
Private Const TERM_KEY_BRACKET_OPEN As String = "("
Private Const TERM_KEY_BRACKET_CLOSE As String = ")"

Private m_query       As OntologyQuery  'OLS interface
Private m_ontologies  As Dictionary     'List of m_ontologies to show in drop-down
Private m_selectedOntology As String
Private m_isCancelled As Boolean        'True if user clicked Cancel button

' Constructor
Private Sub UserForm_Initialize()
    On Error GoTo Error_Trap
    Set m_query = New OntologyQuery
    ' Default is to show all ontologies from OLS in combo box
    Set m_ontologies = m_query.getOntologyNames()
    Exit Sub
Error_Trap:
    showError Err.number, "UserForm_Initialize | " & Err.source, Err.description
End Sub

'Destructor
Private Sub UserForm_Terminate()
    On Error GoTo Error_Trap
    Set m_query = Nothing
    Set m_ontologies = Nothing
    Exit Sub
Error_Trap:
    showError Err.number, "UserForm_Terminate | " & Err.source, Err.description
End Sub

'Initialisation
Private Sub UserForm_Activate()
    On Error GoTo Error_Trap
    Dim key As Variant, item As Variant, i As Integer
    m_isCancelled = True
    txtTerm.text = ""
    lstTerms.Clear
    cboOntologies.Clear
    'cboOntologies.AddItem SEARCH_ALL
    ' Show ontologies in drop-down list
    For Each key In m_ontologies.Keys
        cboOntologies.AddItem m_ontologies.item(key) & " " & ONT_KEY_BRACKET_OPEN & key & ONT_KEY_BRACKET_CLOSE
    Next
    If Len(m_selectedOntology) = 0 Then
        cboOntologies.ListIndex = 0
    Else
        ' Show selected ontology
        For i = 0 To cboOntologies.ListCount - 1
            If InStr(cboOntologies.List(i), m_selectedOntology) > 0 Then
                cboOntologies.ListIndex = i
                Exit For
            End If
        Next i
    End If
    txtTerm.SetFocus
    Exit Sub
Error_Trap:
    showError Err.number, "UserForm_Activate | " & Err.source, Err.description
End Sub

'Selected ontology name, eg. "Gene Ontology"
Public Property Get SelectedOntology() As String
    SelectedOntology = cboOntologies.text
End Property
Public Property Let SelectedOntology(ByVal o As String)
    m_selectedOntology = o
End Property

'List of ontologies to show
Public Property Get ontologies() As Dictionary
    Set ontologies = m_ontologies
End Property
Public Property Set ontologies(ByRef o As Dictionary)
    Set m_ontologies = o
End Property

'Term as entered by user
Public Property Get SelectedTerm() As String
    SelectedTerm = txtSelectedTerm.text
End Property
Public Property Let SelectedTerm(ByVal t As String)
    txtSelectedTerm.text = t
    txtTermMetaData.text = ""
End Property

'Returns true if Cancel button was pressed
Public Property Get Cancelled() As Boolean
    Cancelled = m_isCancelled
End Property

' Returns the short label of the ontology, eg. "GO" from "Gene Ontology [GO]"
Public Property Get Ontology() As String
    Ontology = parseText(cboOntologies.text, ONT_KEY_BRACKET_OPEN, ONT_KEY_BRACKET_CLOSE)
End Property

' Returns the ontology term ID, eg. "GO:0006966" from "Apoptosis (GO:0006966)"
Public Property Get SelectedTermId() As String
    SelectedTermId = parseTermId(SelectedTerm)
End Property

Private Sub btnCancel_Click()
    m_isCancelled = True
    Me.Hide
End Sub

Private Sub btnOK_Click()
    m_isCancelled = False
    Me.Hide
End Sub

' Show definition for selected ontology term
Private Sub btnGetDefintion_Click()
    On Error GoTo Error_Trap
    showTermDescription parseTermId(txtSelectedTerm.text)
    Exit Sub
Error_Trap:
    showError Err.number, "btnGetDefintion_Click | " & Err.source, Err.description
End Sub

' Search for ontology term
Private Sub btnSearch_Click()
    On Error GoTo Error_Trap
    showTerms
    Exit Sub
Error_Trap:
    showError Err.number, "btnSearch_Click | " & Err.source, Err.description
End Sub

' Search for ontology term when leave text box (eg. tab or press enter)
Private Sub txtTerm_Exit(ByVal Cancel As MSForms.ReturnBoolean)
    On Error GoTo Error_Trap
    showTerms
    Exit Sub
Error_Trap:
    showError Err.number, "txtTerm_Exit | " & Err.source, Err.description
End Sub

'Show selected term
Private Sub lstTerms_Click()
    On Error GoTo Error_Trap
    SelectedTerm = lstTerms.text
    Exit Sub
Error_Trap:
    showError Err.number, "lstTerms_Click | " & Err.source, Err.description
End Sub

'Show description for term
Private Sub showTermDescription(ByVal term As String)
    On Error GoTo Error_Trap
    Dim metaData As Dictionary, key As Variant, value As Variant, definition As String, synonyms As String
    Dim ontName As String
    ontName = parseTermOntology(term)
    If Len(ontName) > 0 Then
        showStatus "Getting definition..."
        txtTermMetaData.text = ""
        Set metaData = m_query.getTermMetadata(term, ontName)
        For Each key In metaData.Keys
            value = metaData.item(key)
            If key = "definition" Then
                definition = value
            Else
                If InStr(key, "synonym") Then
                    synonyms = synonyms & "- " & value & vbCrLf
                End If
            End If
        Next
        If Len(definition) = 0 Then
            definition = "No definition available"
        End If
        txtTermMetaData.text = definition & vbCrLf & vbCrLf
        If Len(synonyms) > 0 Then
            txtTermMetaData.text = txtTermMetaData.text & "Synonyms:" & vbCrLf & synonyms
        End If
        showStatus ""
    End If
    Exit Sub
Error_Trap:
    showError Err.number, "showTermDescription | " & Err.source, Err.description
End Sub

' Show error message as pop-up and in status bar
Private Sub showError(ByVal number As Long, ByVal source As String, ByVal description As String)
On Error Resume Next
    Dim msg As String
    msg = description & " [" & source & " exception (" & number & ")]"
    showStatus msg
    MsgBox msg
End Sub

' Show message in status bar
Private Sub showStatus(ByVal message As String, Optional ByVal mousePointer As fmMousePointer = fmMousePointerDefault)
    Me.mousePointer = mousePointer
    txtStatus.text = message
    Me.Repaint
End Sub

' Returns the ontology term ID, eg. "GO:0006966" from "Apoptosis (GO:0006966)"
Private Function parseTermId(ByVal term As String) As String
    parseTermId = parseText(term, TERM_KEY_BRACKET_OPEN, TERM_KEY_BRACKET_CLOSE)
End Function

' Returns the ontology name from the term ID, eg. "GO" from "GO:0006966"
Private Function parseTermOntology(ByVal term As String) As String
    Dim colon As Integer
    colon = InStr(term, ":")
    If colon > 0 Then
        parseTermOntology = Left(term, colon - 1)
    Else
        parseTermOntology = ""
    End If
End Function

' Extract text, eg. "GO" from "Gene Ontology [GO]"
Private Function parseText(ByVal text As String, ByVal startStr As String, ByVal endStr As String) As String
    Dim start As Integer, t As String
    start = InStr(1, text, startStr)
    If start > 0 Then
        ' Get the part up to startStr
        t = Right(text, Len(text) - start)
        ' Chop off endStr
        t = Left(t, Len(t) - 1)
    End If
    parseText = t
End Function

' Show ontology terms matching the query entered by the user
Private Sub showTerms()
    On Error GoTo Error_Trap
    Dim key As Variant, item As Variant, terms As Dictionary, id As Variant, term As String, ont As String
    term = txtTerm.text
    lstTerms.Clear
    If Len(term) > 0 Then
        showStatus "Searching " & cboOntologies.text & " for '" & term & "'"
        If cboOntologies.text = SEARCH_ALL Then
            Set terms = m_query.getPrefixedTermsByName(term)
        Else
            Set terms = m_query.getTermsByName(term, Ontology)
        End If
        showStatus ""
        If Not terms Is Nothing Then
            If terms.Count = 0 Then
                MsgBox "Sorry, no terms found for '" & term & "'"
            Else
                For Each key In terms.Keys
                    lstTerms.AddItem terms.item(key) & " " & TERM_KEY_BRACKET_OPEN & key & TERM_KEY_BRACKET_CLOSE
                Next
            End If
            'To use columns:
            'With lstTerms
            '    .ColumnCount = 2
            '    .BoundColumn = 2
            '    .ColumnWidths = ".5 in; 2 in"
            '    For Each item In terms.Items
            '        .AddItem getKeyFromItem(item, terms)
            '        .List(.ListCount - 1, 1) = item
            '    Next
            'End With
        End If
    End If
    Exit Sub
Error_Trap:
    showStatus ""
    Err.Raise Err.number, Err.source & " | showTerms", Err.description
End Sub

