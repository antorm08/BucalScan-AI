## 1. Normalized Runtime Persistence

- [x] 1.1 Stop creating compatibility `analyses` rows in the prediction transaction
- [x] 1.2 Remove unused runtime CRUD helpers that query or create legacy analyses

## 2. Normalized Read Models

- [x] 2.1 Rebuild history search, filters, sorting, pagination, and serialization from normalized clinical tables
- [x] 2.2 Rebuild workspace daily summaries from normalized model predictions

## 3. Regression Coverage

- [x] 3.1 Update history fixtures and assertions to prove rows are returned without legacy duplicates
- [x] 3.2 Prove prediction persistence and summaries do not create or depend on `analyses`
- [x] 3.3 Run migration tests (`5 passed`), the complete backend suite (`119 passed`), and strict OpenSpec validation
