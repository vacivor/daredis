# Command Adaptation Progress

Generated against the official Redis 8.6 command reference on 2026-03-25.

Source: https://redis.io/docs/latest/commands/redis-8-6-commands/

## Legend

- `Helper`: `Yes` means a typed helper appears to exist; `Family` means support exists at the command-family level but may not be exposed as a dedicated helper for that exact command; `No` means raw `sendCommand()` only.
- `Cluster`: `Yes` means `ClusterCommandSpec` has direct support; `Family` means routing is handled by a family-level parser or no-key family rule; `No` means no dedicated local routing support.
- `Status`: a compact summary derived from `Helper` and `Cluster`.

## Summary

- Total commands tracked: 445
- Ready: 244
- Partial: 22
- Helper only: 14
- Raw + routed: 40
- Raw only: 125

## String commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `APPEND` | Yes | Yes | Ready | Appends a string to the value of a key. Creates the key if it doesn't exist. |
| `DECR` | Yes | Yes | Ready | Decrements the integer value of a key by one. Uses 0 as initial value if the key doesn't exist. |
| `DECRBY` | Yes | Yes | Ready | Decrements a number from the integer value of a key. Uses 0 as initial value if the key doesn't exist. |
| `DELEX` | No | No | Raw only | Raw only |
| `DIGEST` | No | No | Raw only | Raw only |
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
| `HEXPIRE` | No | No | Raw only | Raw only |
| `HEXPIREAT` | No | No | Raw only | Raw only |
| `HEXPIRETIME` | No | No | Raw only | Raw only |
| `HGET` | Yes | Yes | Ready | Returns the value of a field in a hash. |
| `HGETALL` | Yes | Yes | Ready | Returns all fields and values in a hash. |
| `HGETDEL` | No | No | Raw only | Raw only |
| `HGETEX` | No | No | Raw only | Raw only |
| `HINCRBY` | Yes | Yes | Ready | Increments the integer value of a field in a hash by a number. Uses 0 as initial value if the field doesn't exist. |
| `HINCRBYFLOAT` | Yes | Yes | Ready | Increments the floating point value of a field by a number. Uses 0 as initial value if the field doesn't exist. |
| `HKEYS` | Yes | Yes | Ready | Returns all fields in a hash. |
| `HLEN` | Yes | Yes | Ready | Returns the number of fields in a hash. |
| `HMGET` | Yes | Yes | Ready | Returns the values of all fields in a hash. |
| `HMSET` | Yes | Yes | Ready | Sets the values of multiple fields. |
| `HPERSIST` | No | No | Raw only | Raw only |
| `HPEXPIRE` | No | No | Raw only | Raw only |
| `HPEXPIREAT` | No | No | Raw only | Raw only |
| `HPEXPIRETIME` | No | No | Raw only | Raw only |
| `HPTTL` | No | No | Raw only | Raw only |
| `HRANDFIELD` | No | No | Raw only | Raw only |
| `HSCAN` | Yes | Yes | Ready | Iterates over fields and values of a hash. |
| `HSET` | Yes | Yes | Ready | Creates or modifies the value of a field in a hash. |
| `HSETEX` | No | No | Raw only | Raw only |
| `HSETNX` | Yes | Yes | Ready | Sets the value of a field in a hash only when the field doesn't exist. |
| `HSTRLEN` | No | No | Raw only | Raw only |
| `HTTL` | No | No | Raw only | Raw only |
| `HVALS` | Yes | Yes | Ready | Returns all values in a hash. |
## List commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `BLMOVE` | Yes | Yes | Ready | Pops an element from a list, pushes it to another list and returns it. Blocks until an element is available otherwise. Deletes the list if the last element was moved. |
| `BLMPOP` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `BLPOP` | Yes | Yes | Ready | Removes and returns the first element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped. |
| `BRPOP` | Yes | Yes | Ready | Removes and returns the last element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped. |
| `BRPOPLPUSH` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `LINDEX` | Yes | Yes | Ready | Returns an element from a list by its index. |
| `LINSERT` | Yes | Yes | Ready | Inserts an element before or after another element in a list. |
| `LLEN` | Yes | Yes | Ready | Returns the length of a list. |
| `LMOVE` | Yes | Yes | Ready | Returns an element after popping it from one list and pushing it to another. Deletes the list if the last element was moved. |
| `LMPOP` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `LPOP` | Yes | Yes | Ready | Returns the first elements in a list after removing it. Deletes the list if the last element was popped. |
| `LPOS` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `LPUSH` | Yes | Yes | Ready | Prepends one or more elements to a list. Creates the key if it doesn't exist. |
| `LPUSHX` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `LRANGE` | Yes | Yes | Ready | Returns a range of elements from a list. |
| `LREM` | Yes | Yes | Ready | Removes elements from a list. Deletes the list if the last element was removed. |
| `LSET` | Yes | Yes | Ready | Sets the value of an element in a list by its index. |
| `LTRIM` | Yes | Yes | Ready | Removes elements from both ends a list. Deletes the list if all elements were trimmed. |
| `RPOP` | Yes | Yes | Ready | Returns and removes the last elements of a list. Deletes the list if the last element was popped. |
| `RPOPLPUSH` | Yes | Yes | Ready | Returns the last element of a list after removing and pushing it to another list. Deletes the list if the last element was popped. |
| `RPUSH` | Yes | Yes | Ready | Appends one or more elements to a list. Creates the key if it doesn't exist. |
| `RPUSHX` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
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
| `SMISMEMBER` | No | No | Raw only | Raw only |
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
| `BZMPOP` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `BZPOPMAX` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `BZPOPMIN` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `ZADD` | Yes | Yes | Ready | Adds one or more members to a sorted set, or updates their scores. Creates the key if it doesn't exist. |
| `ZCARD` | Yes | Yes | Ready | Returns the number of members in a sorted set. |
| `ZCOUNT` | Yes | Yes | Ready | Returns the count of members in a sorted set that have scores within a range. |
| `ZDIFF` | Yes | Yes | Ready | Returns the difference between multiple sorted sets. |
| `ZDIFFSTORE` | Yes | Yes | Ready | Stores the difference of multiple sorted sets in a key. |
| `ZINCRBY` | Yes | Yes | Ready | Increments the score of a member in a sorted set. |
| `ZINTER` | Yes | Yes | Ready | Returns the intersect of multiple sorted sets. |
| `ZINTERCARD` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `ZINTERSTORE` | Yes | Yes | Ready | Stores the intersect of multiple sorted sets in a key. |
| `ZLEXCOUNT` | Yes | Yes | Ready | Returns the number of members in a sorted set within a lexicographical range. |
| `ZMPOP` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `ZMSCORE` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `ZPOPMAX` | Yes | Yes | Ready | Returns the highest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped. |
| `ZPOPMIN` | Yes | Yes | Ready | Returns the lowest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped. |
| `ZRANDMEMBER` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `ZRANGE` | Yes | Yes | Ready | Returns members in a sorted set within a range of indexes. |
| `ZRANGEBYLEX` | Yes | Yes | Ready | Returns members in a sorted set within a lexicographical range. |
| `ZRANGEBYSCORE` | Yes | Yes | Ready | Returns members in a sorted set within a range of scores. |
| `ZRANGESTORE` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `ZRANK` | Yes | Yes | Ready | Returns the index of a member in a sorted set ordered by ascending scores. |
| `ZREM` | Yes | Yes | Ready | Removes one or more members from a sorted set. Deletes the sorted set if all members were removed. |
| `ZREMRANGEBYLEX` | Yes | Yes | Ready | Removes members in a sorted set within a lexicographical range. Deletes the sorted set if all members were removed. |
| `ZREMRANGEBYRANK` | Yes | Yes | Ready | Removes members in a sorted set within a range of indexes. Deletes the sorted set if all members were removed. |
| `ZREMRANGEBYSCORE` | Yes | Yes | Ready | Removes members in a sorted set within a range of scores. Deletes the sorted set if all members were removed. |
| `ZREVRANGE` | Yes | Yes | Ready | Returns members in a sorted set within a range of indexes in reverse order. |
| `ZREVRANGEBYLEX` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `ZREVRANGEBYSCORE` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `ZREVRANK` | Yes | Yes | Ready | Returns the index of a member in a sorted set ordered by descending scores. |
| `ZSCAN` | Yes | Yes | Ready | Iterates over members and scores of a sorted set. |
| `ZSCORE` | Yes | Yes | Ready | Returns the score of a member in a sorted set. |
| `ZUNION` | Yes | Yes | Ready | Returns the union of multiple sorted sets. |
| `ZUNIONSTORE` | Yes | Yes | Ready | Stores the union of multiple sorted sets in a key. |
## Stream commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `XACK` | Yes | Yes | Ready | Returns the number of messages that were successfully acknowledged by the consumer group member of a stream. |
| `XACKDEL` | No | No | Raw only | Raw only |
| `XADD` | Yes | Yes | Ready | Appends a new message to a stream. Creates the key if it doesn't exist. |
| `XAUTOCLAIM` | Yes | Yes | Ready | Changes, or acquires, ownership of messages in a consumer group, as if the messages were delivered to as consumer group member. |
| `XCFGSET` | No | No | Raw only | Raw only |
| `XCLAIM` | Yes | Yes | Ready | Changes, or acquires, ownership of a message in a consumer group, as if the message was delivered a consumer group member. |
| `XDEL` | Yes | Yes | Ready | Returns the number of messages after removing them from a stream. |
| `XDELEX` | No | No | Raw only | Raw only |
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
| `XSETID` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
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
| `JSON.ARRAPPEND` | No | No | Raw only | Raw only |
| `JSON.ARRINDEX` | No | No | Raw only | Raw only |
| `JSON.ARRINSERT` | No | No | Raw only | Raw only |
| `JSON.ARRLEN` | No | No | Raw only | Raw only |
| `JSON.ARRPOP` | No | No | Raw only | Raw only |
| `JSON.ARRTRIM` | No | No | Raw only | Raw only |
| `JSON.CLEAR` | No | No | Raw only | Raw only |
| `JSON.DEBUG` | No | No | Raw only | Raw only |
| `JSON.DEBUG MEMORY` | No | No | Raw only | Raw only |
| `JSON.DEL` | No | No | Raw only | Raw only |
| `JSON.FORGET` | No | No | Raw only | Raw only |
| `JSON.GET` | No | No | Raw only | Raw only |
| `JSON.MERGE` | No | No | Raw only | Raw only |
| `JSON.MGET` | No | No | Raw only | Raw only |
| `JSON.MSET` | No | No | Raw only | Raw only |
| `JSON.NUMINCRBY` | No | No | Raw only | Raw only |
| `JSON.NUMMULTBY` | No | No | Raw only | Raw only |
| `JSON.OBJKEYS` | No | No | Raw only | Raw only |
| `JSON.OBJLEN` | No | No | Raw only | Raw only |
| `JSON.RESP` | No | No | Raw only | Raw only |
| `JSON.SET` | No | No | Raw only | Raw only |
| `JSON.STRAPPEND` | No | No | Raw only | Raw only |
| `JSON.STRLEN` | No | No | Raw only | Raw only |
| `JSON.TOGGLE` | No | No | Raw only | Raw only |
| `JSON.TYPE` | No | No | Raw only | Raw only |
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
| `VADD` | No | No | Raw only | Raw only |
| `VCARD` | No | No | Raw only | Raw only |
| `VDIM` | No | No | Raw only | Raw only |
| `VEMB` | No | No | Raw only | Raw only |
| `VGETATTR` | No | No | Raw only | Raw only |
| `VINFO` | No | No | Raw only | Raw only |
| `VISMEMBER` | No | No | Raw only | Raw only |
| `VLINKS` | No | No | Raw only | Raw only |
| `VRANDMEMBER` | No | No | Raw only | Raw only |
| `VRANGE` | No | No | Raw only | Raw only |
| `VREM` | No | No | Raw only | Raw only |
| `VSETATTR` | No | No | Raw only | Raw only |
| `VSIM` | No | No | Raw only | Raw only |
## Pub/Sub commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `PSUBSCRIBE` | Yes | No | Helper only | Pub/Sub session only |
| `PUBLISH` | No | No | Raw only | Raw only |
| `PUBSUB CHANNELS` | Yes | Yes | Ready | Returns the active channels. |
| `PUBSUB NUMPAT` | Yes | Yes | Ready | Returns a count of unique pattern subscriptions. |
| `PUBSUB NUMSUB` | Yes | Yes | Ready | Returns a count of subscribers to channels. |
| `PUBSUB SHARDCHANNELS` | Yes | Yes | Ready | Returns the active shard channels. |
| `PUBSUB SHARDNUMSUB` | Yes | Yes | Ready | Returns the count of subscribers of shard channels. |
| `PUNSUBSCRIBE` | Yes | No | Helper only | Pub/Sub session only |
| `SPUBLISH` | No | No | Raw only | Raw only |
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
| `FCALL` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `FCALL_RO` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
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
| `AUTH` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
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
| `HELLO` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `PING` | Yes | Yes | Ready | Returns the server's liveliness response. |
| `QUIT` | No | No | Raw only | Raw only |
| `RESET` | No | No | Raw only | Raw only |
| `SELECT` | No | No | Raw only | Raw only |
## Server commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `ACL CAT` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `ACL DELUSER` | Yes | Yes | Ready | Deletes ACL users, and terminates their connections. |
| `ACL DRYRUN` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `ACL GENPASS` | Yes | Yes | Ready | Generates a pseudorandom, secure password that can be used to identify ACL users. |
| `ACL GETUSER` | Yes | Yes | Ready | Lists the ACL rules of a user. |
| `ACL LIST` | Yes | Yes | Ready | Dumps the effective rules in ACL file format. |
| `ACL LOAD` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `ACL LOG` | Yes | Yes | Ready | Lists recent security events generated due to ACL rules. |
| `ACL SAVE` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `ACL SETUSER` | Yes | Yes | Ready | Creates and modifies an ACL user and its rules. |
| `ACL USERS` | Yes | Yes | Ready | Lists all ACL users. |
| `ACL WHOAMI` | Yes | Yes | Ready | Returns the authenticated username of the current connection. |
| `BGREWRITEAOF` | No | No | Raw only | Raw only |
| `BGSAVE` | No | No | Raw only | Raw only |
| `COMMAND` | Yes | Yes | Ready | Returns detailed information about all commands. |
| `COMMAND COUNT` | Yes | Yes | Ready | Returns a count of commands. |
| `COMMAND DOCS` | Yes | Yes | Ready | Returns documentary information about one, multiple or all commands. |
| `COMMAND GETKEYS` | Yes | Yes | Ready | Extracts the key names from an arbitrary command. |
| `COMMAND GETKEYSANDFLAGS` | Yes | Yes | Ready | Extracts the key names and access flags for an arbitrary command. |
| `COMMAND INFO` | Yes | Yes | Ready | Returns information about one, multiple or all commands. |
| `COMMAND LIST` | Yes | Yes | Ready | Returns a list of command names. |
| `CONFIG GET` | Yes | Yes | Ready | Returns the effective values of configuration parameters. |
| `CONFIG RESETSTAT` | Yes | Yes | Ready | Resets the server's statistics. |
| `CONFIG REWRITE` | Yes | Yes | Ready | Persists the effective configuration to file. |
| `CONFIG SET` | Yes | Yes | Ready | Sets configuration parameters in-flight. |
| `DBSIZE` | Yes | Yes | Ready | Returns the number of keys in the database. |
| `FAILOVER` | No | No | Raw only | Raw only |
| `FLUSHALL` | Yes | Yes | Ready | Removes all keys from all databases. |
| `FLUSHDB` | Yes | Yes | Ready | Remove all keys from the current database. |
| `HOTKEYS` | No | No | Raw only | Raw only |
| `HOTKEYS GET` | No | No | Raw only | Raw only |
| `HOTKEYS RESET` | No | No | Raw only | Raw only |
| `HOTKEYS START` | No | No | Raw only | Raw only |
| `HOTKEYS STOP` | No | No | Raw only | Raw only |
| `INFO` | Yes | Yes | Ready | Returns information and statistics about the server. |
| `LASTSAVE` | No | No | Raw only | Raw only |
| `LATENCY DOCTOR` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `LATENCY GRAPH` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `LATENCY HISTOGRAM` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `LATENCY HISTORY` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `LATENCY LATEST` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `LATENCY RESET` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `LOLWUT` | No | No | Raw only | Raw only |
| `MEMORY DOCTOR` | Yes | Yes | Ready | Outputs a memory problems report. |
| `MEMORY MALLOC-STATS` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `MEMORY PURGE` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `MEMORY STATS` | Yes | Yes | Ready | Returns details about memory usage. |
| `MEMORY USAGE` | Yes | Yes | Ready | Estimates the memory usage of a key. |
| `MODULE LIST` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `MODULE LOAD` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `MODULE LOADEX` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `MODULE UNLOAD` | No | Family | Raw + routed | Raw sendCommand only; cluster family parser exists |
| `MONITOR` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `PSYNC` | No | No | Raw only | Raw only |
| `REPLCONF` | No | No | Raw only | Raw only |
| `REPLICAOF` | Yes | Yes | Ready | Configures a server as replica of another, or promotes it to a master. |
| `RESTORE-ASKING` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `ROLE` | Yes | Yes | Ready | Returns the replication role. |
| `SAVE` | No | No | Raw only | Raw only |
| `SHUTDOWN` | No | No | Raw only | Raw only |
| `SLAVEOF` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `SLOWLOG GET` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `SLOWLOG LEN` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `SLOWLOG RESET` | Yes | Family | Ready | Typed helper with family-level cluster routing support |
| `SWAPDB` | No | No | Raw only | Raw only |
| `SYNC` | No | No | Raw only | Raw only |
| `TIME` | Yes | Yes | Ready | Returns the server time. |
## Cluster commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `ASKING` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `CLUSTER ADDSLOTS` | Yes | Yes | Ready | Assigns new hash slots to a node. |
| `CLUSTER ADDSLOTSRANGE` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER BUMPEPOCH` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER COUNT-FAILURE-REPORTS` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER COUNTKEYSINSLOT` | Yes | Yes | Ready | Returns the number of keys in a hash slot. |
| `CLUSTER DELSLOTS` | Yes | Yes | Ready | Sets hash slots as unbound for a node. |
| `CLUSTER DELSLOTSRANGE` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER FAILOVER` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER FLUSHSLOTS` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER FORGET` | Yes | Yes | Ready | Removes a node from the nodes table. |
| `CLUSTER GETKEYSINSLOT` | Yes | Yes | Ready | Returns the key names in a hash slot. |
| `CLUSTER INFO` | Yes | Yes | Ready | Returns information about the state of a node. |
| `CLUSTER KEYSLOT` | Yes | Yes | Ready | Returns the hash slot for a key. |
| `CLUSTER LINKS` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER MEET` | Yes | Yes | Ready | Forces a node to handshake with another node. |
| `CLUSTER MIGRATION` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER MYID` | Yes | Yes | Ready | Returns the ID of a node. |
| `CLUSTER MYSHARDID` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER NODES` | Yes | Yes | Ready | Returns the cluster configuration for a node. |
| `CLUSTER REPLICAS` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER REPLICATE` | Yes | Yes | Ready | Configure a node as replica of a master node. |
| `CLUSTER RESET` | Yes | Yes | Ready | Resets a node. |
| `CLUSTER SAVECONFIG` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER SET-CONFIG-EPOCH` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER SETSLOT` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER SHARDS` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER SLAVES` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER SLOT-STATS` | Family | Yes | Partial | Helper exists in command family; exact command helper may be indirect |
| `CLUSTER SLOTS` | Yes | Yes | Ready | Returns the mapping of cluster slots to nodes. |
| `READONLY` | Yes | Yes | Ready | Enables read-only queries for a connection to a Redis Cluster replica node. |
| `READWRITE` | Yes | Yes | Ready | Enables read-write queries for a connection to a Reids Cluster replica node. |
## Generic commands

| Command | Helper | Cluster | Status | Notes |
| --- | --- | --- | --- | --- |
| `COPY` | Yes | Yes | Ready | Copies the value of a key to a new key. |
| `DEL` | Yes | Yes | Ready | Deletes one or more keys. |
| `DUMP` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `EXISTS` | Yes | Yes | Ready | Determines whether one or more keys exist. |
| `EXPIRE` | Yes | Yes | Ready | Sets the expiration time of a key in seconds. |
| `EXPIREAT` | Yes | Yes | Ready | Sets the expiration time of a key to a Unix timestamp. |
| `EXPIRETIME` | Yes | Yes | Ready | Returns the expiration time of a key as a Unix timestamp. |
| `KEYS` | Yes | No | Helper only | Typed helper without dedicated cluster spec |
| `MIGRATE` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
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
| `RESTORE` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `SCAN` | Yes | No | Helper only | Typed helper without dedicated cluster spec |
| `SORT` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
| `SORT_RO` | No | Yes | Raw + routed | Raw sendCommand only, but cluster-aware |
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
