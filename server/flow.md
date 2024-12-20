# Principles of Operation

The code in this repo orchestrates a single flow:
- Someone is hired into a department at BYU
- The `edu.byu/HR Personal Action/Hired` event is raised in Event Hub
- Event Hub does an HTTP POST to the IICS Absorb updater pico (because we subscribed and provided a web hook)
- That event is queued for the pico and when the pico is ready [the `reactToWebhook` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/EventHub/krl/edu.byu.hr_hired.krl#L278-L291) is selected
- If the payload (a JSON object) is considered valid, it is stored, and an internal `edu_byu_hr_hired:hired_event_received` event is raised
- That internal event selects [the `internalFollowUp` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/EventHub/krl/edu.byu.hr_hired.krl#L292-L314)
- If the hiring is for one of the departments of interest, the rule fires, queueing up two additional events for the same pico
    - `edu.byu.sdk:token_check_needed`
    - `edu_byu_hr_hired:new_hire_of_interest`
- When the pico is ready, [the `checkIfTokenNeeded` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/EventHub/krl/edu.byu.sdk.krl#L76-L82) is selected
- If the token (obtained through OAuth as a grant type of client credentials) has expired, the rule fires and an internal event `edu_byu_sdk:tokenNeede` event is raised
- That internal event selects [the `generateAuthenticationToken` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/EventHub/krl/edu.byu.sdk.krl#L58-L75)
- A new token is requested and stored (meanwhile, the `edu_byu_hr_hired:new_hire_of_interest` event is still in the pico's queue)
- When the pico is ready, [the `createNewAbsorbAccount` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/EventHub/krl/edu.byu.hr_hired.krl#L431-L449) is selected for that event
- If there is a relationship established with an Absorb pico (either sandbox or production), this pico sends it an `absorb_api_test:account_requested` event
- That event is queued for the Absorb pico and when it is ready, [the `createOrAdjustAccount` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/AbsorbAPI/krl/edu.byu.absorb-api-test.krl#L85-L106) is selected
- This rule always fires and queues up three additional events for this same Absorb pico
    - `com_absorb_sdk:token_check_needed`
    - `absorb_api_test:account_may_need_updating`
    - `absorb_api_test:account_may_need_creating`
- When the pico is ready, [the `checkIfTokenNeeded` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/AbsorbAPI/krl/com.absorb.sdk.krl#L76-L82) is selected
- If the Absorb API token has expired, the rule fires and raises an internal `com_absorb_sdk:tokenNeeded` event
- That internal event selects [the `generateAuthenticationToken` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/AbsorbAPI/krl/com.absorb.sdk.krl#L59-L75)
- A new token is requested (using the Absorb `Authenticate` API) and stored (meanwhile two events are still in the pico's queue)
- When the pico is ready, the `absorb_api_test:account_may_need_updating` event selects [the `updateExistingAccount` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/AbsorbAPI/krl/edu.byu.absorb-api-test.krl#L107-L123)
- If there is already an account for that username (Absorb terminology; our Net-ID) then that account is set to `activeStatus` and given a (possibly) new department using the Absorb `users/upload` API, and an internal `absorb_api_test:account_updated` event is raised
- When the pico is ready, the `absorb_api_test:account_may_need_creating` event selects [the `createAccount` rule](https://github.com/byu-oit/b1conrad-absorb-api/blob/main/AbsorbAPI/krl/edu.byu.absorb-api-test.krl#L124-L145)
- If there is not already an account for that username, then an account is created using the Absorb `users/upload` API, and an internal `absorb_api_test:account_created` event is raised
