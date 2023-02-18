# krl rulesets

A specific version of each ruleset will be installed in the production pico.

Futher development can proceed and be tested in sandbox.

## `com.absorb.sdk`

This ruleset [wraps](https://picostack.blogspot.com/2023/02/web-api-needing-token-grant.html)
the Absorb API (currently version 1).

### configuration

When installed in a pico, it must be configured.

Configuration is expressed in a JSON string, like _one_ of these (redacted):
```
{"SubDomain":"byu.sandbox","Username":"NETID","Password":"****","PrivateKey":"a…7-redacted"}
{"SubDomain":"byu","Username":"NETID","Password":"****","PrivateKey":"a…f-redacted"}
```

This identifies:
- `SubDomain`: which `.myabsorb.com` instance the ruleset will support API calls for
- `Username`: the Net-ID of the admin account to be used
- `Password`: the Absorb account password of that admin account
- `PrivateKey`: a GUID assigned by Absorb for use of the API in that instance

### modules used

None

### web pages 

None

### functions shared

`latestResponse`,
`theToken`,
`tokenValid`,
`departments`,
`users`

### functions and actions provided

`tokenValid`, `users`, `department`, `departments`, `users_upload`

## `edu.byu.absorb-api-test`

It must be installed _after_ the `sdk` module.

### modules used

- `io.picolabs.wrangler`
- `com.absorb.sdk`

### web pages 

None

### functions shared

`tokenValid`,
`getDepartments`,
`getUsers`,
`getDepartmentById`

### functions and actions provided

None (meaning that it is not meant to be used as a module)

