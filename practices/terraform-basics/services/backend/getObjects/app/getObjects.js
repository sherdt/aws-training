const { createDatabaseTableStructure } = require('./services/sqlService');

exports.handler = async (event, context) => {
  try {

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

    console.log('Get objects...');
    const tableStructure = await createDatabaseTableStructure(dbConfig);
    return {
      statusCode: 200,
      body: JSON.stringify(tableStructure)
    };
  } catch (e) {
    console.error(e);
    return {
      statusCode: 500,
      body: e.message
    }
  }
};
