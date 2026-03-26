# Command Adaptation Progress

Generated against the official Redis 8.6 command reference on 2026-03-25.

Source: https://redis.io/docs/latest/commands/redis-8-6-commands/

## Legend

- `Helper`: `Yes` means a typed helper appears to exist; `Family` means support exists at the command-family level but may not be exposed as a dedicated helper for that exact command; `No` means raw `sendCommand()` only.
- `Cluster`: `Yes` means `ClusterCommandSpec` has direct support; `Family` means routing is handled by a family-level parser or no-key family rule; `No` means no dedicated local routing support.
- `Status`: a compact summary derived from `Helper` and `Cluster`.
- Some dangerous administrative helpers are intentionally isolated in `RedisAdminCommands` and are not mixed into the default `Daredis` / `DaredisCluster` client APIs.

## Summary

- Total commands tracked: 445
- Ready: 382
- Partial: 0
- Helper only: 14
- Raw + routed: 0
- Raw only: 49

## String commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `APPEND` | Yes | Yes | Ready | Appends a string to the value of a key. Creates the key if it doesn't exist. |
| `DECR` | Yes | Yes | Ready | Decrements the integer value of a key by one. Uses 0 as initial value if the key doesn't exist. |
| `DECRBY` | Yes | Yes | Ready | Decrements a number from the integer value of a key. Uses 0 as initial value if the key doesn't exist. |
| `DELEX` | Yes | Yes | Ready | Conditionally deletes a string key by value or digest checks. |
| `DIGEST` | Yes | Yes | Ready | Returns the XXH3 digest of a string value. |
| `GET` | Yes | Yes | Ready | Returns the string value of a key. |
| `GETDEL` | Yes | Yes | Ready | Returns the string value of a key after deleting the key. |
| `GETEX` | Yes | Yes | Ready | Returns the string value of a key after setting its expiration time. |
| `GETRANGE` | Yes | Yes | Ready | Returns a substring of the string stored at a key. |
| `GETSET` | Yes | Yes | Ready | Returns the previous string value of a key after setting it to a new value. |
| `INCR` | Yes | Yes | Ready | Increments the integer value of a key by one. Uses 0 as initial value if the key doesn't exist. |
| `INCRBY` | Yes | Yes | Ready | Increments the integer value of a key by a number. Uses 0 as initial value if the key doesn't exist. |
| `INCRBYFLOAT` | Yes | Yes | Ready | Increment the floating point value of a key by a number. Uses 0 as initial value if the key doesn't exist. |
| `LCS` | Yes | Yes | Ready | Finds the longest common substring. |
| `MGET` | Yes | Yes | Ready | Atomically returns the string values of one or more keys. |
| `MSET` | Yes | Yes | Ready | Atomically creates or modifies the string values of one or more keys. |
| `MSETEX` | Yes | Yes | Ready | Atomically sets multiple string keys with a shared expiration in a single operation. |
| `MSETNX` | Yes | Yes | Ready | Atomically modifies the string values of one or more keys only when all keys don't exist. |
| `PSETEX` | Yes | Yes | Ready | Sets both string value and expiration time in milliseconds of a key. The key is created if it doesn't exist. |
| `SET` | Yes | Yes | Ready | Sets the string value of a key, ignoring its type. The key is created if it doesn't exist. |
| `SETEX` | Yes | Yes | Ready | Sets the string value and expiration time of a key. Creates the key if it doesn't exist. |
| `SETNX` | Yes | Yes | Ready | Set the string value of a key only when the key doesn't exist. |
| `SETRANGE` | Yes | Yes | Ready | Overwrites a part of a string value with another by an offset. Creates the key if it doesn't exist. |
| `STRLEN` | Yes | Yes | Ready | Returns the length of a string value. |
| `SUBSTR` | Yes | Yes | Ready | Returns a substring from a string value. |
## Hash commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `HDEL` | Yes | Yes | Ready | Deletes one or more fields and their values from a hash. Deletes the hash if no fields remain. |
| `HEXISTS` | Yes | Yes | Ready | Determines whether a field exists in a hash. |
| `HEXPIRE` | Yes | Yes | Ready | Sets per-field expiration times in seconds. |
| `HEXPIREAT` | Yes | Yes | Ready | Sets per-field absolute expiration times in seconds. |
| `HEXPIRETIME` | Yes | Yes | Ready | Returns per-field absolute expiration timestamps in seconds. |
| `HGET` | Yes | Yes | Ready | Returns the value of a field in a hash. |
| `HGETALL` | Yes | Yes | Ready | Returns all fields and values in a hash. |
| `HGETDEL` | Yes | Yes | Ready | Gets and deletes one or more hash fields. |
| `HGETEX` | Yes | Yes | Ready | Gets hash fields and optionally updates their expiration. |
| `HINCRBY` | Yes | Yes | Ready | Increments the integer value of a field in a hash by a number. Uses 0 as initial value if the field doesn't exist. |
| `HINCRBYFLOAT` | Yes | Yes | Ready | Increments the floating point value of a field by a number. Uses 0 as initial value if the field doesn't exist. |
| `HKEYS` | Yes | Yes | Ready | Returns all fields in a hash. |
| `HLEN` | Yes | Yes | Ready | Returns the number of fields in a hash. |
| `HMGET` | Yes | Yes | Ready | Returns the values of all fields in a hash. |
| `HMSET` | Yes | Yes | Ready | Sets the values of multiple fields. |
| `HPERSIST` | Yes | Yes | Ready | Removes expiration metadata from hash fields. |
| `HPEXPIRE` | Yes | Yes | Ready | Sets per-field expiration times in milliseconds. |
| `HPEXPIREAT` | Yes | Yes | Ready | Sets per-field absolute expiration times in milliseconds. |
| `HPEXPIRETIME` | Yes | Yes | Ready | Returns per-field absolute expiration timestamps in milliseconds. |
| `HPTTL` | Yes | Yes | Ready | Returns per-field remaining TTLs in milliseconds. |
| `HRANDFIELD` | Yes | Yes | Ready | Returns random hash fields, with optional values. |
| `HSCAN` | Yes | Yes | Ready | Iterates over fields and values of a hash. |
| `HSET` | Yes | Yes | Ready | Creates or modifies the value of a field in a hash. |
| `HSETEX` | Yes | Yes | Ready | Sets hash fields and optionally updates their expiration metadata. |
| `HSETNX` | Yes | Yes | Ready | Sets the value of a field in a hash only when the field doesn't exist. |
| `HSTRLEN` | Yes | Yes | Ready | Returns the string length of a hash field value. |
| `HTTL` | Yes | Yes | Ready | Returns per-field remaining TTLs in seconds. |
| `HVALS` | Yes | Yes | Ready | Returns all values in a hash. |
## List commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `BLMOVE` | Yes | Yes | Ready | Pops an element from a list, pushes it to another list and returns it. Blocks until an element is available otherwise. Deletes the list if the last element was moved. |
| `BLMPOP` | Yes | Yes | Ready | Pops the first element from one of multiple lists. Blocks until an element is available otherwise. Deletes the list if the last element was popped. |
| `BLPOP` | Yes | Yes | Ready | Removes and returns the first element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped. |
| `BRPOP` | Yes | Yes | Ready | Removes and returns the last element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped. |
| `BRPOPLPUSH` | Yes | Yes | Ready | Pops an element from a list, pushes it to another list and returns it. Block until an element is available otherwise. Deletes the list if the last element was popped. |
| `LINDEX` | Yes | Yes | Ready | Returns an element from a list by its index. |
| `LINSERT` | Yes | Yes | Ready | Inserts an element before or after another element in a list. |
| `LLEN` | Yes | Yes | Ready | Returns the length of a list. |
| `LMOVE` | Yes | Yes | Ready | Returns an element after popping it from one list and pushing it to another. Deletes the list if the last element was moved. |
| `LMPOP` | Yes | Yes | Ready | Returns multiple elements from a list after removing them. Deletes the list if the last element was popped. |
| `LPOP` | Yes | Yes | Ready | Returns the first elements in a list after removing it. Deletes the list if the last element was popped. |
| `LPOS` | Yes | Yes | Ready | Returns the index of matching elements in a list. |
| `LPUSH` | Yes | Yes | Ready | Prepends one or more elements to a list. Creates the key if it doesn't exist. |
| `LPUSHX` | Yes | Yes | Ready | Prepends one or more elements to a list only when the list exists. |
| `LRANGE` | Yes | Yes | Ready | Returns a range of elements from a list. |
| `LREM` | Yes | Yes | Ready | Removes elements from a list. Deletes the list if the last element was removed. |
| `LSET` | Yes | Yes | Ready | Sets the value of an element in a list by its index. |
| `LTRIM` | Yes | Yes | Ready | Removes elements from both ends a list. Deletes the list if all elements were trimmed. |
| `RPOP` | Yes | Yes | Ready | Returns and removes the last elements of a list. Deletes the list if the last element was popped. |
| `RPOPLPUSH` | Yes | Yes | Ready | Returns the last element of a list after removing and pushing it to another list. Deletes the list if the last element was popped. |
| `RPUSH` | Yes | Yes | Ready | Appends one or more elements to a list. Creates the key if it doesn't exist. |
| `RPUSHX` | Yes | Yes | Ready | Appends one or more elements to a list only when the list exists. |
## Set commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `SADD` | Yes | Yes | Ready | Adds one or more members to a set. Creates the key if it doesn't exist. |
| `SCARD` | Yes | Yes | Ready | Returns the number of members in a set. |
| `SDIFF` | Yes | Yes | Ready | Returns the difference of multiple sets. |
| `SDIFFSTORE` | Yes | Yes | Ready | Stores the difference of multiple sets in a key. |
| `SINTER` | Yes | Yes | Ready | Returns the intersect of multiple sets. |
| `SINTERCARD` | Yes | Yes | Ready | Returns the number of members of the intersect of multiple sets. |
| `SINTERSTORE` | Yes | Yes | Ready | Stores the intersect of multiple sets in a key. |
| `SISMEMBER` | Yes | Yes | Ready | Determines whether a member belongs to a set. |
| `SMEMBERS` | Yes | Yes | Ready | Returns all members of a set. |
| `SMISMEMBER` | Yes | Yes | Ready | Checks membership for multiple set members at once. |
| `SMOVE` | Yes | Yes | Ready | Moves a member from one set to another. |
| `SPOP` | Yes | Yes | Ready | Returns one or more random members from a set after removing them. Deletes the set if the last member was popped. |
| `SRANDMEMBER` | Yes | Yes | Ready | Get one or multiple random members from a set |
| `SREM` | Yes | Yes | Ready | Removes one or more members from a set. Deletes the set if the last member was removed. |
| `SSCAN` | Yes | Yes | Ready | Iterates over members of a set. |
| `SUNION` | Yes | Yes | Ready | Returns the union of multiple sets. |
| `SUNIONSTORE` | Yes | Yes | Ready | Stores the union of multiple sets in a key. |
## Sorted set commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `BZMPOP` | Yes | Yes | Ready | Pops the highest or lowest scoring members from one of multiple sorted sets. Blocks until a member is available otherwise. |
| `BZPOPMAX` | Yes | Yes | Ready | Removes and returns the member with the highest score from one of multiple sorted sets. Blocks until a member is available otherwise. |
| `BZPOPMIN` | Yes | Yes | Ready | Removes and returns the member with the lowest score from one of multiple sorted sets. Blocks until a member is available otherwise. |
| `ZADD` | Yes | Yes | Ready | Adds one or more members to a sorted set, or updates their scores. Creates the key if it doesn't exist. |
| `ZCARD` | Yes | Yes | Ready | Returns the number of members in a sorted set. |
| `ZCOUNT` | Yes | Yes | Ready | Returns the count of members in a sorted set that have scores within a range. |
| `ZDIFF` | Yes | Yes | Ready | Returns the difference between multiple sorted sets. |
| `ZDIFFSTORE` | Yes | Yes | Ready | Stores the difference of multiple sorted sets in a key. |
| `ZINCRBY` | Yes | Yes | Ready | Increments the score of a member in a sorted set. |
| `ZINTER` | Yes | Yes | Ready | Returns the intersect of multiple sorted sets. |
| `ZINTERCARD` | Yes | Yes | Ready | Returns the number of members of the intersect of multiple sorted sets. |
| `ZINTERSTORE` | Yes | Yes | Ready | Stores the intersect of multiple sorted sets in a key. |
| `ZLEXCOUNT` | Yes | Yes | Ready | Returns the number of members in a sorted set within a lexicographical range. |
| `ZMPOP` | Yes | Yes | Ready | Pops the highest or lowest scoring members from one of multiple sorted sets. |
| `ZMSCORE` | Yes | Yes | Ready | Returns the scores associated with the given members in a sorted set. |
| `ZPOPMAX` | Yes | Yes | Ready | Returns the highest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped. |
| `ZPOPMIN` | Yes | Yes | Ready | Returns the lowest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped. |
| `ZRANDMEMBER` | Yes | Yes | Ready | Returns one or more random members from a sorted set. |
| `ZRANGE` | Yes | Yes | Ready | Returns members in a sorted set within a range of indexes. |
| `ZRANGEBYLEX` | Yes | Yes | Ready | Returns members in a sorted set within a lexicographical range. |
| `ZRANGEBYSCORE` | Yes | Yes | Ready | Returns members in a sorted set within a range of scores. |
| `ZRANGESTORE` | Yes | Yes | Ready | Stores a range of members from a sorted set in another key. |
| `ZRANK` | Yes | Yes | Ready | Returns the index of a member in a sorted set ordered by ascending scores. |
| `ZREM` | Yes | Yes | Ready | Removes one or more members from a sorted set. Deletes the sorted set if all members were removed. |
| `ZREMRANGEBYLEX` | Yes | Yes | Ready | Removes members in a sorted set within a lexicographical range. Deletes the sorted set if all members were removed. |
| `ZREMRANGEBYRANK` | Yes | Yes | Ready | Removes members in a sorted set within a range of indexes. Deletes the sorted set if all members were removed. |
| `ZREMRANGEBYSCORE` | Yes | Yes | Ready | Removes members in a sorted set within a range of scores. Deletes the sorted set if all members were removed. |
| `ZREVRANGE` | Yes | Yes | Ready | Returns members in a sorted set within a range of indexes in reverse order. |
| `ZREVRANGEBYLEX` | Yes | Yes | Ready | Returns members in a sorted set within a lexicographical range in reverse order. |
| `ZREVRANGEBYSCORE` | Yes | Yes | Ready | Returns members in a sorted set within a range of scores in reverse order. |
| `ZREVRANK` | Yes | Yes | Ready | Returns the index of a member in a sorted set ordered by descending scores. |
| `ZSCAN` | Yes | Yes | Ready | Iterates over members and scores of a sorted set. |
| `ZSCORE` | Yes | Yes | Ready | Returns the score of a member in a sorted set. |
| `ZUNION` | Yes | Yes | Ready | Returns the union of multiple sorted sets. |
| `ZUNIONSTORE` | Yes | Yes | Ready | Stores the union of multiple sorted sets in a key. |
## Stream commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `XACK` | Yes | Yes | Ready | Returns the number of messages that were successfully acknowledged by the consumer group member of a stream. |
| `XACKDEL` | Yes | Yes | Ready | Acknowledges messages for a consumer group and applies stream deletion reference policies in the same command. |
| `XADD` | Yes | Yes | Ready | Appends a new message to a stream. Creates the key if it doesn't exist. |
| `XAUTOCLAIM` | Yes | Yes | Ready | Changes, or acquires, ownership of messages in a consumer group, as if the messages were delivered to as consumer group member. |
| `XCFGSET` | Yes | Yes | Ready | Configures stream IDMP retention and capacity settings. |
| `XCLAIM` | Yes | Yes | Ready | Changes, or acquires, ownership of a message in a consumer group, as if the message was delivered a consumer group member. |
| `XDEL` | Yes | Yes | Ready | Returns the number of messages after removing them from a stream. |
| `XDELEX` | Yes | Yes | Ready | Deletes stream entries with explicit consumer-reference handling policies. |
| `XGROUP CREATE` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `XGROUP CREATECONSUMER` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `XGROUP DELCONSUMER` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `XGROUP DESTROY` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `XGROUP SETID` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `XINFO CONSUMERS` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `XINFO GROUPS` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `XINFO STREAM` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `XLEN` | Yes | Yes | Ready | Return the number of messages in a stream. |
| `XPENDING` | Yes | Yes | Ready | Returns the information and entries from a stream consumer group's pending entries list. |
| `XRANGE` | Yes | Yes | Ready | Returns the messages from a stream within a range of IDs. |
| `XREAD` | Yes | Yes | Ready | Returns messages from multiple streams with IDs greater than the ones requested. Blocks until a message is available otherwise. |
| `XREADGROUP` | Yes | Yes | Ready | Returns new or historical messages from a stream for a consumer in a group. Blocks until a message is available otherwise. |
| `XREVRANGE` | Yes | Yes | Ready | Returns the messages from a stream within a range of IDs in reverse order. |
| `XSETID` | Yes | Yes | Ready | An internal command for replicating stream values. |
| `XTRIM` | Yes | Yes | Ready | Deletes messages from the beginning of a stream. |
## Bitmap commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `BITCOUNT` | Yes | Yes | Ready | Counts the number of set bits (population counting) in a string. |
| `BITFIELD` | Yes | Yes | Ready | Performs arbitrary bitfield integer operations on strings. |
| `BITFIELD_RO` | Yes | Yes | Ready | Performs arbitrary read-only bitfield integer operations on strings. |
| `BITOP` | Yes | Yes | Ready | Performs bitwise operations on multiple strings, and stores the result. |
| `BITPOS` | Yes | Yes | Ready | Finds the first set (1) or clear (0) bit in a string. |
| `GETBIT` | Yes | Yes | Ready | Returns a bit value by offset. |
| `SETBIT` | Yes | Yes | Ready | Sets or clears the bit at offset of the string value. Creates the key if it doesn't exist. |
## HyperLogLog commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `PFADD` | Yes | Yes | Ready | Adds elements to a HyperLogLog key. Creates the key if it doesn't exist. |
| `PFCOUNT` | Yes | Yes | Ready | Returns the approximated cardinality of the set(s) observed by the HyperLogLog key(s). |
| `PFDEBUG` | No | No | Raw only | Raw only |
| `PFMERGE` | Yes | Yes | Ready | Merges one or more HyperLogLog values into a single key. |
| `PFSELFTEST` | No | No | Raw only | Raw only |
## Geospatial commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `GEOADD` | Yes | Yes | Ready | Adds one or more members to a geospatial index. The key is created if it doesn't exist. |
| `GEODIST` | Yes | Yes | Ready | Returns the distance between two members of a geospatial index. |
| `GEOHASH` | Yes | Yes | Ready | Returns members from a geospatial index as geohash strings. |
| `GEOPOS` | Yes | Yes | Ready | Returns the longitude and latitude of members from a geospatial index. |
| `GEORADIUS` | Yes | Yes | Ready | Queries a geospatial index for members within a distance from a coordinate, optionally stores the result. |
| `GEORADIUSBYMEMBER` | Yes | Yes | Ready | Queries a geospatial index for members within a distance from a member, optionally stores the result. |
| `GEORADIUSBYMEMBER_RO` | Yes | Yes | Ready | Returns members from a geospatial index that are within a distance from a member. |
| `GEORADIUS_RO` | Yes | Yes | Ready | Returns members from a geospatial index that are within a distance from a coordinate. |
| `GEOSEARCH` | Yes | Yes | Ready | Queries a geospatial index for members inside an area of a box or a circle. |
| `GEOSEARCHSTORE` | Yes | Yes | Ready | Queries a geospatial index for members inside an area of a box or a circle, optionally stores the result. |
## JSON commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `JSON.ARRAPPEND` | Yes | Yes | Ready | Appends one or more JSON values to an array path and returns updated lengths. |
| `JSON.ARRINDEX` | Yes | Yes | Ready | Searches a JSON array for a value with optional start and stop bounds. |
| `JSON.ARRINSERT` | Yes | Yes | Ready | Inserts one or more JSON values into an array at the requested index. |
| `JSON.ARRLEN` | Yes | Yes | Ready | Returns JSON array lengths for the requested path. |
| `JSON.ARRPOP` | Yes | Yes | Ready | Pops a JSON array element and returns the serialized value or values. |
| `JSON.ARRTRIM` | Yes | Yes | Ready | Trims a JSON array to the requested inclusive range. |
| `JSON.CLEAR` | Yes | Yes | Ready | Clears containers and resets scalar JSON values where supported. |
| `JSON.DEBUG` | Yes | Yes | Ready | Family-level helper exposed through `jsonDebugMemory(...)`. |
| `JSON.DEBUG MEMORY` | Yes | Yes | Ready | Returns the memory footprint of a JSON value at a key/path. |
| `JSON.DEL` | Yes | Yes | Ready | Deletes JSON values at a path and returns the removal count. |
| `JSON.FORGET` | Yes | Yes | Ready | Alias-style helper for removing JSON values at a path. |
| `JSON.GET` | Yes | Yes | Ready | Gets JSON in serialized form with optional formatting and multi-path support. |
| `JSON.MERGE` | Yes | Yes | Ready | Merges a serialized JSON value into the target key and path. |
| `JSON.MGET` | Yes | Yes | Ready | Gets serialized JSON values for multiple keys at a shared path. |
| `JSON.MSET` | Yes | Yes | Ready | Sets multiple key/path/value triplets in one operation. |
| `JSON.NUMINCRBY` | Yes | Yes | Ready | Increments a numeric JSON value and returns the serialized result. |
| `JSON.NUMMULTBY` | Yes | Yes | Ready | Multiplies a numeric JSON value and returns the serialized result. |
| `JSON.OBJKEYS` | Yes | Yes | Ready | Returns object keys for the requested JSON path. |
| `JSON.OBJLEN` | Yes | Yes | Ready | Returns object field counts for the requested JSON path. |
| `JSON.RESP` | Yes | Yes | Ready | Returns the RESP-normalized structure for the requested JSON value. |
| `JSON.SET` | Yes | Yes | Ready | Sets a serialized JSON value with optional NX/XX semantics. |
| `JSON.STRAPPEND` | Yes | Yes | Ready | Appends to a JSON string value and returns updated lengths. |
| `JSON.STRLEN` | Yes | Yes | Ready | Returns JSON string lengths for the requested path. |
| `JSON.TOGGLE` | Yes | Yes | Ready | Toggles boolean JSON values and returns the updated states. |
| `JSON.TYPE` | Yes | Yes | Ready | Returns JSON type names for the requested path. |
## Search commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `FT.AGGREGATE` | No | No | Raw only | Raw only |
| `FT.ALIASADD` | No | No | Raw only | Raw only |
| `FT.ALIASDEL` | No | No | Raw only | Raw only |
| `FT.ALIASUPDATE` | No | No | Raw only | Raw only |
| `FT.ALTER` | No | No | Raw only | Raw only |
| `FT.CONFIG GET` | No | No | Raw only | Raw only |
| `FT.CONFIG SET` | No | No | Raw only | Raw only |
| `FT.CREATE` | No | No | Raw only | Raw only |
| `FT.CURSOR DEL` | No | No | Raw only | Raw only |
| `FT.CURSOR READ` | No | No | Raw only | Raw only |
| `FT.DICTADD` | No | No | Raw only | Raw only |
| `FT.DICTDEL` | No | No | Raw only | Raw only |
| `FT.DICTDUMP` | No | No | Raw only | Raw only |
| `FT.DROPINDEX` | No | No | Raw only | Raw only |
| `FT.EXPLAIN` | No | No | Raw only | Raw only |
| `FT.EXPLAINCLI` | No | No | Raw only | Raw only |
| `FT.HYBRID` | No | No | Raw only | Raw only |
| `FT.INFO` | No | No | Raw only | Raw only |
| `FT.PROFILE` | No | No | Raw only | Raw only |
| `FT.SEARCH` | No | No | Raw only | Raw only |
| `FT.SPELLCHECK` | No | No | Raw only | Raw only |
| `FT.SYNDUMP` | No | No | Raw only | Raw only |
| `FT.SYNUPDATE` | No | No | Raw only | Raw only |
| `FT.TAGVALS` | No | No | Raw only | Raw only |
| `FT._LIST` | No | No | Raw only | Raw only |
## Time series commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `TS.ADD` | No | No | Raw only | Raw only |
| `TS.ALTER` | No | No | Raw only | Raw only |
| `TS.CREATE` | No | No | Raw only | Raw only |
| `TS.CREATERULE` | No | No | Raw only | Raw only |
| `TS.DECRBY` | No | No | Raw only | Raw only |
| `TS.DEL` | No | No | Raw only | Raw only |
| `TS.DELETERULE` | No | No | Raw only | Raw only |
| `TS.GET` | No | No | Raw only | Raw only |
| `TS.INCRBY` | No | No | Raw only | Raw only |
| `TS.INFO` | No | No | Raw only | Raw only |
| `TS.MADD` | No | No | Raw only | Raw only |
| `TS.MGET` | No | No | Raw only | Raw only |
| `TS.MRANGE` | No | No | Raw only | Raw only |
| `TS.MREVRANGE` | No | No | Raw only | Raw only |
| `TS.QUERYINDEX` | No | No | Raw only | Raw only |
| `TS.RANGE` | No | No | Raw only | Raw only |
| `TS.REVRANGE` | No | No | Raw only | Raw only |
## Vector set commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `VADD` | Yes | Yes | Ready | Adds or updates a vector-set element from `VALUES` or `FP32` input, with optional HNSW tuning and attributes. |
| `VCARD` | Yes | Yes | Ready | Returns the number of elements in a vector set. |
| `VDIM` | Yes | Yes | Ready | Returns the configured vector dimension for a vector set. |
| `VEMB` | Yes | Yes | Ready | Returns a stored embedding and also exposes the `RAW` form through a dedicated helper; the raw blob is currently surfaced as a decoded string because bulk-string replies are not yet binary-safe. |
| `VGETATTR` | Yes | Yes | Ready | Returns the JSON attributes associated with a vector-set element. |
| `VINFO` | Yes | Yes | Ready | Returns vector-set metadata normalized as a map. |
| `VISMEMBER` | Yes | Yes | Ready | Checks whether an element exists in a vector set. |
| `VLINKS` | Yes | Yes | Ready | Returns HNSW graph neighbors per layer, with optional similarity scores. |
| `VRANDMEMBER` | Yes | Yes | Ready | Returns one or more random vector-set elements. |
| `VRANGE` | Yes | Yes | Ready | Returns vector-set elements in lexicographical order over a stateless range window. |
| `VREM` | Yes | Yes | Ready | Removes an element from a vector set. |
| `VSETATTR` | Yes | Yes | Ready | Associates or removes JSON attributes for a vector-set element. |
| `VSIM` | Yes | Yes | Ready | Executes similarity search by element, `VALUES`, or `FP32` query input with typed result decoding. |
## Pub/Sub commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `PSUBSCRIBE` | Yes | No | Helper only | Pub/Sub session only |
| `PUBLISH` | Yes | Yes | Ready | Posts a message to a pub/sub channel and returns the receiver count. |
| `PUBSUB CHANNELS` | Yes | Yes | Ready | Returns the active channels. |
| `PUBSUB NUMPAT` | Yes | Yes | Ready | Returns a count of unique pattern subscriptions. |
| `PUBSUB NUMSUB` | Yes | Yes | Ready | Returns a count of subscribers to channels. |
| `PUBSUB SHARDCHANNELS` | Yes | Yes | Ready | Returns the active shard channels. |
| `PUBSUB SHARDNUMSUB` | Yes | Yes | Ready | Returns the count of subscribers of shard channels. |
| `PUNSUBSCRIBE` | Yes | No | Helper only | Pub/Sub session only |
| `SPUBLISH` | Yes | Yes | Ready | Posts a message to a shard pub/sub channel and returns the receiver count. |
| `SSUBSCRIBE` | Yes | No | Helper only | Pub/Sub session only |
| `SUBSCRIBE` | Yes | No | Helper only | Pub/Sub session only |
| `SUNSUBSCRIBE` | Yes | No | Helper only | Pub/Sub session only |
| `UNSUBSCRIBE` | Yes | No | Helper only | Pub/Sub session only |
## Transaction commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `DISCARD` | Yes | No | Helper only | Transaction session only |
| `EXEC` | Yes | No | Helper only | Transaction session only |
| `MULTI` | Yes | No | Helper only | Transaction session only |
| `UNWATCH` | Yes | No | Helper only | Transaction session only |
| `WATCH` | Yes | No | Helper only | Transaction session only |
## Scripting commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `EVAL` | Yes | Yes | Ready | Executes a server-side Lua script. |
| `EVALSHA` | Yes | Yes | Ready | Executes a server-side Lua script by SHA1 digest. |
| `EVALSHA_RO` | Yes | Yes | Ready | Executes a read-only server-side Lua script by SHA1 digest. |
| `EVAL_RO` | Yes | Yes | Ready | Executes a read-only server-side Lua script. |
| `FCALL` | Yes | Yes | Ready | Calls a function. |
| `FCALL_RO` | Yes | Yes | Ready | Calls a read-only function. |
| `FUNCTION DELETE` | Yes | Yes | Ready | Deletes a library and its functions. |
| `FUNCTION DUMP` | Yes | Yes | Ready | Dumps all libraries into a serialized binary payload. |
| `FUNCTION FLUSH` | Yes | Yes | Ready | Deletes all libraries and functions. |
| `FUNCTION KILL` | Yes | Yes | Ready | Terminates a function during execution. |
| `FUNCTION LIST` | Yes | Yes | Ready | Returns information about all libraries. |
| `FUNCTION LOAD` | Yes | Yes | Ready | Creates a library. |
| `FUNCTION RESTORE` | Yes | Yes | Ready | Restores all libraries from a payload. |
| `FUNCTION STATS` | Yes | Yes | Ready | Returns information about a function during execution. |
| `SCRIPT DEBUG` | Yes | Yes | Ready | Sets the debug mode of server-side Lua scripts. |
| `SCRIPT EXISTS` | Yes | Yes | Ready | Determines whether server-side Lua scripts exist in the script cache. |
| `SCRIPT FLUSH` | Yes | Yes | Ready | Removes all server-side Lua scripts from the script cache. |
| `SCRIPT KILL` | Yes | Yes | Ready | Terminates a server-side Lua script during execution. |
| `SCRIPT LOAD` | Yes | Yes | Ready | Loads a server-side Lua script to the script cache. |
## Connection commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `AUTH` | Yes | Yes | Ready | Authenticates the connection. |
| `CLIENT CACHING` | Yes | Yes | Ready | Instructs the server whether to track the keys in the next request. |
| `CLIENT GETNAME` | Yes | Yes | Ready | Returns the name of the connection. |
| `CLIENT GETREDIR` | Yes | Yes | Ready | Returns the client ID to which the connection's tracking notifications are redirected. |
| `CLIENT ID` | Yes | Yes | Ready | Returns the unique client ID of the connection. |
| `CLIENT INFO` | Yes | Yes | Ready | Returns information about the connection. |
| `CLIENT KILL` | Yes | Yes | Ready | Terminates open connections. |
| `CLIENT LIST` | Yes | Yes | Ready | Lists open connections. |
| `CLIENT NO-EVICT` | Yes | Yes | Ready | Sets the client eviction mode of the connection. |
| `CLIENT NO-TOUCH` | Yes | Yes | Ready | Controls whether commands sent by the client affect the LRU/LFU of accessed keys. |
| `CLIENT PAUSE` | Yes | Yes | Ready | Suspends commands processing. |
| `CLIENT REPLY` | Yes | Yes | Ready | Instructs the server whether to reply to commands. |
| `CLIENT SETINFO` | Yes | Yes | Ready | Sets information specific to the client or connection. |
| `CLIENT SETNAME` | Yes | Yes | Ready | Sets the connection name. |
| `CLIENT TRACKING` | Yes | Yes | Ready | Controls server-assisted client-side caching for the connection. |
| `CLIENT TRACKINGINFO` | Yes | Yes | Ready | Returns information about server-assisted client-side caching for the connection. |
| `CLIENT UNBLOCK` | Yes | Yes | Ready | Unblocks a client blocked by a blocking command from a different connection. |
| `CLIENT UNPAUSE` | Yes | Yes | Ready | Resumes processing commands from paused clients. |
| `ECHO` | Yes | Yes | Ready | Returns the given string. |
| `HELLO` | Yes | Yes | Ready | Handshakes with the Redis server. |
| `PING` | Yes | Yes | Ready | Returns the server's liveliness response. |
| `QUIT` | No | No | Raw only | Raw only |
| `RESET` | No | No | Raw only | Raw only |
| `SELECT` | No | No | Raw only | Raw only |
## Server commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `ACL CAT` | Yes | Yes | Ready | Lists ACL categories or the commands inside one category. |
| `ACL DELUSER` | Yes | Yes | Ready | Admin-only helper. Deletes ACL users, and terminates their connections. |
| `ACL DRYRUN` | Yes | Yes | Ready | Simulates whether a user may execute a command. |
| `ACL GENPASS` | Yes | Yes | Ready | Generates a pseudorandom, secure password that can be used to identify ACL users. |
| `ACL GETUSER` | Yes | Yes | Ready | Lists the ACL rules of a user. |
| `ACL LIST` | Yes | Yes | Ready | Dumps the effective rules in ACL file format. |
| `ACL LOAD` | Yes | Yes | Ready | Admin-only helper. Reloads ACL rules from the ACL file. |
| `ACL LOG` | Yes | Yes | Ready | Lists recent security events generated due to ACL rules. |
| `ACL SAVE` | Yes | Yes | Ready | Admin-only helper. Saves ACL rules to the ACL file. |
| `ACL SETUSER` | Yes | Yes | Ready | Admin-only helper. Creates and modifies an ACL user and its rules. |
| `ACL USERS` | Yes | Yes | Ready | Lists all ACL users. |
| `ACL WHOAMI` | Yes | Yes | Ready | Returns the authenticated username of the current connection. |
| `BGREWRITEAOF` | Yes | Yes | Ready | Admin-only helper. Starts an append-only file rewrite in the background. |
| `BGSAVE` | Yes | Yes | Ready | Admin-only helper. Starts a background save, with optional scheduling when an AOF rewrite is active. |
| `COMMAND` | Yes | Yes | Ready | Returns detailed information about all commands. |
| `COMMAND COUNT` | Yes | Yes | Ready | Returns a count of commands. |
| `COMMAND DOCS` | Yes | Yes | Ready | Returns documentary information about one, multiple or all commands. |
| `COMMAND GETKEYS` | Yes | Yes | Ready | Extracts the key names from an arbitrary command. |
| `COMMAND GETKEYSANDFLAGS` | Yes | Yes | Ready | Extracts the key names and access flags for an arbitrary command. |
| `COMMAND INFO` | Yes | Yes | Ready | Returns information about one, multiple or all commands. |
| `COMMAND LIST` | Yes | Yes | Ready | Returns a list of command names. |
| `CONFIG GET` | Yes | Yes | Ready | Returns the effective values of configuration parameters. |
| `CONFIG RESETSTAT` | Yes | Yes | Ready | Resets the server's statistics. |
| `CONFIG REWRITE` | Yes | Yes | Ready | Admin-only helper. Persists the effective configuration to file. |
| `CONFIG SET` | Yes | Yes | Ready | Admin-only helper. Sets configuration parameters in-flight. |
| `DBSIZE` | Yes | Yes | Ready | Returns the number of keys in the database. |
| `FAILOVER` | Yes | Yes | Ready | Admin-only helper. Starts a coordinated failover with typed target, timeout, force, and abort options. |
| `FLUSHALL` | Yes | Yes | Ready | Admin-only helper. Removes all keys from all databases. |
| `FLUSHDB` | Yes | Yes | Ready | Admin-only helper. Remove all keys from the current database. |
| `HOTKEYS` | Yes | Yes | Ready | Admin-only helper family with explicit subcommand wrappers for tracking hot keys. |
| `HOTKEYS GET` | Yes | Yes | Ready | Admin-only helper. Returns normalized hot key tracking results as a map, or null when no session exists. |
| `HOTKEYS RESET` | Yes | Yes | Ready | Admin-only helper. Releases the resources used for hot key tracking. |
| `HOTKEYS START` | Yes | Yes | Ready | Admin-only helper. Starts hot key tracking with explicit metric, duration, sampling, and slot options. |
| `HOTKEYS STOP` | Yes | Yes | Ready | Admin-only helper. Stops hot key tracking while preserving collected results. |
| `INFO` | Yes | Yes | Ready | Returns information and statistics about the server. |
| `LASTSAVE` | Yes | Yes | Ready | Returns the Unix timestamp of the last successful persistence save. |
| `LATENCY DOCTOR` | Yes | Family | Ready | Returns a human-readable latency analysis report. |
| `LATENCY GRAPH` | Yes | Family | Ready | Returns an ASCII latency graph for an event. |
| `LATENCY HISTOGRAM` | Yes | Family | Ready | Returns per-command latency histograms as normalized maps. |
| `LATENCY HISTORY` | Yes | Family | Ready | Returns timestamp-latency samples for an event. |
| `LATENCY LATEST` | Yes | Family | Ready | Returns the latest latency samples for all events. |
| `LATENCY RESET` | Yes | Family | Ready | Resets latency samples for one or more events. |
| `LOLWUT` | Yes | Yes | Ready | Admin-only helper. Returns the generated LOLWUT output with optional version-specific arguments. |
| `MEMORY DOCTOR` | Yes | Yes | Ready | Outputs a memory problems report. |
| `MEMORY MALLOC-STATS` | Yes | Yes | Ready | Returns allocator statistics as a raw report string. |
| `MEMORY PURGE` | Yes | Yes | Ready | Asks the allocator to release memory. |
| `MEMORY STATS` | Yes | Yes | Ready | Returns details about memory usage. |
| `MEMORY USAGE` | Yes | Yes | Ready | Estimates the memory usage of a key. |
| `MODULE LIST` | Yes | Family | Ready | Returns the loaded modules as normalized maps. |
| `MODULE LOAD` | Yes | Family | Ready | Admin-only helper. Loads a module from a shared library path. |
| `MODULE LOADEX` | Yes | Family | Ready | Admin-only helper. Loads a module with CONFIG and ARGS sections. |
| `MODULE UNLOAD` | Yes | Family | Ready | Admin-only helper. Unloads a module by name. |
| `MONITOR` | Yes | Yes | Ready | Dedicated monitor session with a streaming message API. |
| `PSYNC` | Yes | Yes | Ready | Admin-only helper. Low-level replication helper for issuing a PSYNC handshake on a dedicated connection. |
| `REPLCONF` | Yes | Yes | Ready | Admin-only helper. Low-level replication helper with typed wrappers for common REPLCONF forms. |
| `REPLICAOF` | Yes | Yes | Ready | Admin-only helper. Configures a server as replica of another, or promotes it to a master. |
| `RESTORE-ASKING` | Yes | Yes | Ready | Restores a serialized key on an importing cluster node. |
| `ROLE` | Yes | Yes | Ready | Returns the replication role. |
| `SAVE` | Yes | Yes | Ready | Admin-only helper. Performs a synchronous database save. |
| `SHUTDOWN` | Yes | Yes | Ready | Admin-only helper. Builds validated shutdown flag combinations and returns OK for abort flows. |
| `SLAVEOF` | Yes | Yes | Ready | Admin-only helper. Deprecated alias of REPLICAOF. |
| `SLOWLOG GET` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `SLOWLOG LEN` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `SLOWLOG RESET` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `SWAPDB` | Yes | Yes | Ready | Admin-only helper. Swaps two logical Redis databases. |
| `SYNC` | Yes | Yes | Ready | Admin-only helper. Low-level replication helper for issuing SYNC on a dedicated connection. |
| `TIME` | Yes | Yes | Ready | Returns the server time. |
## Cluster commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `ASKING` | Yes | Yes | Ready | Enables an importing cluster node to accept the next command. |
| `CLUSTER ADDSLOTS` | Yes | Yes | Ready | Assigns new hash slots to a node. |
| `CLUSTER ADDSLOTSRANGE` | Yes | Yes | Ready | Assigns one or more slot ranges to a node. |
| `CLUSTER BUMPEPOCH` | Yes | Yes | Ready | Advances the cluster config epoch. |
| `CLUSTER COUNT-FAILURE-REPORTS` | Yes | Yes | Ready | Returns the number of failure reports for a node. |
| `CLUSTER COUNTKEYSINSLOT` | Yes | Yes | Ready | Returns the number of keys in a hash slot. |
| `CLUSTER DELSLOTS` | Yes | Yes | Ready | Sets hash slots as unbound for a node. |
| `CLUSTER DELSLOTSRANGE` | Yes | Yes | Ready | Removes one or more slot ranges from a node. |
| `CLUSTER FAILOVER` | Yes | Yes | Ready | Forces a replica to perform a manual failover. |
| `CLUSTER FLUSHSLOTS` | Yes | Yes | Ready | Removes all slot assignments from a node. |
| `CLUSTER FORGET` | Yes | Yes | Ready | Removes a node from the nodes table. |
| `CLUSTER GETKEYSINSLOT` | Yes | Yes | Ready | Returns the key names in a hash slot. |
| `CLUSTER INFO` | Yes | Yes | Ready | Returns information about the state of a node. |
| `CLUSTER KEYSLOT` | Yes | Yes | Ready | Returns the hash slot for a key. |
| `CLUSTER LINKS` | Yes | Yes | Ready | Returns normalized maps describing all cluster TCP links. |
| `CLUSTER MEET` | Yes | Yes | Ready | Forces a node to handshake with another node. |
| `CLUSTER MIGRATION` | Yes | Yes | Ready | Starts, inspects, and cancels migration tasks through explicit subcommand helpers. |
| `CLUSTER MYID` | Yes | Yes | Ready | Returns the ID of a node. |
| `CLUSTER MYSHARDID` | Yes | Yes | Ready | Returns the shard ID of the current node. |
| `CLUSTER NODES` | Yes | Yes | Ready | Returns the cluster configuration for a node. |
| `CLUSTER REPLICAS` | Yes | Yes | Ready | Lists the replica nodes of a master node. |
| `CLUSTER REPLICATE` | Yes | Yes | Ready | Configure a node as replica of a master node. |
| `CLUSTER RESET` | Yes | Yes | Ready | Resets a node. |
| `CLUSTER SAVECONFIG` | Yes | Yes | Ready | Forces the node to persist the cluster configuration. |
| `CLUSTER SET-CONFIG-EPOCH` | Yes | Yes | Ready | Sets the local config epoch on a node. |
| `CLUSTER SETSLOT` | Yes | Yes | Ready | Changes the owner or transition state of a slot. |
| `CLUSTER SHARDS` | Yes | Yes | Ready | Returns normalized shard descriptions and slot ranges. |
| `CLUSTER SLAVES` | Yes | Yes | Ready | Deprecated alias of CLUSTER REPLICAS. |
| `CLUSTER SLOT-STATS` | Yes | Yes | Ready | Returns normalized slot statistics for range and order-by queries. |
| `CLUSTER SLOTS` | Yes | Yes | Ready | Returns the mapping of cluster slots to nodes. |
| `READONLY` | Yes | Yes | Ready | Enables read-only queries for a connection to a Redis Cluster replica node. |
| `READWRITE` | Yes | Yes | Ready | Enables read-write queries for a connection to a Reids Cluster replica node. |
## Generic commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `COPY` | Yes | Yes | Ready | Copies the value of a key to a new key. |
| `DEL` | Yes | Yes | Ready | Deletes one or more keys. |
| `DUMP` | Yes | Yes | Ready | Returns a serialized representation of the value stored at a key. |
| `EXISTS` | Yes | Yes | Ready | Determines whether one or more keys exist. |
| `EXPIRE` | Yes | Yes | Ready | Sets the expiration time of a key in seconds. |
| `EXPIREAT` | Yes | Yes | Ready | Sets the expiration time of a key to a Unix timestamp. |
| `EXPIRETIME` | Yes | Yes | Ready | Returns the expiration time of a key as a Unix timestamp. |
| `KEYS` | Yes | No | Helper only | Typed helper without dedicated cluster spec |
| `MIGRATE` | Yes | Yes | Ready | Atomically transfers one or more keys to another Redis instance. |
| `MOVE` | Yes | Yes | Ready | Moves a key to another database. |
| `OBJECT ENCODING` | Yes | Yes | Ready | Returns the internal encoding of a Redis object. |
| `OBJECT FREQ` | Yes | Yes | Ready | Returns the logarithmic access frequency counter of a Redis object. |
| `OBJECT IDLETIME` | Yes | Yes | Ready | Returns the time since the last access to a Redis object. |
| `OBJECT REFCOUNT` | Yes | Yes | Ready | Returns the reference count of a value of a key. |
| `PERSIST` | Yes | Yes | Ready | Removes the expiration time of a key. |
| `PEXPIRE` | Yes | Yes | Ready | Sets the expiration time of a key in milliseconds. |
| `PEXPIREAT` | Yes | Yes | Ready | Sets the expiration time of a key to a Unix milliseconds timestamp. |
| `PEXPIRETIME` | Yes | Yes | Ready | Returns the expiration time of a key as a Unix milliseconds timestamp. |
| `PTTL` | Yes | Yes | Ready | Returns the expiration time in milliseconds of a key. |
| `RANDOMKEY` | Yes | No | Helper only | Typed helper without dedicated cluster spec |
| `RENAME` | Yes | Yes | Ready | Renames a key and overwrites the destination. |
| `RENAMENX` | Yes | Yes | Ready | Renames a key only when the target key name doesn't exist. |
| `RESTORE` | Yes | Yes | Ready | Creates a key from the serialized representation of a value. |
| `SCAN` | Yes | No | Helper only | Typed helper without dedicated cluster spec |
| `SORT` | Yes | Yes | Ready | Sorts the elements in a list, set, or sorted set, optionally storing the result. |
| `SORT_RO` | Yes | Yes | Ready | Returns the sorted elements of a list, set, or sorted set. |
| `TOUCH` | Yes | Yes | Ready | Returns the number of existing keys out of those specified after updating the time they were last accessed. |
| `TTL` | Yes | Yes | Ready | Returns the expiration time in seconds of a key. |
| `TYPE` | Yes | Yes | Ready | Determines the type of value stored at a key. |
| `UNLINK` | Yes | Yes | Ready | Asynchronously deletes one or more keys. |
| `WAIT` | No | No | Raw only | Raw only |
| `WAITAOF` | No | No | Raw only | Raw only |

## Maintenance

- Update this file whenever a new typed helper or cluster routing spec is added.
- Re-run the Redis command reference comparison when Redis command pages change.
- Prefer adding `ClusterCommandSpec` coverage together with any new keyed helper.
