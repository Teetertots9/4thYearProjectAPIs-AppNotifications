
// Load the SDK for JavaScript
const AWS = require('aws-sdk');
// Set the region
AWS.config.update({ region: process.env.region });
const logger = require('pino')({ name: 'Delete App Notification', level: 'info' });
// Create DynamoDB document client
const docClient = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const TABLE_NAME = process.env.table;

exports.handler = async (event) => {
  try {
    logger.info(event);
    const { params } = event;

    const { id } = params.path;

    const deleteItemParams = {
      TableName: TABLE_NAME,
      Key: {
        id,
      },
      ConditionExpression: 'attribute_exists(id)',
    };

    logger.info('Delete Item Params:');
    logger.info(deleteItemParams);

    // delete item
    const response = await docClient.delete(deleteItemParams).promise();

    if (response.errorMessage) {
      throw new Error(response.errorMessage);
    }

    response.id = id;
    response.Message = 'Item Deleted Succesfully';

    logger.info(response);

    return response;
  } catch (err) {
    logger.error(err);
    return err;
  }
};
