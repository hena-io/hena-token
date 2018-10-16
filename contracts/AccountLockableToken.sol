pragma solidity ^0.4.24;

import './openzeppelin-solidity/contracts/ownership/Ownable.sol';

/**
 * @title Account Lockable Token
 */
contract AccountLockableToken is Ownable {
    mapping(address => bool) public lockStates;

    event LockAccount(address indexed lockAccount);
    event UnlockAccount(address indexed unlockAccount);

    /**
     * @dev Throws if called by locked account
     */
    modifier whenNotLocked() {
        require(!lockStates[msg.sender]);
        _;
    }

    /**
     * @dev Lock target account
     * @param _target Target account to lock
     */
    function lockAccount(address _target) public
        onlyOwner
        returns (bool)
    {
        require(_target != owner);
        require(!lockStates[_target]);

        lockStates[_target] = true;

        emit LockAccount(_target);

        return true;
    }

    /**
     * @dev Unlock target account
     * @param _target Target account to unlock
     */
    function unlockAccount(address _target) public
        onlyOwner
        returns (bool)
    {
        require(_target != owner);
        require(lockStates[_target]);

        lockStates[_target] = false;

        emit UnlockAccount(_target);

        return true;
    }
}