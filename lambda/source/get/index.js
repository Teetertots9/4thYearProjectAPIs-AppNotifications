
// Load the SDK for JavaScript
const AWS = require('aws-sdk');
// Set the region
AWS.config.update({ region: process.env.region });
const logger = require('pino')({ name: 'Get App Notifications', level: 'info' });
// Create DynamoDB document client
const docClient = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const TABLE_NAME = process.env.table;

exports.handler = async (event) => {
  try {
    logger.info(event);
    const { params } = event;

    const exclusiveStartKey = params.querystring.lastEvaluatedKey;
    const { limit } = params.querystring;

    const getAllParams = {
      TableName: TABLE_NAME,
    };

    if (exclusiveStartKey) {
      getAllParams.ExclusiveStartKey = {
        id: exclusiveStartKey,
      };
    }
    if (limit && limit > 0) {
      getAllParams.Limit = limit;
    }

    logger.info('Get All Params:');
    logger.info(getAllParams);

    // get all items
    const response = await docClient.scan(getAllParams).promise();

    if (response.errorMessage) {
      throw new Error(response.errorMessage);
    }

    logger.info(response);

    return response;
  } catch (err) {
    logger.error(err);
    return err;
  }
};
