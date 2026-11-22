// =========================================================
// CRESTFIELD UNIVERSITY - STUDENT RESULT PORTAL
// PORTFOLIO 5: DISTRIBUTED AND CLOUD DATABASE EXERCISE
// File: 01_replication_demo.js
// Database: MongoDB Atlas M0 cluster (MongoDB shell in Compass)
//
// The Atlas cluster from Portfolio 4 is a 3-node REPLICA SET
// hosted in the cloud: one primary (accepts writes) and two
// secondaries (keep copies of the data). These blocks show
// replication, read preferences and write concerns using the
// same crestfield_university data.
//
// Paste ONE numbered block at a time and screenshot the output.
// (The free M0 tier blocks some admin commands such as
//  rs.status(); db.hello() gives the same topology information.)
// =========================================================

use('crestfield_university');


// ---------------------------------------------------------
// P1. REPLICA SET TOPOLOGY
// setName = the replica set, hosts = the 3 nodes holding a
// copy of the data, primary = the node that accepts writes,
// me = the node this shell is connected to.
// ---------------------------------------------------------
(function () {
  const h = db.hello();
  return {
    replica_set: h.setName,
    nodes: h.hosts,
    primary: h.primary,
    connected_to: h.me,
    this_node_is_primary: h.isWritablePrimary
  };
})();


// ---------------------------------------------------------
// P2. READ PREFERENCE - WHICH NODE ANSWERS A QUERY?
// The same transcript query is sent first to the primary,
// then with readPref('secondary'). The serverInfo.host in
// each explain shows a DIFFERENT node answered: reads can be
// spread across replicas (e.g. on results-release day).
// ---------------------------------------------------------
({
  primary_answered_by: db.students.find({ matric_number: 'CU/2025/00012' })
    .readPref('primary').explain().serverInfo.host,
  secondary_answered_by: db.students.find({ matric_number: 'CU/2025/00012' })
    .readPref('secondary').explain().serverInfo.host
});


// ---------------------------------------------------------
// P3. WRITE CONCERN - HOW MANY NODES MUST CONFIRM A WRITE?
// w: 1         -> only the primary confirms (fast, but the
//                 write could be lost if the primary fails
//                 before it is copied)
// w: 'majority'-> at least 2 of 3 nodes confirm (survives
//                 the loss of one node) - appropriate for
//                 grades, which must never be lost
// ---------------------------------------------------------
db.replication_test.insertOne(
  { note: 'write acknowledged by primary only', at: new Date() },
  { writeConcern: { w: 1 } }
);

db.replication_test.insertOne(
  { note: 'write acknowledged by a majority of nodes', at: new Date() },
  { writeConcern: { w: 'majority', wtimeout: 5000 } }
);


// ---------------------------------------------------------
// P4. READ CONCERN - READING ONLY DATA THAT IS SAFE
// readConcern 'majority' returns only data confirmed by a
// majority of nodes, so a student never sees a result that
// could disappear if the primary failed.
// ---------------------------------------------------------
db.students.find(
  { matric_number: 'CU/2025/00027' },
  { _id: 0, matric_number: 1, 'name.first': 1, 'name.last': 1 }
).readConcern('majority');


// ---------------------------------------------------------
// P5. CLEAN UP
// ---------------------------------------------------------
db.replication_test.drop();
