const mysql = require('mysql');
const util = require('util');

const TABLE_NAME = 'orders';

const getAllTableNamesInDatabase = databaseName =>
 'SELECT table_name FROM information_schema.tables WHERE table_schema = "' + databaseName + '"';
const getCreateTableQuery = tableName =>
 'CREATE TABLE IF NOT EXISTS ' + tableName + ' (name VARCHAR(255))';


const prepareDatabase = async (query, dbConfig) => {
  let result;

  console.log(`Create database ${dbConfig.database} if not exists`);
  result = await query('CREATE DATABASE IF NOT EXISTS ??', dbConfig.database);
  console.log(result);

  console.log(`Use database ${dbConfig.database}.`);
  result = await query('USE ??', dbConfig.database);
  console.log(result);

  result = await query(getAllTableNamesInDatabase(dbConfig.database));
  console.log('Tables before changes: ');
  console.log(result);

  console.log('Creating table: ' + TABLE_NAME);
  result = await query(getCreateTableQuery(TABLE_NAME));
  console.log(result);

  result = await query(getAllTableNamesInDatabase(dbConfig.database));
  console.log('Tables after changes: ');
  console.log(result);

  return result;
};

exports.getAllObjects = async (dbConfig) => {
  let result = null;

  const conConfig = {
    host: dbConfig.host,
    port: dbConfig.port,
    user: dbConfig.user,
    password: dbConfig.password,
  }
  const connection = mysql.createConnection(conConfig);
  try {
    const query = util.promisify(connection.query).bind(connection);
    result = await prepareDatabase(query, dbConfig);

    console.log('Get all entries in database table...');
    result = query('SELECT * FROM ' + TABLE_NAME);
  } finally {
    const conEnd = util.promisify(connection.end).bind(connection);
    await conEnd();
  }

  return result;
};
