ruleset com.absorb.sdk {
  meta {
    provides tokenValid, categories
    shares latestResponse, theToken
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
      ent:token && ent:valid && time:add(ent:valid,{"hours":2}) < time:now()
    }
    categories = function(authenticationToken){
      the_headers = {
        "Content-Type":"application/json",
        "x-api-key":PrivateKey,
        "Authorization":"api_key: "+authenticationToken
      }
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
      ent:token := response{"status_code"}==200 => response{"content"} | null
      ent:valid := response{"status_code"}==200 => time:now() | false
    }
  }
}
