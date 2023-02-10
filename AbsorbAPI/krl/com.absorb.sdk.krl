ruleset com.absorb.sdk {
  meta {
    provides tokenValid, users, department, departments, users_upload
    shares latestResponse, theToken, tokenValid, departments, users
, department // for manual testing
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
      tokenTime = ent:issued
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
    department = function(id){
      url = api_url+"departments/"+id
      response = http:get(url,headers=v1_headers())
      code = response{"status_code"}
      code == 200 => response{"content"}.decode() | null
    }
    departments = function(id){
      url = api_url+"departments?ExternalId="+id
      response = http:get(url,headers=v1_headers())
      code = response{"status_code"}
      code == 200 => response{"content"}.decode() | null
    }
    users = function(username){
      url = api_url+"users?username="+username
      response = http:get(url,headers=v1_headers())
      code = response{"status_code"}
      code == 200 => response{"content"}.decode() | null
    }
    users_upload = defaction(body){
      url = api_url + "users/upload?Key=0"
      http:post(url,headers=v1_headers(),json=[body]) setting(response)
      return response
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
      ent:issued := time:now()
    }
  }
  rule checkIfTokenNeeded {
    select when com_absorb_sdk token_check_needed
    if not tokenValid() then noop()
    fired {
      raise com_absorb_sdk event "tokenNeeded"
    }
  }
}
