# krl rulesets

A specific version of each ruleset will be installed in the production pico.

Futher development can proceed and be tested in sandbox, while production runs.

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
- `Username`: the Absorb username of the admin account to be used (at BYU it is a Net-ID)
- `Password`: the Absorb account password of that admin account
- `PrivateKey`: a GUID assigned by Absorb for use of the API in that instance

### modules used

None

### web pages 

None

### functions shared

Shared functions can be used from the Pico Labs developer UI in the pico's Testing tab.
Given an Event Channel Identifier (ECI), they can be used in URLs of the form
```
http://DOMAIN:3000/c/ECI/query/com.absorb.sdk/NAME?GIVEN=VALUE
```
providing the DOMAIN hosting the pico engine, the ECI, the NAME of the shared function, and given values if any.

- `latestResponse`, HTTP response from the latest attempt to generate a token
- `theToken`, the access token most recently generated
- `tokenValid`, `true` or `false`, the latest token has not yet expired
- `departments`, given `id` (a BYU department code (four digit number)), an array of Absorb department objects (wraps the `departments?ExternalId=` API)
- `users`, given `username` (a BYU Net-ID), an array of Absorb user objects (wraps the Absorb `users?username=` API)

### functions and actions provided

Provided functions and actions can be used in another ruleset that uses this one as a module.

- `tokenValid`, `true` or `false`, the latest token has not yet expired
- `users`, given `username` (a BYU Net-ID), an array of Absorb user objects (wraps the Absorb `users?username=` API)
- `department`, given `id` (an Absorb department id (a GUID)), an Absorb department object (wraps the `departments/:id` API)
- `departments`, given `id` (a BYU department code (four digit number)), an array of Absorb department objects (wraps the `departments?ExternalId=` API)
- `users_upload`, an action which given a user object, upserts the Absorb user (wraps the `users/upload?Key=0` API)

### salient events

- `com_absorb_sdk:tokenNeeded`, reacts by generating a client credential token
- `com_absorb_sdk:token_check_needed`, reacts by checking if the token has expired and regenerating if needed

## `edu.byu.absorb-api-test`

It must be installed _after_ the `sdk` module.

### modules used

- `io.picolabs.wrangler`
- `com.absorb.sdk`

### web pages 

None

### functions shared

`tokenValid`, `true` or `false`, the latest token has not yet expired (wraps the function of the same name provided by the SDK)
`getDepartments`, given `id` (a BYU department code (four digit number)), an array of Absorb department objects (wraps the SDK `departments`)
`getUsers`, given `username` (a BYU Net-ID), an array of Absorb user objects (wraps the SDK `users`)
`getDepartmentById`, given `id` (an Absorb department id (a GUID)), an Absorb department object (wraps the SDK `department`)

### functions and actions provided

None (meaning that it is not meant to be used as a module)

### salient events

- `wrangler ruleset_installed`, reacts by making a new ECI tagged "absorb-api-test"
- `absorb_api_test token_needed`, reacts by raising the `com_absorb_sdk:tokenNeeded` event
- `absorb_api_test new_hire`, reacts by invoking the `sdk:user_upload` action based on given attributes (username, departmentId, (4 digits), firstName, lastName, emailAddress, externalId (9 digits), gender (F/M))
- `absorb_api_test account_requested`, updates an existing Absorb account or creates a new one (same attributes as above)
