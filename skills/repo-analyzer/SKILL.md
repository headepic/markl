---
name: repo-analyzer
description: Generates structured, evidence-backed project analysis reports in both Markdown and HTML formats.
triggers:
  - project analysis
  - source code analysis
  - codebase review
  - architecture analysis
  - tech stack analysis
  - project overview report
  - code audit
---

# Repo Analyzer Skill Documentation

This document defines Claude Code's **repo-analyzer** skill -- a structured codebase analysis tool that generates evidence-backed project reports.

## Purpose

The skill produces two deliverables:
- `project-analysis.md` (Markdown report)
- `project-analysis.html` (styled, interactive HTML)

These go beyond surface walkthroughs by providing **structured output** (tech stack tables, risk matrices, module breakdowns) and **architectural depth** explaining design rationale and consequences.

## Activation Triggers

Use when users request: "project analysis," "source code analysis," "codebase review," "architecture analysis," "tech stack analysis," "project overview report," "code audit," or when providing a directory path asking for understanding/review.

## Investigation Phases

**Phase 1: Discovery** -- Read orientation sources: READMEs, dependency manifests, git history, CI/CD config, license.

**Phase 2: Tech Stack** -- Map languages, frameworks, libraries, infrastructure, dev tooling, and storage with architectural significance.

**Phase 3: Architecture** -- Identify the pattern (monolith, microservices, etc.), execution flow, layer structure, entry points, and data flow. Generate Mermaid diagrams.

**Phase 4: Core Modules** -- Surface the 3-7 critical modules defining core behavior, distinctive design decisions, external integrations, and dependency issues.

**Phase 5: Core Functionality** -- Deep-dive into business logic, APIs, configuration, and extensibility (when warranted).

**Phase 6: Quality & Risk** -- Assess test coverage, error handling, security patterns, technical debt, scalability, documentation, dependencies, and commercial viability.

## Output Requirements

Reports must contain these sections:
1. Project Thesis
2. Repository Shape
3. Tech Stack
4. Architecture Design (with Mermaid diagrams)
5. Core Modules
6. Distinctive Design Decisions
7. Quality Signals & Risks
8. Unknowns Worth Verifying

HTML must be self-contained, support light/dark modes (toggle in sidebar), include navigation links, render on mobile/desktop, and use inline Mermaid for diagrams.

## Writing Standards

- Open sections with declarative statements backed by file paths
- Explain consequences, not just content
- Avoid README parroting; surface distinctive qualities
- Every bullet must state fact and implication
- No credentials, API keys, or secrets in output
- Distinguish inference from confirmed facts
