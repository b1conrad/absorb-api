ruleset edu.byu.sdk {
  meta {
    provides tokenValid
    shares latestResponse, theToken, tokenValid
  }
  global {
    latestResponse = function(){
      ent:latestResponse
    }
    theToken = function(){
      ent:token
    }
    ClientID = meta:rulesetConfig{"ClientID"}
    ClientSecret = meta:rulesetConfig{"ClientSecret"}
    api_url = "https://api.byu.edu/"
    tokenValid = function(){
      tokenTime = ent:valid
      ent:token
.klog("theToken")
      && tokenTime
.klog("timestamp")
      && (time:add(tokenTime,{"hours":2}) > time:now())
.klog("not yet expired")
    }
    categories = function(){
      the_headers = {
        "Content-Type":"application/json",
        "Authorization":ent:token
      }
.klog("headers")
      http:get(api_url+"categories",headers=the_headers)
    }
  }
  rule generateAuthenticationToken {
    select when edu_byu_sdk tokenNeeded
    pre {
      creds = {
        "ClientID":ClientID,
        "ClientSecret":ClientSecret,
      }
      data = {"grant_type":"client_credentials"}
    }
    http:post(api_url+"token",auth=creds,form=data) setting(response)
    fired {
      ent:latestResponse := response
      ent:token := response{"status_code"}==200 => response{"content"}.decode()
                                                 | null
      ent:valid := time:now()
    }
  }
}
