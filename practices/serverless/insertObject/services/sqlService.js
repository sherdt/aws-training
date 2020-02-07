const mysql = require('mysql');
const util = require('util');

const TABLE_NAME = 'orders';

const getAllTableNamesInDatabase = databaseName =>
 'SELECT table_name FROM information_schema.tables WHERE table_schema = "' + databaseName + '"';
const getCreateTableQuery = tableName =>
 'CREATE TABLE IF NOT EXISTS ' + tableName + ' (name VARCHAR(255), price VARCHAR(255))';

const prepareDatabase = async (query, dbConfig) => {
  const DB = process.env['DB'];

  let result;

  console.log(`Create database ${dbConfig.database} if not exists`);
  result = await query('CREATE DATABASE IF NOT EXISTS ??', DB);
  await query('USE ??', DB);
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

exports.insertObject = async (dbConfig, name, price) => {
  let result = null;

  const connection = mysql.createConnection(dbConfig);
  try {
    const query = util.promisify(connection.query).bind(connection);
    result = await prepareDatabase(query, dbConfig);

    console.log(`Insert object with name ${name} and price ${price}`);
    result = query('INSERT INTO ' + TABLE_NAME + ' VALUES("' + name + ', ' + price + '")');

  } finally {
    const conEnd = util.promisify(connection.end).bind(connection);
    await conEnd();
  }

  return result;
};
