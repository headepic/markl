---
name: domain-research
description: Use when the user asks to research, investigate, map, understand, compare, or get up to speed on a domain, market, technology, company, product category, concept, paper area, policy area, or knowledge field; especially for "deep research", "调研", "研究一下", "帮我搞懂", "竞品分析", "领域地图", "学习路线", or strategy/learning/investment/product judgment briefs.
---

# Domain Research

## Overview

Turn an unclear topic into a sourced research brief with a domain map, historical context, current landscape, evidence matrix, open questions, and next-step recommendations. The goal is not to collect links; the goal is to form a defensible judgment.

## Operating Modes

Pick the smallest mode that satisfies the user:

| Mode | Use when | Output |
|---|---|---|
| Quick scan | The user wants orientation or a first pass | 1-2 page brief |
| Deep dive | The user wants serious understanding or a decision | Full research brief with sources |
| Evidence matrix | The user is validating claims or comparing options | Claim/source/confidence table |
| Reading path | The user wants to learn the field | Ordered syllabus and exercises |
| Competitive map | The user asks about a product/company/category | Landscape, alternatives, positioning |

If the user does not specify a mode, default to Quick scan. Offer to expand to Deep dive only after the scan unless the wording clearly asks for deep research.

## Research Workflow

### 1. Frame the Question

Identify:
- Research object: topic, company, product, concept, person, market, or field
- User intent: learning, strategy, product decision, investment, writing, technical selection, or competitive analysis
- Scope: geography, time period, audience level, and desired depth
- Decision pressure: what the user needs to decide after reading

Ask only if ambiguity changes the research outcome. Otherwise state assumptions and proceed.

### 2. Gather Sources

Use current sources for anything that may have changed: markets, laws, product specs, model releases, company status, funding, prices, standards, research fronts, and news.

Prefer sources in this order:
- Primary: official docs, papers, standards, filings, source repos, release notes, pricing pages, company blogs
- Direct evidence: data, benchmarks, issue trackers, user reviews, community threads, talks, interviews
- Secondary: reputable journalism, analyst reports, textbooks, surveys, explainers
- Tertiary: aggregators and listicles only for discovery, not final evidence

For academic or technical fields, include papers and surveys. For product/company research, include official pages, pricing, docs, changelogs, competitors, and user sentiment. For policy or regulated domains, include official agencies and statute/regulator pages.

### 3. Build the Domain Map

Map the field before judging it:
- Core concepts and vocabulary
- Main actors: companies, labs, communities, regulators, standards bodies, authors
- User/customer segments and jobs-to-be-done
- Value chain or technical stack
- Major schools of thought, tradeoffs, and controversies
- Adjacent domains and substitutes

### 4. Use Horizontal-Vertical Analysis

Use a two-axis pass adapted from horizontal-vertical analysis:

- Vertical axis: how the domain evolved over time, including origins, inflection points, failed paths, and why the current shape emerged.
- Horizontal axis: what exists now, including competing products, methods, institutions, approaches, and user choices.
- Intersection: how historical path dependencies explain current winners, gaps, risks, and future trajectories.

Do not write a timeline and a competitor table as filler. The value is in explaining causality: why this field looks this way now.

### 5. Make Claims Traceable

For every important claim, track:
- Claim
- Source(s)
- Evidence type: primary, data, expert, user sentiment, secondary, inference
- Confidence: high, medium, low
- Recency risk: stable, may change, actively changing
- Counterevidence or caveat

Separate facts from interpretation. Mark inference explicitly.

### 6. Synthesize

Turn gathered material into judgment:
- What matters most and why
- What people commonly misunderstand
- Where the field is moving
- What is overhyped, underappreciated, or structurally hard
- What the user should read, try, buy, avoid, monitor, or decide next

## Output Rules

Use the templates in [references/report-templates.md](references/report-templates.md) when helpful.

Always include:
- Executive summary
- Domain map
- Key findings with evidence
- Unknowns and weak spots
- Sources with links or precise citations

For deep dives, also include:
- Horizontal-vertical analysis
- Evidence matrix
- Counterarguments
- Future scenarios
- Recommended reading path

Keep the response proportional. A quick scan should be concise; a deep dive can be long, but should still be navigable.

## Quality Bar

- Current facts are verified with browsing or primary sources.
- Important claims do not rely on a single weak source.
- The brief names what is uncertain instead of smoothing it over.
- The structure helps the user think, not just admire the amount of research.
- The recommendations follow from the evidence, not from generic taste.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Starting with a generic definition | Start from the user's goal and decision context |
| Collecting links without a model | Build the domain map before synthesizing |
| Treating popularity as importance | Ask what job the actor/source performs in the ecosystem |
| Hiding weak evidence | Mark confidence and recency risk |
| Only explaining the present | Add the vertical axis to show how the present was formed |
| Only telling history | Add the horizontal axis to show current alternatives |
