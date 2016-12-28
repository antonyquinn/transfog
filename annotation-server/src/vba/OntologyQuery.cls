VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "OntologyQuery"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' ------------------------------------------------------------------
' PRIDE XML Generation Spreadsheet
' By Phil Jones and Antony Quinn, EMBL-EBI (www.ebi.ac.uk)
'
' A project in support of the PRIDE Proteomics Identifications
' Database (www.ebi.ac.uk/pride).
'
' Funded by the BBSRC 'Proteome Harvest' grant
'
' Available under the Apache License Version 2.0, January 2004
' (See http://www.apache.org/licenses/LICENSE-2.0.html)
'
' For support queries, please email pjones@ebi.ac.uk
' ------------------------------------------------------------------
Option Explicit

' Soap Client Implementation for OntologyQuery service
' Based upon WSDL: http://www.ebi.ac.uk/ontology-lookup/services/OntologyQuery?wsdl

Private Const SOAP_ADDRESS As String = "http://www.ebi.ac.uk/ontology-lookup/services/OntologyQuery"
Private Const NAMESPACE As String = "urn:OntologyQuery"

'AQ - made private
Private Const IS_A_RELATION_TYPE_ID As Integer = 1
Private Const PART_OF_RELATION_TYPE_ID As Integer = 2
Private Const DEVELOPS_FROM_RELATION_TYPE_ID As Integer = 3
Private Const NO_DISTANCE_CONSTRAINT As Integer = -1

Private iSoap As SOAPClient

Private Sub Class_Initialize()
    Set iSoap = New SOAPClient
    iSoap.XmlNamespace = NAMESPACE
    iSoap.EndPoint = SOAP_ADDRESS
End Sub

' AQ - added
Private Sub Class_Terminate()
    Set iSoap = Nothing
End Sub

' Tested with new WSDL - OK
Public Function getVersion() As String
    With iSoap
        .MethodName = "getVersion"
        getVersion = .query(False).lastChild.firstChild.firstChild.firstChild.text
    End With
End Function
    

' Note - In theory, Ontology Name is optional in this function
' but in practice it is required. (No error - just failure to return any value).
' AQ - added ByVal
Public Function getTermById(ByVal termId As String, ByVal ontologyName As String) As String
    With iSoap
        .MethodName = "getTermById"
        .addParameter "in0", termId
        .addParameter "in1", ontologyName
        getTermById = .query(False).lastChild.firstChild.firstChild.firstChild.text
    End With
End Function

Public Function getOntologyNames() As Dictionary
    Dim returnXML As Object
    With iSoap
        .MethodName = "getOntologyNames"
        Set getOntologyNames = parseMap(.query(False))
    End With
    'Debug.Print "Ontology Names XML: " & returnXML.xml
End Function

' AQ - added
Public Function getRootTerms(ByVal ontologyName As String) As Dictionary
    With iSoap
        .MethodName = "getRootTerms"
        .addParameter "in0", ontologyName
        Set getRootTerms = parseMap(.query(False))
    End With
End Function

' AQ - added
Public Function getTermMetadata(ByVal termId As String, ByVal ontologyName As String) As Dictionary
    With iSoap
        .MethodName = "getTermMetadata"
        .addParameter "in0", termId
        .addParameter "in1", ontologyName
        Set getTermMetadata = parseMap(.query(False))
    End With
End Function

' Note - includeSynonyms is optional in this method
' AQ - added ByVal
Public Function getTermsByName(ByVal partialName As String, ByVal shortOntologyName As String) As Dictionary
    With iSoap
        .MethodName = "getTermsByName"
        .addParameter "in0", partialName
        .addParameter "in1", shortOntologyName
        .addParameter "in2", "false"
        Set getTermsByName = parseMap(.query(False))
    End With
End Function

' AQ - added ByVal
Public Function getPrefixedTermsByName(ByVal partialName As String) As Dictionary
    With iSoap
        .MethodName = "getPrefixedTermsByName"
        .addParameter "in0", partialName
        .addParameter "in1", "false"
        Set getPrefixedTermsByName = parseMap(.query(False))
    End With
End Function

' AQ - added ByVal
Public Function getTermChildren(ByVal termId As String, Optional ByVal ontologyName As String = "", _
Optional ByVal distance As Integer = -1, Optional ByVal relationshipTypes As String = "") As Dictionary
    With iSoap
        .MethodName = "getTermChildren"
        .addParameter "termId", termId
        .addParameter "ontologyName", ontologyName
        .addParameter "distance", "" & distance
        .addParameter "relationTypes", relationshipTypes
        Set getTermChildren = parseMap(.query(False))
    End With
End Function

' AQ - added ByVal
Public Function getChildrenFromRoot(ByVal termId As String, ByVal ontologyName As String, _
childrenIds As Collection) As Dictionary

End Function

' AQ - added ByVal
Public Function isObsolete(ByVal termId As String, ByVal ontologyName As String) As Boolean

End Function

' AQ
Private Function parseMap(xml As Object) As Dictionary
    Dim returnMap As Dictionary
    Dim itemNodes As Object, currentNode As Object
    Dim indexer As Integer
    Set itemNodes = xml.lastChild.firstChild.lastChild.firstChild.childNodes
    Set returnMap = New Dictionary
    For Each currentNode In itemNodes
        returnMap.Add currentNode.firstChild.text, currentNode.lastChild.text
    Next currentNode
    Set parseMap = returnMap
End Function

Public Function clearCache()

End Function



