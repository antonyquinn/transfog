VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "OntologyQueryTest"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
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


' Unit tests for OntologyQuery
'
' @author  Antony Quinn <aquinn@ebi.ac.uk>
' @version $Id: OntologyQueryTest.cls,v 1.1 2007/06/27 15:47:30 aquinn Exp $

Option Explicit
Option Compare Text

Private query As OntologyQuery
Private doDebugging As Boolean

'Set up
Private Sub Class_Initialize()
    doDebug = False
    Set query = New OntologyQuery
End Sub

'Tear down
Private Sub Class_Terminate()
    Set query = Nothing
End Sub

Private Sub log(ByVal message As String)
    If doDebug Then
        Debug.Print message
    End If
End Sub

Private Sub logDictionary(ByVal name As String, dict As Dictionary)
    Dim key As Variant
    For Each key In dict.Keys
        log name & "[" & key & "] = " & vbTab & dict.item(key) & " "
    Next
End Sub

Public Property Get doDebug() As Boolean
    doDebug = doDebugging
End Property

Public Property Let doDebug(ByVal value As Boolean)
    doDebugging = value
End Property

Public Sub testGetVersion()
    Dim version As String
    version = query.getVersion()
    log "getVersion = " & version
    assertTrue Len(version) > 0, "testGetVersion: version is empty"
End Sub
    
Public Sub testGetTermById()
    Const ONT_NAME As String = "GO"
    Const TERM_ID As String = "GO:0006915"
    Const expected As String = "apoptosis"
    Dim term As String
    term = query.getTermById(TERM_ID, ONT_NAME)
    log "getTermById('" & TERM_ID & "', '" & ONT_NAME & "') = " & term
    assertEquals expected, term, "testGetTermById: "
End Sub

Public Sub testGetOntologyNames()
    Dim dict As Dictionary
    Set dict = query.getOntologyNames()
    logDictionary "getOntologyNames", dict
    assertTrue dict.Count > 0, "testGetOntologyNames: no ontology names found"
End Sub

Public Sub testGetRootTerms()
    Dim dict As Dictionary
    Set dict = query.getRootTerms("GO")
    logDictionary "getRootTerms", dict
    assertTrue dict.Count > 0, "testGetRootTerms: no root terms found"
End Sub

Public Sub testGetTermMetadata()
    Const ONT_NAME As String = "GO"
    Const TERM_ID As String = "GO:0006915"
    Dim dict As Dictionary
    Set dict = query.getTermMetadata(TERM_ID, ONT_NAME)
    logDictionary "getTermMetadata", dict
    assertTrue dict.Count > 0, "testGetTermMetadata: no meta data found"
End Sub

Public Sub testGetTermsByName()
    Const PARTIAL_NAME As String = "copper"
    Const ONT_NAME As String = "CHEBI"
    Dim dict As Dictionary
    Set dict = query.getTermsByName(PARTIAL_NAME, ONT_NAME)
    logDictionary "getTermsByName('" & PARTIAL_NAME & "', '" & ONT_NAME & "')", dict
    assertTrue dict.Count > 0, "testGetTermsByName: no terms found"
End Sub

Public Sub testGetPrefixedTermsByName()
    Const PARTIAL_NAME As String = "microarray"
    Dim dict As Dictionary
    Set dict = query.getPrefixedTermsByName(PARTIAL_NAME)
    logDictionary "getPrefixedTermsByName('" & PARTIAL_NAME & "')", dict
    assertTrue dict.Count > 0, "testGetPrefixedTermsByName: no terms found"
End Sub

Public Sub testGetTermChildren()
    Const ONT_NAME As String = "GO"
    Const TERM_ID As String = "GO:0006915"
    Dim dict As Dictionary
    Set dict = query.getTermChildren(TERM_ID, ONT_NAME)
    logDictionary "getTermChildren('" & TERM_ID & "', '" & ONT_NAME & "')", dict
    assertTrue dict.Count > 0, "testGetTermChildren: no terms found"
End Sub

'TODO
Public Sub testGetChildrenFromRoot()

End Sub

'TODO
Public Sub isObsolete()

End Sub

'TODO
Public Sub clearCache()

End Sub

