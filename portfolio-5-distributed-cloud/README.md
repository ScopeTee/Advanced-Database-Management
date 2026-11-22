# Portfolio 5: Distributed and Cloud Database Exercise

## Expected Evidence

Distributed/cloud database discussion or setup based on the same case study, including replication, sharding, availability, consistency, or deployment evidence.

## Implementation

This portfolio uses the MongoDB Atlas cluster from Portfolio 4 to demonstrate a distributed, cloud-hosted database for the Crestfield University Student Result Portal.

| Item | Detail |
|---|---|
| Provider | MongoDB Atlas (free M0 tier) on **AWS**, region **Paris (eu-west-3)** |
| Version | MongoDB 8.0.39 |
| Topology | **Replica set** `atlas-11iaya-shard-0` with **3 nodes**: one primary, two secondaries |
| Data | The `crestfield_university` database from Portfolio 4 |

| File | Purpose |
|---|---|
| `01_replication_demo.js` | Shell commands showing the replica set topology, read preference, write concern and read concern |
| `screenshots/` | Shell output and Atlas dashboard screenshots |

The free M0 tier does not allow `rs.status()` or sharding, so I used `db.hello()` for the topology, and treat sharding as a design discussion.

## How to Run / Test

1. Connect to the Atlas cluster in MongoDB Compass and open the MongoDB shell.
2. Run `use('crestfield_university');`.
3. Paste each block from `01_replication_demo.js` (P1–P5) one at a time.
4. In the Atlas website, open **Clusters** for the overview, then **Cluster0 → Metrics** to see the three nodes.

## Results and Evidence

| Screenshot | Shows |
|---|---|
| `01-p1-topology.png` | Replica set `atlas-11iaya-shard-0` with nodes `ac-v0lbayi-shard-00-00`, `-01` and `-02`. The primary is `-02`, and the shell is connected to it |
| `02-p2-read-preference.png` | The same query answered by `shard-00-02` (`readPref('primary')`) and by `shard-00-01` (`readPref('secondary')`) |
| `03-p3-write-concern.png` | Inserts with `w: 1` and `w: 'majority'`, both acknowledged |
| `04-p4-read-concern.png` | A student record read with `readConcern('majority')` |
| `04b-p5-cleanup.png` | Test collection removed |
| `05-atlas-cluster-overview.png` | Atlas dashboard: AWS Paris (eu-west-3), MongoDB 8.0.39, "Replica Set – 3 nodes" |
| `06-atlas-nodes.png` | Atlas Metrics for the three members: two secondaries (S) and the primary (P) |

## Notes / Analysis

### 1. Replication

I set up a 3-node replica set on AWS in the Paris region (eu-west-3), with each node holding the same `crestfield_university` database. From my P1 screenshot, I confirmed that all three nodes were part of the replica set. The Metrics screenshot also showed activity on the secondary nodes even though I only wrote to the primary, which reflects them replicating the changes. This is useful for Crestfield because results-release day could bring a lot of read traffic, and the P2 test showed that a read could be served by `shard-00-01`, a secondary, instead of the primary `shard-00-02`.

### 2. Availability

Replication also helps keep the database available when a node fails. If the primary goes down, the two remaining secondary nodes can elect a new primary automatically, usually within seconds. Since the replica set has three nodes, two nodes still form a majority when one node is unavailable. This is why an odd number of nodes is commonly used for replica sets, as it makes majority voting straightforward.

### 3. Consistency

The secondary nodes replicate changes asynchronously, so there can be a short delay before they have the latest data. This means a read from a secondary might return slightly outdated information, which is acceptable when viewing a transcript but not ideal when dealing with grades. For this reason, I used `w: 'majority'` in P3 so a write is confirmed by at least two nodes, and `readConcern('majority')` in P4 so the read returns data that will not be rolled back. The trade-off is that majority writes can take slightly longer than using `w: 1`.

### 4. CAP Theorem

CAP theorem explains that during a network partition, a distributed database has to choose between consistency and availability. For Crestfield's grading system, I would prioritise consistency because it is more important to have correct grades than to allow conflicting grade updates. MongoDB supports this by allowing only the side with a majority of nodes to elect and maintain a primary. For less critical information, such as announcements, availability could be more important because a brief inconsistency would have less impact. MongoDB also lets this choice be tuned per query: reading from a secondary, as in P2, favours availability and spreading the load, while majority reads and writes, as in P3 and P4, favour consistency.

### 5. Sharding

Replication copies the same data across multiple servers, while sharding divides the data across servers. Sharding would become useful if Crestfield's student records grew beyond what one server could comfortably store or handle. If I were designing the shard key, I would choose a hashed `matric_number` because it should distribute student records more evenly across shards, while allowing a transcript lookup to target a single shard. The drawback of a hashed key is that range queries, such as listing all students admitted in 2023, would have to be sent to every shard. A faculty-based shard key would be simpler, but it has low cardinality: there are only a few faculty values, and some faculties may have far more students than others, which could create an uneven distribution. Although sharding was not available on the free M0 tier, this would be my preferred design if the database needed to scale further.
