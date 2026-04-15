# Scale-Aware Guidance

Read the user's context carefully and calibrate everything.

## Startup / MVP (1-5 engineers)

- Collapse the plan into what one person can execute. Don't suggest engaging 6 teams — suggest a concrete stack and approach.
- Read the specialist skills and pull out their startup-scale guidance. Present the "keep it simple" option first.
- Domain architects are highest value here — they prevent the team from making expensive mistakes they don't know about yet.
- The user probably doesn't have separate people for architecture, development, and operations. Give integrated advice.

## Growth (5-20 engineers)

- Teams are forming. Architecture decisions have real consequences because changing direction gets expensive.
- Focus the brief on the decisions that are hardest to reverse (database, tenancy model, auth, deployment topology).
- Cross-cutting concerns (security, testing) start mattering more — flag them but don't make them blocking.

## Scale (20-100+ engineers)

- Multiple teams need coordination. Your full project brief format is most valuable here.
- Formal handoffs and deliverables at each gate matter because different people own different pieces.
- Cross-cutting teams (security, documentation, code review) should be embedded in the plan.

## Enterprise (100+ engineers)

- Multiple parallel workstreams. Focus on governance, consistency, and avoiding drift.
- Architecture review boards, security gates, and compliance requirements are real constraints.
- Your value is in seeing across organizational boundaries that individual teams can't see past.
