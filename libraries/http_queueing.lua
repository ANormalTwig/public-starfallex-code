--[[
    Library to make all http.get and http.post requests work based off of a queue system.
    All http.get and http.post requests return a number which can be used to cancel a queued http request with http.cancel(index)
    
    -Twig
]]

local http_queue = {}

local _http = table.copy(http)

local function checkHttp()
    if #http_queue > 0 then
        if _http.canRequest() then
            local key, httpInfo = next(http_queue)
            http_queue[key] = nil
            
            local method = httpInfo.method
            if method=="get" then
                _http.get(
                    httpInfo.url,
                    httpInfo.callbackSuccess,
                    httpInfo.callbackFail,
                    httpInfo.headers
                )
            elseif method=="post" then
                _http.post(
                    httpInfo.url,
                    httpInfo.payload,
                    httpInfo.callbackSuccess,
                    httpInfo.callbackFail,
                    httpInfo.headers
                )
            end
            
            if http_queue == 0 then
                timer.stop("_HTTP_QUEUE_LOOP")
            end
        else
            timer.start("_HTTP_QUEUE_LOOP")
        end
    end
end
timer.create("_HTTP_QUEUE_LOOP", 1, 0, checkHttp)
timer.stop("_HTTP_QUEUE_LOOP")

/// Runs a new http GET request

// @param string url Http target url
// @param function callbackSuccess The function to be called on request success, taking the arguments body (string), length (number), headers (table) and code (number)
// @param function? callbackFail The function to be called on request fail, taking the failing reason as an argument
// @param table? headers GET headers to be sent
// @return number Index of http request
function http.get(_url, _cbY, _cbN, _headers)
    local httpTable = {
        method = "get",
        url = _url,
        callbackSuccess = _cbY,
        callbackFail = _cbN,
        headers = _headers
    }
    
    local requestIndex = table.insert(http_queue, httpTable)
    checkHttp()
    return requestIndex
end

/// Runs a new http POST request

/// @param string url Http target url
// @param table? payload Optional POST payload to be sent, can be both table and string. When table is used, the request body is encoded as application/x-www-form-urlencoded
// @param function? callbackSuccess Optional function to be called on request success, taking the arguments body (string), length (number), headers (table) and code (number)
// @param function? callbackFail Optional function to be called on request fail, taking the failing reason as an argument
// @param table? headers Optional POST headers to be sent
// @return number Index of http request
function http.post(_url, _payload, _cbY, _cbN, _headers)
    local httpTable = {
        method = "post",
        payload = _payload,
        url = _url,
        callbackSuccess = _cbY,
        callbackFail = _cbN,
        headers = _headers
    }
    
    local requestIndex = table.insert(http_queue, httpTable)
    checkHttp()
    return requestIndex
end

/// Cancels a queued http request

// @shared
// @param number index The index of the http request you want to cancel
function http.cancel(queueInd)
    if http_queue[queueInd] then
        http_queue[queueInd] = nil
        return true
    end
    
    return false
end