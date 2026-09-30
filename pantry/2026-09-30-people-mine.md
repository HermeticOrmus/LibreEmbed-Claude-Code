# People mine: LibreEmbed-Claude-Code

What people who use the product said in its own public places: issues, issue comments, discussions, pull requests, and forks that changed something. Optional third pantry source; a product with no outside voices yet leaves the Hits table empty and says so.

## How this fills

1. List the product's own repos (the kitchen law names them).
2. Read what people outside the maintainers wrote since the last run: issues (the `feedback` label first), issue comments, discussions and their comments, pull requests, and forks with commits ahead of the default branch.
3. One row per voice. Quote a short snippet and link the exact issue, comment, discussion, PR or commit. Say whether they gave credit consent when the source has a consent box.
4. Tag each row with the capability it is about, in the same words as the competitor map's matrix, so the queue can cite it next to competitor and X rows.
5. Never count stars as feedback, never infer sentiment the person did not state, never paraphrase a number. Maintainers' own issues are not voices.
6. Save as `YYYY-MM-DD-people-mine.md` beside the other dated files (keep this TEMPLATE).

## Hits

No outside voices yet: every issue, comment and pull request in the repo is by the maintainer, there are no discussions, and no fork has commits ahead of `main`.

| Repo | Kind (bug/feature/question/praise/contribution) | Snippet | Link | Theme (matrix capability) | Credit consent |
|------|--------------------------------------------------|---------|------|---------------------------|----------------|

## Audience context (not feedback)

Stars and forks are not feedback and are not counted as voices. This aggregate is recorded only because it bears on which translations to stock. No person is named.

- Stargazers: 49 (GitHub API, 2026-09-30). 10 list a location on their GitHub profile; 8 of those 10 are in China (entries such as "China", "中国", Shenzhen, Hefei, Beijing). The other 2 are outside China.
- Forks: 12. 3 fork owners list a location; 2 are in China and 1 is a two-letter city abbreviation we did not resolve.
- Discussions are enabled (categories include Show and tell); 0 discussions so far.

## Read log (what we read)

- Issues and pull requests, all states (`gh api repos/HermeticOrmus/LibreEmbed-Claude-Code/issues?state=all`): #1 Release v1.0.0 (maintainer, closed), #2 v1.0.0 marketplace PR (maintainer, merged), #3 Open the kitchen (maintainer, open). 0 outside authors.
- Issue comments (`/issues/comments`): 1, by the maintainer, on #1. 0 outside.
- Pull request review comments (`/pulls/comments`): 0.
- Issues with the `feedback` label: 0.
- Discussions (GraphQL `repository.discussions`): 0.
- Forks (`/forks`): 12. Compared each fork's `main` with ours (`/compare/main...<owner>:main`): all 12 are 0 commits ahead (16 or 27 behind). Every fork has only a `main` branch. 0 forks with changes.
- Stargazer and fork-owner profiles (`/stargazers`, `/users/<login>`): read the `location` field only, for the aggregate above.
