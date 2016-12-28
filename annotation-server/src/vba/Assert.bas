Attribute VB_Name = "Assert"
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


' Assertions for unit testing
'
' @author  Antony Quinn <aquinn@ebi.ac.uk>
' @version $Id: Assert.bas,v 1.1 2007/06/27 15:47:30 aquinn Exp $

Option Explicit
Option Compare Text

'Error codes
Private Const ERR_BASE As Long = 1971
Private Const ERR_EQUALS As Long = ERR_BASE + 1
Private Const ERR_TRUE As Long = ERR_BASE + 2

Public Sub assertEquals(ByVal expected As Variant, ByVal actual As Variant, Optional ByVal message As String = "")
    If Not expected = actual Then
        throwException ERR_EQUALS, "assertEquals", message & "Expected " & expected & ", found " & actual
    End If
End Sub

Public Sub assertTrue(ByVal condition As Boolean, Optional ByVal message As String = "")
    If condition = False Then
        throwException ERR_TRUE, "assertTrue", message
    End If
End Sub

Private Sub throwException(ByVal number As Long, ByVal source As String, ByVal message As String)
    Err.Raise number, source, message
End Sub
