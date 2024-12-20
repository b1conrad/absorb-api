# absorb-api
playing around to learn the Absorb API

## Rationale

Story STRY0078158 asks
>Absorb is the Employee Learning Management System  (Y-Train).  Real-time account setup is needed for new employees.
>
>Can we use Informatica Cloud to listed for employee events and then set up that using IICS?

This work would produce what we call "an integration".

## Input/Trigger

This should be possible because "the HR system is raising `Hired`, `Job Changed`, and `Terminated` events."

We will need to subscribe to these events on Event Hub.

## Output/API

We will need to learn how to use the Absorb API to create accounts for people who have been hired.

## Strategy

### Prime directive
Take as little time as possible from engineers working on Project Granite.

### Depend on existing integration for reconciliation

Tauna, our campus partner, when asked about a standard workaround, said this:

>Currently, there is not a work around. I usually receive an email from the manager or the employee wondering why they cannot get into Absorb. Then I send an email apology explaining the situation. Although I try to communicate with hiring managers and HR about the situation, there are so many managers that still do not know about the situation. In many cases, they are hiring JIT for the event or contract so the option of hiring in advance is not realistic. CE, Athletics, Dining Services, and Physical Facilities are the departments that need this the most.

We plan to take action only for `Hired` events from these departments:
1. CE, 
1. Athletics, 
1. Dining Services, and 
1. Physical Facilities

Upon receiving the `Hired` event for someone not yet in the Absorb system, we will create a user account.

We will depend on the existing batch (early weekday mornings) to "true up" or reconcile.
This will also take care of removing accounts for terminated employees, so we will ignore the `Terminated` events.

The exact departments and their codes are available upon request.

As of today, February 14, 2023 at 14:00 we are beta testing the complete proof of concept for selected departments.

### External documentation

See slide deck [IICS Absorb updater](https://docs.google.com/presentation/d/1lcHs1FLFqN0vCFG_eXpFHKJ-VFlvLoAyx5CT4ph1mWM/edit?usp=sharing).

### Repo

[https://github.com/b1conrad/absorb-api](https://github.com/b1conrad/absorb-api)
