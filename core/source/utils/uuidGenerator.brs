function generateGuid() as string
    ' Example {5EF8541E-C9F7-CFCD-4BD4-036AF6C145DA}
    return "{" + getRandomHexString(8) + "-" + getRandomHexString(4) + "-" + "4" + getRandomHexString(3) + "-" + getRandomHexStringFourthByte(1) + getRandomHexString(3) + "-" + getRandomHexString(12) + "}"
end function

function getRandomHexString(length as integer) as string
    hexChars = "0123456789ABCDEF"
    hexString = ""
    for i = 1 to length
        hexString = hexString + hexChars.mid(rnd(16) - 1, 1)
    next
    return hexString
end function

function getRandomHexStringFourthByte(length as integer) as string
    hexChars = "89AB"
    hexString = ""
    for i = 1 to length
        hexString = hexString + hexChars.mid(rnd(4) - 1, 1)
    next
    return hexString
end function
