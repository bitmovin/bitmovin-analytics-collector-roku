'Plucks deeply nested values from assoc arrays (handles invalids)
function pluck(v, arr)
  if v = invalid
    return invalid
  else if not isArray(arr) or arr.count() = 0
    return v
  else if arr.count() = 1
    return v[arr[0]]
  else
    field = arr[0]
    arr.shift()
    return pluck(v[field], arr)
  end if
end function

function isInvalid(v)
  if v = invalid
    return true
  else
    return false
  end if
end function

function isArray(v)
  return getInterface(v, "ifArray") <> invalid
end function

function getAnalyticsRequestTypes()
  analyticsRequestTypes = {
    REGULAR: 0,
    AD_ENGAGEMENT: 1
  }

  return analyticsRequestTypes
end function
