ruleset com.absorb.sdk {
  meta {
    provides Authenticate, categories
  }
  global {
    SubDomain = meta:rulesetConfig{"SubDomain"}
    Username = meta:rulesetConfig{"Username"}
    Password = meta:rulesetConfig{"Password"}
    PrivateKey = meta:rulesetConfig{"PrivateKey"}
    Authenticate = defaction(){
      BodyParameters = {
        "Username":Username,
        "Password":Password,
        "PrivateKey":PrivateKey
      }
      api_url = "https://"+SubDomain+".myabsorb.com/api/Rest/v1/Authenticate"
      http:post(api_url,json=BodyParameters) setting(response)
      return response
    }
    categories = function(authenticationToken){
      api_url = "https://"+SubDomain+".myabsorb.com/api/Rest/v1/categories"
      the_headers = {
        "Content-Type":"application/json",
        "x-api-key":PrivateKey,
        "Authorization":"api_key "+authenticationToken
      }
      http:get(api_url,headers=the_headers)
    }
  }
}
