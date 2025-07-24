# 🔥 **Redis Access Guide - localhost:6379**

## ❌ **Why HTTP Doesn't Work**
Redis uses a **binary TCP protocol**, NOT HTTP. That's why `http://localhost:6379` shows "connection reset."

---

## ✅ **Correct Ways to Access Redis**

### **1. Command Line Access**
```bash
# Direct access (if redis-cli installed locally)
redis-cli -h localhost -p 6379

# Via Docker container (recommended)
docker exec -it langgraph-redis redis-cli

# Quick test
docker exec langgraph-redis redis-cli ping
# Returns: PONG
```

### **2. Your Enhanced Start Script**
```bash
# Automatic Redis connectivity test
./start.sh status
# Shows: ✓ 📊 Redis (6379): Connection successful
```

### **3. Common Redis Commands**
```bash
# Connect to Redis
docker exec -it langgraph-redis redis-cli

# Inside Redis CLI:
ping                    # Test connection
info                    # Server information  
keys *                  # List all keys
get <key>              # Get value
set <key> <value>      # Set value
flushall               # Clear all data (careful!)
exit                   # Exit CLI
```

---

## 🖥️ **GUI Access with RedisInsight**

### **Option A: Docker RedisInsight (Recommended)**
```bash
# Add RedisInsight to your docker-compose.yml or run standalone:
docker run -d \
  --name redisinsight \
  -p 8001:8001 \
  -v redisinsight:/db \
  --network langgraph-network \
  redislabs/redisinsight:latest

# Access at: http://localhost:8001
```

### **Option B: Install RedisInsight Desktop**
- Download from: https://redis.com/redis-enterprise/redis-insight/
- Connect to: `localhost:6379`

---

## 🔧 **Add RedisInsight to Your Stack**

Add this service to your `docker-compose.yml`:

```yaml
  redisinsight:
    image: redislabs/redisinsight:latest
    container_name: langgraph-redisinsight
    ports:
      - "8001:8001"
    volumes:
      - redisinsight_data:/db
    networks:
      - langgraph-network
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8001"]
      interval: 30s
      timeout: 10s
      retries: 3
```

And add the volume:
```yaml
volumes:
  # ... existing volumes
  redisinsight_data:
```

---

## 🚀 **Quick Access Summary**

| Method | URL/Command | Description |
|--------|-------------|-------------|
| **CLI** | `docker exec -it langgraph-redis redis-cli` | Direct command line |
| **Status Check** | `./start.sh status` | Automated connectivity test |
| **RedisInsight** | `http://localhost:8001` | Web-based GUI (after setup) |
| **Desktop Tools** | Install RedisInsight desktop | Native GUI application |

---

## 🔍 **Testing Your Redis**

```bash
# 1. Basic connectivity
docker exec langgraph-redis redis-cli ping

# 2. Server info
docker exec langgraph-redis redis-cli info server

# 3. Memory usage
docker exec langgraph-redis redis-cli info memory

# 4. Current data
docker exec langgraph-redis redis-cli keys "*"

# 5. Interactive session
docker exec -it langgraph-redis redis-cli
```

---

## ⚠️ **Important Notes**

- **Redis ≠ HTTP**: Redis uses TCP binary protocol, not HTTP
- **Port 6379**: Direct Redis protocol, not web accessible
- **GUI Access**: Use RedisInsight or other Redis desktop tools
- **Security**: Redis has no built-in authentication in basic setup
- **Data**: Redis is in-memory with optional persistence

**✅ Your Redis is working perfectly! Use the CLI or add RedisInsight for GUI access.**
