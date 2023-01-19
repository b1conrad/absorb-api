ruleset edu.byu.absorb-api-test {
  meta {
    use module com.absorb.sdk alias sdk
    shares getToken
  }
  global {
    getToken = function(){
      sdk:Authenticate()
    }
  }
}
