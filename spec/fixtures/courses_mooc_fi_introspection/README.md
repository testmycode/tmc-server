# courses.mooc.fi introspection fixtures

Hand-mirrored copies of what secret-project-331 emits from
`POST /api/v0/main-frontend/oauth/introspect` (RFC 7662). They exist because
`CoursesMoocFiTokenIntrospector` reads that response by member name, and every other spec in
this repo stubs the response instead of producing it — so without these, a rename on either
side of the wire passes CI in both repos and logs every user out in production.

Upstream definition: `services/headless-lms/server/src/domain/oauth/introspect_response.rs`
(struct `IntrospectResponse`). Its `tests::golden_serialized_shape` pins the same JSON on that
side; `active_response.json` is a copy of the literal in that test, so the two can be diffed by
eye. **The mirror is manual — when the upstream struct changes, update these files in the same
change.** The pairing is only as honest as that discipline: sp331's golden test fails when its
own output drifts, `courses_mooc_fi_introspection_contract_spec.rb` fails when these files stop
matching what the introspector reads, and neither can observe the other repo.

`aud` is deliberately absent: every access token sp331 mints is created with `audience: None`,
so the member is never emitted. See the note in the introspector.
