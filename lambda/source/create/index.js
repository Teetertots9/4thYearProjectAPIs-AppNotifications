
const shortid = require('shortid');
const logger = require('pino')({ name: 'Create App Notification', level: 'info' });
// Load the SDK for JavaScript
const AWS = require('aws-sdk');
// Set the region
AWS.config.update({ region: process.env.region });

// Create DynamoDB document client
const docClient = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const TABLE_NAME = process.env.table;

exports.handler = async (event) => {
  try {
    logger.info(event);
    const { body } = event;

    const item = {
      ...body,
      notifications: [],
    };

    const createItemParams = {
      TableName: TABLE_NAME,
      Item: item,
      ConditionExpression: 'attribute_not_exists(id)',
    };

    logger.info('Create Item Params:');
    logger.info(createItemParams);

    // create item
    const response = await docClient.put(createItemParams).promise();

    if (response.errorMessage) {
      throw new Error(response.errorMessage);
    }

    response.Item = createItemParams.Item;
    response.Message = 'Item Created Succesfully';

    logger.info(response);

    return response;
  } catch (err) {
    logger.error(err);
    return err;
  }
};
