const TestContract = artifacts.require('TestContract');

module.exports = async (callback) => {
  try {
    const testContract = await TestContract.deployed();
    const reciept = await testContract.SendRequest("Hello World");
    console.log(reciept);

  } catch(err) {
    console.log('Oops: ', err.message);
  }
  callback();
};
