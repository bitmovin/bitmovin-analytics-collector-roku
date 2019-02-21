Function GenerateGuid() As String
    ' Ex. {5EF8541E-C9F7-CFCD-4BD4-036AF6C145DA}
    Return "{" + GetRandomHexString(8) + "-" + GetRandomHexString(4) + "-" + "4" + GetRandomHexString(3) + "-" + GetRandomHexStringFourthByte(1) + GetRandomHexString(3) + "-" + GetRandomHexString(12) + "}"
End Function

Function GetRandomHexString(length As Integer) As String
    hexChars = "0123456789ABCDEF"
    hexString = ""
    For i = 1 to length
        hexString = hexString + hexChars.Mid(Rnd(16) - 1, 1)
    Next
    Return hexString
End Function

Function GetRandomHexStringFourthByte(length As Integer) As String
    hexChars = "89AB"
    hexString = ""
    For i = 1 to length
        hexString = hexString + hexChars.Mid(Rnd(4) - 1, 1)
    Next
    Return hexString
End Function
