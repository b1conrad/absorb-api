ruleset edu.byu.sdk {
  meta {
    provides tokenValid, subscriptions 
    shares latestResponse, theToken, tokenValid
  }
  global {
    latestResponse = function(){
      ent:latestResponse
    }
    theToken = function(){
      ent:token{"access_token"}
    }
    ClientID = meta:rulesetConfig{"ClientID"}
    ClientSecret = meta:rulesetConfig{"ClientSecret"}
    api_url = "https://api.byu.edu/"
    tokenValid = function(){
      tokenTime = ent:valid
      ent:token{"access_token"}
.klog("theToken")
      && tokenTime
.klog("timestamp")
      && (time:add(tokenTime,{"hours":2}) > time:now())
.klog("not yet expired")
    }
    subscriptions = function(){
      url = api_url + "domains/eventhub/v2/subscriptions"
      the_headers = {
        "Content-Type":"application/json",
        "Authorization":"Bearer "+ent:token{"access_token"}
      }
.klog("headers")
      http:get(url,headers=the_headers)
    }
  }
  rule generateAuthenticationToken {
    select when edu_byu_sdk tokenNeeded
    pre {
      creds = {
        "username":ClientID,
        "password":ClientSecret,
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
