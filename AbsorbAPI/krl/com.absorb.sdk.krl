ruleset com.absorb.sdk {
  meta {
    provides tokenValid, categories, users, department
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
    department = function(id){
      url = api_url+"departments/"+id
      response = http:get(url,headers=v1_headers())
      code = response{"status_code"}
      code == 200 => response{"content"}.decode() | null
    }
    departments = function(id){
      url = api_url+"departments?ExternalId="+id
.klog("id")
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
  rule createAccountForNewHire {
    select when com_absorb_sdk new_hire
      username re#^([a-z][a-z0-9]{1,7})$#
      departmentId re#^(\d{4})$#
      firstName re#(.+)#
      lastName re#(.+)#
      emailAddress re#(.+)# // more permissive than API
      externalId re#^(\d{9})$#
      gender re#^([FM])$#
      setting(username,dept_id,firstName,lastName,emailAddress,externalId,sex)
    pre {
      gender = sex=="F" => 2 | sex=="M" => 1 | 0
      department = departments(dept_id).head()
      departmentId = department => department{"Id"} | null
      body = {
        "username": username,
        "password": "ChangeMe",
        "departmentId": departmentId,
        "firstName": firstName,
        "lastName": lastName,
        "emailAddress": emailAddress,
        "externalId": externalId,
        "gender": gender,
        "activeStatus": 0,
        "isLearner": true,
        "isInstructor": false,
        "isAdmin": false,
        "hasUsername": true,
      }
.klog("body")
      url = api_url + "users/upload?Key=0"
    }
    if departmentId then
      http:post(url,headers=v1_headers(),json=[body]) setting(response)
    fired {
      raise com_absorb_sdk event "account_added" attributes response
    }
  }
}
