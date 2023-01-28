ruleset com.absorb.sdk {
  meta {
    provides tokenValid, categories, departments
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
    v1_headers = function(){
      {
        "Content-Type":"application/json",
        "x-api-key":PrivateKey,
        "Authorization":ent:token
      }
    }
    categories = function(){
      http:get(api_url+"categories",headers=v1_headers())
    }
    departments = function(id){
      url = api_url+"departments?ExternalId="+id
      response = http:get(url,headers=v1_headers())
      code = response{"status_code"}
      code == 200 => response{"content"}.decode() | null
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
