Attribute VB_Name = "UnitTests"

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


' Unit tests (has to be in module so can call as macro).
'
' @author  Antony Quinn <aquinn@ebi.ac.uk>
' @version $Id: UnitTests.bas,v 1.1 2007/06/27 15:47:30 aquinn Exp $

Option Explicit
Option Compare Text

Public Sub ontologyQueryTests()
    On Error GoTo Error_Trap
    Dim test As OntologyQueryTest
    Debug.Print "--- ontologyQueryTests [start] ---"
    Set test = New OntologyQueryTest
    test.doDebug = True
    test.testGetVersion
    test.testGetTermById
    test.testGetOntologyNames
    test.testGetTermsByName
    test.testGetPrefixedTermsByName
    test.testGetTermChildren
    test.testGetRootTerms
    test.testGetTermMetadata
    GoTo Finally
    Exit Sub
Error_Trap:
    Debug.Print Err.description & " [" & Err.source & " exception (" & Err.number & ")]"
Finally:
    Set test = Nothing
    Debug.Print "--- ontologyQueryTests [end] ---"
    Debug.Print
End Sub
    
