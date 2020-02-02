const { createDatabaseTableStructure } = require('./services/sqlService');

exports.handler = async (event, context) => {
  try {
    const insertVariables = typeof event.body === 'object' ? event.body : JSON.parse(event.body);
    const name = insertVariables.name;

    const DB_HOST = process.env['DB_HOST'];
    const DB_PORT = process.env['DB_PORT'];
    const DB = process.env['DB'];
    const DB_USER = process.env['DB_USER'];
    const DB_PW = process.env['DB_PW'];

    const dbConfig = {
      host: DB_HOST,
      port: DB_PORT,
      database: DB,
      user: DB_USER,
      password: DB_PW,
    };

    console.log('insert object...');
    const tableStructure = await createDatabaseTableStructure(dbConfig, name);
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": '*',
      },
      body: JSON.stringify(tableStructure)
    };
  } catch (e) {
    console.error(e);
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": '*',
      },
      body: e.message
    }
  }
};
