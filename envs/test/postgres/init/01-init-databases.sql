-- -- Initialize databases for LangGraph stack

-- -- Create LangSmith database
-- CREATE DATABASE langsmith;

-- -- Grant permissions
-- GRANT ALL PRIVILEGES ON DATABASE langsmith TO postgres;

-- -- Create extensions in default database
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- -- Create extensions in langsmith database
-- \c langsmith;
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- -- Create a table for LangGraph checkpoints in default database
-- \c postgres;
-- CREATE TABLE IF NOT EXISTS checkpoints (
--     checkpoint_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     graph_id VARCHAR(255) NOT NULL,
--     thread_id VARCHAR(255) NOT NULL,
--     checkpoint_data JSONB NOT NULL,
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Create index for faster lookups
-- CREATE INDEX IF NOT EXISTS idx_checkpoints_graph_thread 
-- ON checkpoints(graph_id, thread_id);

-- CREATE INDEX IF NOT EXISTS idx_checkpoints_created_at 
-- ON checkpoints(created_at);

-- -- Create a simple logging table
-- CREATE TABLE IF NOT EXISTS agent_logs (
--     log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     agent_id VARCHAR(255),
--     run_id VARCHAR(255),
--     log_level VARCHAR(50),
--     message TEXT,
--     metadata JSONB,
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
-- );

-- CREATE INDEX IF NOT EXISTS idx_agent_logs_agent_run 
-- ON agent_logs(agent_id, run_id);

-- COMMIT;
