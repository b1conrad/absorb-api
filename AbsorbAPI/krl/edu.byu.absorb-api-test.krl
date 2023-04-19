ruleset edu.byu.absorb-api-test {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module com.absorb.sdk alias absorb
    use module io.picolabs.subscription alias rel
    shares tokenValid, getDepartments, getUsers, getDepartmentById
  }
  global {
    event_domain = "absorb_api_test"
    tokenValid = function(){
      absorb:tokenValid()
    }
    getDepartmentById = function(id){
      absorb:tokenValid() => absorb:department(id)
                           | "token needed"
    }
    getDepartments = function(id){
      absorb:tokenValid() => absorb:departments(id)
                           | "token needed"
    }
    getUsers = function(net_id){
      absorb:tokenValid() => absorb:users(net_id)
                           | "token needed"
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["absorb-api-test"],
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise absorb_api_test event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when absorb_api_test factory_reset
    foreach wrangler:channels(["absorb-api-test"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule generateAuthenticationToken {
    select when absorb_api_test token_needed
    fired {
      raise com_absorb_sdk event "tokenNeeded"
    }
  }
  rule createNewAccountManually { // manual use through Testing tab
    select when absorb_api_test new_hire
      username re#^([a-z][a-z0-9]{1,7})$#
      departmentId re#^(\d{4})$#
      firstName re#(.+)#
      lastName re#(.+)#
      emailAddress re#(.+)# // more permissive than API
      externalId re#^(\d{9})$#
      gender re#^([FM?])$#
      setting(username,dept_id,firstName,lastName,emailAddress,externalId,sex)
    pre {
      gender = sex=="F" => 2 | sex=="M" => 1 | 0
      department = absorb:departments(dept_id).head()
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
    }
    if departmentId then absorb:users_upload(body) setting(response)
    fired {
      raise absorb_api_test event "account_added" attributes response
    }
  }
  rule createOrAdjustAccount {
    select when absorb_api_test account_requested
    every {
      event:send({
        "eci":meta:eci,
        "domain":"com_absorb_sdk",
        "type":"token_check_needed",
      })
      event:send({
        "eci":meta:eci,
        "domain":event_domain,
        "type":"account_may_need_updating",
        "attrs":event:attrs,
      })
      event:send({
        "eci":meta:eci,
        "domain":event_domain,
        "type":"account_may_need_creating",
        "attrs":event:attrs,
      })
    }
  }
  rule updateExistingAccount {
    select when absorb_api_test account_may_need_updating
      username re#(.+)# setting(username)
    pre {
      department = event:attrs{"departmentId"}.decode()
      accts = absorb:users(username)
      acct = accts.typeof()=="Array" && accts.length() => accts.head() | null
      logit = acct.klog("acct")
      obj = acct.isnull() => null |
            acct.put("DepartmentId",department.get("a_id"))
                .put("ActiveStatus",0)
    }
    if obj then absorb:users_upload(obj) setting(response)
    fired {
      raise absorb_api_test event "account_updated" attributes response
        .put("event_id",event:attrs{"event_id"})
    }
  }
  rule createAccount {
    select when absorb_api_test account_may_need_creating
      username re#(.+)#
      gender re#([FM?])$#
      setting(username,sex)
    pre {
      department = event:attrs{"departmentId"}.decode()
      gender = sex=="F" => 2 | sex=="M" => 1 | 0
      accts = absorb:users(username)
      acct = accts.typeof()=="Array" && accts.length() => accts.head() | null
      obj = acct => null |
        event:attrs.put("departmentId",department.get("a_id"))
                   .put("gender",gender)
                   .put("password","ChangeMe")
                   .delete("id")
.klog("obj")
    }
    if obj then absorb:users_upload(obj) setting(response)
    fired {
      raise absorb_api_test event "account_created" attributes response
        .put("event_id",event:attrs{"event_id"})
    }
  }
  rule reportBack {
    select when absorb_api_test account_created
             or absorb_api_test account_updated
    pre {
      eci = rel:established("Rx_role","outflow").head(){"Tx"}
      event_id = event:attrs{"event_id"}
      response = event:attrs.delete("event_id")
    }
    if eci && event_id then
      event:send({"eci":eci,"domain":"edu_byu_hr_hired","type":"absorb_response",
       "attrs":{"event_id":event_id,"response":response}
     })
  }
}
