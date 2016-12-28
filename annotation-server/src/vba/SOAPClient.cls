VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SOAPClient"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' ------------------------------------------------------------------
' PRIDE XML Generation Spreadsheet
' By Phil Jones, EMBL-EBI (www.ebi.ac.uk)
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
'Option Explicit

 ' Variables that may help to identify the end-user
 
 Private WebClient As Object
 'Private WebClient As Microsoft.XmlHttp
 Private m_ActiveXPrefix As String
 Private m_ParameterNames() As String
 Private m_ParameterValues() As String
 Private m_MethodName As String
 Private m_XmlNamespace As String
 Private m_OnReadystateChange As String
 Private m_ParameterCount As Integer
 Private m_EndPoint As String
 
 Private Property Get ActiveXPrefix() As String
    If Len(m_ActiveXPrefix) > 0 Then
       ActiveXPrefix = m_ActiveXPrefix
       Exit Property
    End If
    
    Dim Prefixes(4) As String
    Prefixes(0) = "Microsoft"
    Prefixes(1) = "MSXML"
    Prefixes(2) = "MSXML2"
    Prefixes(3) = "MSXML3"
    
    Dim test As Object
    On Error Resume Next
    
    For Each prefix In Prefixes
        Set test = CreateObject(prefix & ".XmlHttp")
        If Not Err Then
            Set test = CreateObject(prefix & ".XmlDom")
            If Not Err Then
                m_ActiveXPrefix = prefix
                ActiveXPrefix = prefix
                Exit Property
            End If
        End If
        Err.Clear
    Next
    
 End Property
 
 Private Property Get ParameterIndex(name As String) As Integer
    For i = 0 To m_ParameterCount
        If m_ParameterNames(i) = name Then
            ParameterIndex = i
            Exit Property
        End If
    Next i
    ParameterIndex = -1
 End Property
 
 Public Property Let parameter(name As String, value As String)
    Dim i As Integer
    i = ParameterIndex(name)
    If i = -1 Then
        addParameter name, value
    Else
        m_ParameterValues(i) = value
    End If
 End Property
 
 Public Property Get parameter(name As String) As String
    Dim i As Integer
    i = ParameterIndex(name)
    If i = -1 Then
        parameter = ""
    Else
        parameter = m_ParameterValues(i)
    End If
 End Property
 
 Public Sub addParameter(name As String, value As String)
    Dim i As Integer
    i = m_ParameterCount
    m_ParameterCount = m_ParameterCount + 1
    ReDim Preserve m_ParameterNames(m_ParameterCount)
    ReDim Preserve m_ParameterValues(m_ParameterCount)
    m_ParameterNames(i) = name
    m_ParameterValues(i) = value
 End Sub
 
 Public Sub ClearParameters()
    ReDim m_ParameterNames(0)
    ReDim m_ParameterValues(0)
    m_ParameterCount = 0
 End Sub
 
 Public Property Get MethodName() As String
    MethodName = m_MethodName
 End Property
 
 Public Property Let MethodName(name As String)
    m_MethodName = name
 End Property
 
 Public Property Let XmlNamespace(uri As String)
    m_XmlNamespace = uri
 End Property
 
 Public Property Get XmlNamespace() As String
    XmlNamespace = m_XmlNamespace
 End Property
 
 Public Property Let OnReadystateChange(method As String)
    m_OnReadystateChange = method
 End Property
 
 Public Property Get OnReadystateChange() As String
    OnReadystateChange = m_OnReadystateChange
 End Property
 
 Public Property Get EndPoint() As String
    EndPoint = m_EndPoint
 End Property
 
 Public Property Let EndPoint(uri As String)
    m_EndPoint = uri
 End Property
 
 Public Function query(Optional Asynch As Boolean = False) As Object
    'Debug.Print "Called Query Function"
    Dim Envelope As Object
    Set Envelope = CreateEnvelope()
    'Debug.Print "XML: " & Envelope.xml
    WebClient.Open "POST", Me.EndPoint, Asynch
    WebClient.setRequestHeader "SOAPAction", """" & Me.XmlNamespace & Me.MethodName & """"
    WebClient.setRequestHeader "Content-Type", "text/xml; charset=UTF-8"
    WebClient.setRequestHeader "Content-Length", CStr(Len(Envelope.xml))
    'Debug.Print Envelope.xml
    On Error GoTo ErrorTrap
    WebClient.send Envelope.xml
    On Error GoTo 0
    If Asynch Then
        While Not WebClient.readyState = 4
            'Debug.Print "Waiting..."
            DoEvents
        Wend
    End If
    'Debug.Print "Response Text: " & WebClient.ResponseText
    'Debug.Print "Response status: " & WebClient.status
    If Envelope.loadXML(WebClient.ResponseText) Then
        If Envelope.lastChild.firstChild.firstChild.nodeName = "soap:Fault" Then
            MsgBox "An error occured while communicating with the server."
            'Debug.Print Envelope.LastChild.FirstChild.FirstChild.FirstChild.nextSibling.text
            GoTo reset
        End If
        'Debug.Print "Actually got a response and setting the Envelope variable to reference it..."
        'Envelope.loadXML Envelope.LastChild.FirstChild.FirstChild.FirstChild.xml
        Envelope.loadXML Envelope.xml
        Set query = Envelope
    End If
    GoTo reset
ErrorTrap:
    MsgBox Err.description
reset:
    Me.ClearParameters
 End Function
 
 Private Function CreateEnvelope() As Object
    Dim soap As Object
    Dim Envelope As Object
    Dim Body As Object
    Dim method As Object
    Dim ParameterNode As Object
    Set soap = CreateObject(ActiveXPrefix & ".XmlDom")
    soap.async = False
    soap.appendChild (soap.createProcessingInstruction("xml", "version='1.0' encoding='UTF-8'"))
    Set Envelope = soap.createElement("soap:Envelope")
    Envelope.setAttribute "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance"
    Envelope.setAttribute "xmlns:xsd", "http://www.w3.org/2001/XMLSchema"
    Envelope.setAttribute "xmlns:soap", "http://schemas.xmlsoap.org/soap/envelope/"
    soap.appendChild Envelope
    Set Body = soap.createElement("soap:Body")
    Envelope.appendChild Body
    Set method = soap.createElement(Me.MethodName)
    Body.appendChild method
    method.setAttribute "xmlns", Me.XmlNamespace
    For i = 0 To m_ParameterCount - 1
        Set ParameterNode = soap.createElement(m_ParameterNames(i))
        ParameterNode.text = m_ParameterValues(i)
        method.appendChild ParameterNode
    Next i
    Set CreateEnvelope = soap
 End Function
 
 Private Sub Class_Initialize()
    Set WebClient = CreateObject(ActiveXPrefix & ".XmlHttp")
    Me.ClearParameters
 End Sub
 
 Private Sub Class_Terminate()
    Set WebClient = Nothing
 End Sub
