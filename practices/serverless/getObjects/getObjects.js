const { getAllObjects } = require('./services/sqlService');

exports.handler = async (event, context) => {
  try {
    const DB_HOST = process.env['DB_HOST'];
    const DB_PORT = process.env['DB_PORT'];
    const DB_USER = process.env['DB_USER'];
    const DB_PW = process.env['DB_PW'];

    const dbConfig = {
      host: DB_HOST,
      port: DB_PORT,
      user: DB_USER,
      password: DB_PW,
    };

    console.log('Get objects...');
    const result = await getAllObjects(dbConfig);

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": '*',
      },
      body: JSON.stringify(result)
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
