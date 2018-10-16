pragma solidity ^0.4.24;

import './openzeppelin-solidity/contracts/lifecycle/Pausable.sol';
import './openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import './openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import './openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol';

import './AccountLockableToken.sol';
import './WithdrawableToken.sol';
import './MilestoneLockToken.sol';

/**
 * @title Hena token
 */
contract Hena is
    Pausable,
    MintableToken,
    BurnableToken,
    AccountLockableToken,
    WithdrawableToken,
    MilestoneLockToken
{
    uint256 constant MAX_SUFFLY = 1000000000;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor() public
    {
        name = "Hena";
        symbol = "HENA";
        decimals = 18;
        totalSupply_ = MAX_SUFFLY * (10 ** uint(decimals));

        balances[owner] = totalSupply_;

        emit Transfer(address(0), owner, totalSupply_);
    }

    function() public
    {
        revert();
    }

    /**
     * @dev Transfer token for a specified address when if not paused and not locked account
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to anther when if not paused and not locked account
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function transferFrom(address _from, address _to, uint256 _value) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        require(!lockStates[_from]);

        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
       when if not paused and not locked account
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender when if not paused and not locked account
     * @param _spender address which will spend the funds.
     * @param _addedValue amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint256 _addedValue) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @param _spender address which will spend the funds.
     * @param _subtractedValue amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    /**
     * @dev Distribute the amount of tokens to owner's balance.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function distribute(address _to, uint256 _value) public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[owner]);

        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(owner, _to, _value);

        return true;
    }

    /**
     * @dev Burns a specific amount of tokens by owner.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public
        onlyOwner
    {
        super.burn(_value);
    }

    /**
     * @dev batch to the policy to account's available balance.
     * @param _policy index of milestone policy to apply.
     * @param _addresses The addresses to apply.
     */
    function batchToApplyMilestone(uint8 _policy, address[] _addresses) public
        onlyOwner
        returns (bool[])
    {
        require(_policy < MAX_POLICY);
        require(_checkPolicyEnabled(_policy));
        require(_addresses.length > 0);

        bool[] memory results = new bool[](_addresses.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            results[i] = false;
            if (_addresses[i] != address(0)) {
                uint256 availableBalance = getAvailableBalance(_addresses[i]);
                results[i] = (availableBalance > 0);
                if (results[i]) {
                    _setMilestoneTo(_addresses[i], availableBalance, _policy);
                }
            }
        }

        return results;
    }
}