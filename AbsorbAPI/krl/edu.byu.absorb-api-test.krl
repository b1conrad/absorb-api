ruleset edu.byu.absorb-api-test {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module com.absorb.sdk alias absorb
    shares tokenValid, getCategories, getDepartments, getUsers, getDepartmentById
  }
  global {
    event_domain = "absorb_api_test"
    tokenValid = function(){
      absorb:tokenValid()
    }
    getCategories = function(){
      absorb:tokenValid() => absorb:categories()
                           | "token needed"
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
}
