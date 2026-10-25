# SPEC: <App name>

Status: draft            <!-- human changes to: approved -->
Approved by: <name>      Date: <YYYY-MM-DD>

## 1. Problem and audience
<Who, what they struggle with today, in plain words.>

## 2. Outcome
<One sentence: what is true for the user after this ships.>

## 3. Out of scope (v1)
- <explicit non-goals>

## 4. Constraints
- Platform: iOS (Expo / React Native)
- Accounts and privacy: <who can see what>
- Offline, push, payments, camera, location: <needed or not, and why>
- Must never happen: <data loss, public exposure of private content, surprise charges>
- Budget and services: <limits>

## 5. Decisions
| Question (plain language) | Answer | Who decided | Date |
| --- | --- | --- | --- |

## 6. Slices (build order, thinnest end-to-end first)
### Slice 1: <name>
- User story: <as a ..., I can ..., so that ...>
- Acceptance criteria (observable on a phone):
  - [ ] AC1.1 <behavior>
  - [ ] AC1.2 <behavior>
- Data: <exists | new>. If new: table, write path, protected read, screen.
- Security: <who can read/write; the row-level security rule in one line>
- States: loading / empty / error / success described.
- Human-only steps: <e.g. apply production migration>

### Slice 2: <name>
...

## 7. Data model
<Tables, columns, ownership column, and the row-level security policy for each operation.>

## 8. Risks and open questions
<Anything unresolved. An open question blocks approval unless marked non-blocking.>

## 9. Release
- Bundle/store name: <...>
- Human gates: <store account, review submission, production secrets>
