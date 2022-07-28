const TestContract = artifacts.require("./TestContract.sol");

contract("TestContract", (accounts) => {
  it("...should store the value 'Hello Blockchain'.", async () => {
    const testContractInstance = await TestContract.deployed();

    // Set value of Hello World
    await testContractInstance.SendRequest("Hello Blockchain", {
      from: accounts[0],
    });

    // Get stored value
    const storedData = await testContractInstance.RequestMessage.call();

    assert.equal(
      storedData,
      "Hello Blockchain",
      "The value 'Hello Blockchain' was not stored."
    );
  });
});
