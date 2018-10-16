const AccountLockableToken = artifacts.require('AccountLockableToken');

contrat('AccountLockableToken', function (accounts) {
    beforeEach(async function() {
        this.token = await AccountLockableToken.new();
    });
});