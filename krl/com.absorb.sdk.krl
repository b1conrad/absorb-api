ruleset com.absorb.sdk {
  meta {
    provides tokenValid, categories
    shares latestResponse, theToken, tokenValid
  }
  global {
    latestResponse = function(){
      ent:latestResponse
    }
    theToken = function(){
      ent:token
    }
    SubDomain = meta:rulesetConfig{"SubDomain"}
    Username = meta:rulesetConfig{"Username"}
    Password = meta:rulesetConfig{"Password"}
    PrivateKey = meta:rulesetConfig{"PrivateKey"}
    api_url = "https://"+SubDomain+".myabsorb.com/api/Rest/v1/"
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
        "x-api-key":PrivateKey,
        "Authorization":ent:token
      }
.klog("headers")
      http:get(api_url+"categories",headers=the_headers)
    }
  }
  rule generateAuthenticationToken {
    select when com_absorb_sdk tokenNeeded
    pre {
      BodyParameters = {
        "Username":Username,
        "Password":Password,
        "PrivateKey":PrivateKey
      }
    }
    http:post(api_url+"Authenticate",json=BodyParameters) setting(response)
    fired {
      ent:latestResponse := response
      ent:token := response{"status_code"}==200 => response{"content"}.decode()
                                                 | null
      ent:valid := time:now()
    }
  }
}
