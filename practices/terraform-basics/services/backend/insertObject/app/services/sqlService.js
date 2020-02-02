/*
    GENERAL
 */
const getAllTableNamesInDatabase = databaseName =>
 'SELECT table_name FROM information_schema.tables WHERE table_schema = "' + databaseName + '"';

/*
    TABLES
 */
const getCreateSpeakerTableQuery = speakerTableName =>
 'CREATE TABLE IF NOT EXISTS ' + speakerTableName + ' (name VARCHAR(255))';

/*
  UTIL
 */
exports.createDatabaseTableStructure = async (dbConfig, name) => {
  const mysql = require('mysql');
  const util = require('util');

  let result = null;

  const speakerTableName = "fuckoff";

  const connection = mysql.createConnection(dbConfig);
  try {
    const query = util.promisify(connection.query).bind(connection);

    result = await query('CREATE DATABASE IF NOT EXISTS ??', dbConfig.database);

    result = await query(getAllTableNamesInDatabase(dbConfig.database));
    console.log('Tables before changes: ');
    console.log(result);

    console.log('Creating table: ' + speakerTableName);
    result = await query(getCreateSpeakerTableQuery(speakerTableName));
    console.log(result);

    result = await query(getAllTableNamesInDatabase(dbConfig.database));
    console.log('Tables after changes: ');
    console.log(result);

    result = query('INSERT INTO '+speakerTableName+' VALUES("'+name+'")');

  } finally {
    const conEnd = util.promisify(connection.end).bind(connection);
    await conEnd();
  }

  return result;
};
