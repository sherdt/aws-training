const { insertObject } = require('./services/sqlService');

exports.handler = async (event, context) => {
  try {
    const insertVariables = typeof event.body === 'object' ? event.body : JSON.parse(event.body);
    const name = insertVariables.name;
    const price = insertVariables.price;

    if(name && price) {
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

      console.log('insert object...');
      const tableStructure = await insertObject(dbConfig, name, price);

      return {
        statusCode: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": '*',
        },
        body: JSON.stringify(tableStructure)
      };
    }else {
      throw new Error("Name or price not defined.");
    }
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
